from fastapi import APIRouter, HTTPException
import json
import os
from datetime import datetime, timedelta
import requests

from app.database.schemas import ScheduleRequest, ScheduleResponse, EventItem

# Try to import OpenAI (optional)
try:
    from openai import OpenAI
    OPENAI_AVAILABLE = True
except ImportError:
    OPENAI_AVAILABLE = False

# Try to import Google Gemini (optional)
try:
    import google.generativeai as genai
    GEMINI_AVAILABLE = True
except ImportError:
    GEMINI_AVAILABLE = False

router = APIRouter(prefix="/chat", tags=["chat"])

# Initialize clients
_openai_client = None
_gemini_model = None
OLLAMA_BASE_URL = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")

def get_gemini_model():
    """Get Google Gemini model (free tier available)"""
    global _gemini_model
    if not GEMINI_AVAILABLE:
        return None
    if _gemini_model is None:
        api_key = os.getenv("GEMINI_API_KEY")
        if api_key:
            genai.configure(api_key=api_key)
            _gemini_model = genai.GenerativeModel('gemini-pro')
    return _gemini_model

def call_ollama(prompt: str, model: str = None) -> str:
    """Call Ollama local LLM (completely free, runs locally)
    Tries multiple models in order of preference.
    """
    # Try models in order of preference (best quality first)
    models_to_try = model and [model] or ["llama3.2", "llama3", "mistral", "codellama", "llama2"]
    
    for model_name in models_to_try:
        try:
            print(f"Trying Ollama model: {model_name}")
            response = requests.post(
                f"{OLLAMA_BASE_URL}/api/generate",
                json={
                    "model": model_name,
                    "prompt": prompt,
                    "stream": False,
                    "options": {
                        "temperature": 0.3,  # Lower temperature for more structured output
                        "num_predict": 2000  # Max tokens
                    }
                },
                timeout=90  # Longer timeout for larger models
            )
            if response.status_code == 200:
                result = response.json().get("response", "")
                if result:
                    print(f"✅ Successfully got response from Ollama ({model_name})")
                    return result
            else:
                print(f"Ollama model {model_name} returned status {response.status_code}")
        except requests.exceptions.ConnectionError:
            print(f"Ollama not running or model {model_name} not available. Make sure Ollama is installed and running.")
            return None  # Don't try other models if Ollama isn't running
        except Exception as e:
            print(f"Error with Ollama model {model_name}: {e}")
            continue  # Try next model
    
    return None


def _create_fallback_events(prompt: str, today: datetime) -> ScheduleResponse:
    """
    Smart fallback that understands natural language and creates structured events.
    Works without any AI APIs - uses pattern matching and intelligent parsing.
    """
    prompt_lower = prompt.lower()
    events = []
    current_time = 6  # Start at 6 AM for morning routines
    
    # Helper to add event with auto-incrementing time
    def add_event(title, start_hour, start_min, duration_min=30, location="", desc=""):
        start_time_str = f"{start_hour:02d}:{start_min:02d}"
        end_hour = start_hour + (start_min + duration_min) // 60
        end_min = (start_min + duration_min) % 60
        end_time_str = f"{end_hour:02d}:{end_min:02d}"
        events.append(EventItem(
            title=title,
            date=today.strftime('%Y-%m-%d'),
            start_time=start_time_str,
            end_time=end_time_str,
            location=location,
            description=desc or title
        ))
        return end_hour, end_min
    
    # Parse time mentions
    import re
    time_patterns = {
        r'(\d{1,2})\s*(am|pm|:|\s)': None,  # Will extract in code
        r'morning': (6, 0),
        r'afternoon': (13, 0),
        r'evening': (17, 0),
        r'night': (20, 0),
        r'early\s*morning': (5, 0),
        r'late\s*night': (22, 0),
    }
    
    # Extract explicit times
    time_matches = re.findall(r'(\d{1,2}):?(\d{2})?\s*(am|pm)?', prompt_lower)
    parsed_times = []
    for match in time_matches:
        hour = int(match[0])
        minute = int(match[1]) if match[1] else 0
        if match[2] == 'pm' and hour < 12:
            hour += 12
        elif match[2] == 'am' and hour == 12:
            hour = 0
        parsed_times.append((hour, minute))
    
    # MORNING ROUTINE DETECTION
    if "wake" in prompt_lower or ("morning" in prompt_lower and "routine" in prompt_lower):
        hour, minute = add_event("Wake Up", 6, 0, 15, "Home", "Morning wake up")
        current_time = hour
        current_min = minute
    
    # PRAYER DETECTION - Smart prayer parsing
    prayer_keywords = ["pray", "prayer", "salah", "salat", "namaz"]
    has_prayer = any(kw in prompt_lower for kw in prayer_keywords)
    
    if has_prayer:
        # Check for "all prayers" or similar
        if any(word in prompt_lower for word in ["all", "every", "all of", "each"]):
            # All 5 prayers
            prayers = [
                ("Fajr Prayer", 5, 30, 30),
                ("Dhuhr Prayer", 12, 30, 30),
                ("Asr Prayer", 15, 30, 30),
                ("Maghrib Prayer", 18, 30, 30),
                ("Isha Prayer", 20, 0, 30),
            ]
            for title, h, m, d in prayers:
                add_event(title, h, m, d, "", "Prayer time")
        else:
            # Single prayer - infer from time or use default
            if "fajr" in prompt_lower or "dawn" in prompt_lower:
                add_event("Fajr Prayer", 5, 30, 30)
            elif "dhuhr" in prompt_lower or "zuhr" in prompt_lower or "noon" in prompt_lower:
                add_event("Dhuhr Prayer", 12, 30, 30)
            elif "asr" in prompt_lower or "afternoon" in prompt_lower:
                add_event("Asr Prayer", 15, 30, 30)
            elif "maghrib" in prompt_lower or "sunset" in prompt_lower:
                add_event("Maghrib Prayer", 18, 30, 30)
            elif "isha" in prompt_lower or "night" in prompt_lower:
                add_event("Isha Prayer", 20, 0, 30)
            else:
                # Default prayer time
                add_event("Prayer", 12, 0, 30)
    
    # SEQUENTIAL ACTIVITY PARSING
    # Look for "and", "then", "after" to chain events
    connectors = [" and ", " then ", " after ", ", then ", ", and ", " followed by "]
    has_connectors = any(conn in prompt_lower for conn in connectors)
    
    # BREAKFAST/MEAL
    if any(word in prompt_lower for word in ["breakfast", "eat", "meal", "food", "lunch", "dinner"]):
        if "breakfast" in prompt_lower:
            add_event("Breakfast", 8, 0, 30, "Kitchen", "Morning meal")
        elif "lunch" in prompt_lower:
            add_event("Lunch", 13, 0, 45, "", "Midday meal")
        elif "dinner" in prompt_lower:
            add_event("Dinner", 19, 0, 60, "", "Evening meal")
        else:
            add_event("Meal", 8, 0, 30, "Kitchen", "Meal time")
    
    # STUDY/LEARNING
    if any(word in prompt_lower for word in ["study", "learn", "homework", "read", "research"]):
        # Try to extract duration
        duration = 120  # Default 2 hours
        if "hour" in prompt_lower:
            hour_match = re.search(r'(\d+)\s*hour', prompt_lower)
            if hour_match:
                duration = int(hour_match.group(1)) * 60
        
        # Try to extract time
        if parsed_times:
            h, m = parsed_times[0]
            add_event("Study Session", h, m, duration, "", "Study time")
        else:
            add_event("Study Session", 9, 0, duration, "", "Study time")
    
    # EXERCISE/WORKOUT
    if any(word in prompt_lower for word in ["exercise", "workout", "gym", "run", "jog", "fitness"]):
        add_event("Exercise", 7, 0, 60, "Gym", "Physical activity")
    
    # SHOWER/BATH
    if any(word in prompt_lower for word in ["shower", "bath", "wash"]):
        add_event("Shower", 7, 30, 20, "Bathroom", "Personal hygiene")
    
    # WORK
    if any(word in prompt_lower for word in ["work", "job", "office", "meeting"]):
        if parsed_times:
            h, m = parsed_times[0]
            add_event("Work", h, m, 480, "Office", "Work time")  # 8 hours
        else:
            add_event("Work", 9, 0, 480, "Office", "Work time")
    
    # If no specific patterns matched, create intelligent events from keywords
    if not events:
        # Try to extract main activity
        words = prompt_lower.split()
        # Remove common words
        stop_words = {"i", "want", "to", "in", "the", "and", "a", "an", "at", "on", "for", "with"}
        meaningful_words = [w for w in words if w not in stop_words and len(w) > 2]
        
        if meaningful_words:
            title = " ".join(meaningful_words[:4]).title()
            add_event(title, 12, 0, 60, "", prompt)
        else:
            # Last resort
            title = prompt[:50] if len(prompt) > 50 else prompt
            add_event(title, 12, 0, 60, "", prompt)
    
    # Sort events by time
    events.sort(key=lambda e: (e.date, e.start_time))
    
    return ScheduleResponse(
        events=events,
        summary=f"✅ Created {len(events)} event(s) using smart fallback mode (no AI needed)"
    )

def is_valid_openai_key(api_key: str) -> bool:
    """Check if the API key looks like a valid OpenAI key (starts with 'sk-')"""
    if not api_key:
        return False
    # OpenAI keys start with "sk-", Gemini keys start with "AIza"
    return api_key.strip().startswith("sk-")

def get_openai_client():
    global _openai_client
    if not OPENAI_AVAILABLE:
        return None
    if _openai_client is None:
        api_key = os.getenv("OPENAI_API_KEY")
        if api_key and is_valid_openai_key(api_key):
            _openai_client = OpenAI(api_key=api_key)
        else:
            # Invalid key format, don't create client
            return None
    return _openai_client

def _build_ai_prompt(user_prompt: str, today: datetime, tomorrow: datetime) -> str:
    """Build the AI prompt for event generation"""
    today_str = today.strftime('%Y-%m-%d')
    tomorrow_str = tomorrow.strftime('%Y-%m-%d')
    weekday = today.strftime('%A')
    
    return f"""You are an intelligent calendar assistant that understands natural language and creates well-organized calendar events.

USER REQUEST: "{user_prompt}"

CONTEXT:
- Today is {weekday}, {today_str}
- Tomorrow is {tomorrow_str}
- Current time context: Use today's date unless the user specifies otherwise (e.g., "tomorrow", "Monday", "next week")

YOUR TASK:
Carefully analyze the user's request and break it down into logical, sequential calendar events. Understand the intent behind their words.

EXAMPLES OF UNDERSTANDING:
- "I want to wake up in the morning and pray all prayers" → Create: Wake Up, Fajr, Dhuhr, Asr, Maghrib, Isha
- "Study from 8 to 10 AM then have breakfast" → Create: Study Session (08:00-10:00), Breakfast (10:00-10:30)
- "Morning routine: wake up, exercise, shower, breakfast" → Create 4 separate events in sequence
- "Pray all prayers" → Create all 5 prayer times (Fajr, Dhuhr, Asr, Maghrib, Isha)
- "I need to work on my project tomorrow afternoon" → Create: Work on Project (tomorrow, 13:00-17:00)

TIME INTERPRETATION:
- "morning" = 06:00-12:00
- "afternoon" = 12:00-17:00  
- "evening" = 17:00-21:00
- "night" = 21:00-23:00
- "early morning" = 05:00-08:00
- "late night" = 22:00-23:59

PRAYER TIMES (if mentioned):
- Fajr: 05:30-06:00
- Dhuhr: 12:30-13:00
- Asr: 15:30-16:00
- Maghrib: 18:30-19:00
- Isha: 20:00-20:30

IMPORTANT RULES:
1. Break down complex requests into multiple events
2. Sequence events logically (e.g., wake up before breakfast)
3. Use realistic durations (e.g., breakfast: 30 min, study: 1-2 hours)
4. If no time specified, infer reasonable times based on activity type
5. If no date specified, use today
6. Make titles clear and descriptive
7. Add helpful descriptions

OUTPUT FORMAT:
Return ONLY a valid JSON array. No markdown, no explanations, just JSON.

[
  {{"title": "Event Title", "date": "YYYY-MM-DD", "start_time": "HH:MM", "end_time": "HH:MM", "location": "", "description": "Description"}},
  {{"title": "Next Event", "date": "YYYY-MM-DD", "start_time": "HH:MM", "end_time": "HH:MM", "location": "", "description": "Description"}}
]

Now analyze the user's request and create the events:"""

def _parse_ai_response(content: str, today: datetime) -> list:
    """Parse AI response and extract events"""
    # Clean up the response (remove markdown code blocks if present)
    if content.startswith("```json"):
        content = content[7:]
    if content.startswith("```"):
        content = content[3:]
    if content.endswith("```"):
        content = content[:-3]
    content = content.strip()
    
    # Parse JSON
    events_data = None
    try:
        events_data = json.loads(content)
    except json.JSONDecodeError as e:
        # Fallback: try to extract JSON from the response
        import re
        json_match = re.search(r'\[.*\]', content, re.DOTALL)
        if json_match:
            try:
                events_data = json.loads(json_match.group(0))
            except json.JSONDecodeError:
                return None
        else:
            return None
    
    if not isinstance(events_data, list):
        return None
    
    # Convert to EventItem objects
    events = []
    for event_data in events_data:
        try:
            event = EventItem(
                title=event_data.get("title", "Untitled Event"),
                date=event_data.get("date", today.strftime('%Y-%m-%d')),
                start_time=event_data.get("start_time", "12:00"),
                end_time=event_data.get("end_time", "13:00"),
                location=event_data.get("location", ""),
                description=event_data.get("description", ""),
            )
            events.append(event)
        except Exception:
            continue
    
    return events if events else None


@router.post("/generate", response_model=ScheduleResponse)
def generate_schedule(payload: ScheduleRequest):
    """
    Generate multiple calendar events from natural language description using Ollama (local LLM).
    Example: "I want to wake up at 6 AM, pray Fajr, then study from 8-10 AM"
    """
    try:
        # Get current date context
        today = datetime.now()
        tomorrow = today + timedelta(days=1)
        
        # Build the prompt
        prompt = _build_ai_prompt(payload.prompt, today, tomorrow)
        
        # Try Ollama first (local, free, no keys needed)
        print("Using Ollama (local LLM, no keys needed)...")
        ollama_response = call_ollama(prompt)
        if ollama_response:
            try:
                events_data = _parse_ai_response(ollama_response, today)
                if events_data:
                    return ScheduleResponse(
                        events=events_data,
                        summary=f"✅ Generated {len(events_data)} event(s) using Ollama (local, free)"
                    )
            except Exception as ollama_error:
                print(f"Ollama parsing error: {ollama_error}")
        
        # Fallback to smart keyword-based generation
        print("Ollama unavailable, using smart fallback...")
        return _create_fallback_events(payload.prompt, today)

    except HTTPException:
        raise
    except Exception as e:
        import traceback
        error_details = traceback.format_exc()
        print(f"Error generating schedule: {error_details}")  # Log to console for debugging
        raise HTTPException(
            status_code=500, 
            detail=f"Failed to generate schedule: {str(e)}. Check server logs for details."
        )

