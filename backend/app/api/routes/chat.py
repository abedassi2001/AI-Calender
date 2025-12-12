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

def call_ollama(prompt: str, model: str = "llama3.2") -> str:
    """Call Ollama local LLM (completely free, runs locally)"""
    try:
        response = requests.post(
            f"{OLLAMA_BASE_URL}/api/generate",
            json={
                "model": model,
                "prompt": prompt,
                "stream": False
            },
            timeout=60
        )
        if response.status_code == 200:
            return response.json().get("response", "")
        return None
    except Exception as e:
        print(f"Ollama error: {e}")
        return None


def _create_fallback_events(prompt: str, today: datetime) -> ScheduleResponse:
    """
    Create simple events from prompt when OpenAI is unavailable.
    This is a basic fallback that extracts keywords and creates events.
    """
    prompt_lower = prompt.lower()
    events = []
    
    # Detect common patterns
    if "pray" in prompt_lower or "prayer" in prompt_lower:
        if "all" in prompt_lower or "every" in prompt_lower:
            # Add all prayer times
            prayers = [
                ("Fajr Prayer", "05:30", "06:00"),
                ("Dhuhr Prayer", "12:30", "13:00"),
                ("Asr Prayer", "15:30", "16:00"),
                ("Maghrib Prayer", "18:30", "19:00"),
                ("Isha Prayer", "20:00", "20:30"),
            ]
            for title, start, end in prayers:
                events.append(EventItem(
                    title=title,
                    date=today.strftime('%Y-%m-%d'),
                    start_time=start,
                    end_time=end,
                    location="",
                    description="Prayer time"
                ))
        else:
            # Single prayer
            events.append(EventItem(
                title="Prayer",
                date=today.strftime('%Y-%m-%d'),
                start_time="12:00",
                end_time="12:30",
                location="",
                description="Prayer time"
            ))
    
    if "wake" in prompt_lower or "morning" in prompt_lower:
        events.append(EventItem(
            title="Wake Up",
            date=today.strftime('%Y-%m-%d'),
            start_time="06:00",
            end_time="06:15",
            location="Home",
            description="Morning wake up"
        ))
    
    if "study" in prompt_lower or "learn" in prompt_lower:
        events.append(EventItem(
            title="Study Session",
            date=today.strftime('%Y-%m-%d'),
            start_time="09:00",
            end_time="11:00",
            location="",
            description="Study time"
        ))
    
    if "breakfast" in prompt_lower or "eat" in prompt_lower:
        events.append(EventItem(
            title="Meal",
            date=today.strftime('%Y-%m-%d'),
            start_time="08:00",
            end_time="08:30",
            location="Kitchen",
            description="Meal time"
        ))
    
    if "exercise" in prompt_lower or "workout" in prompt_lower or "gym" in prompt_lower:
        events.append(EventItem(
            title="Exercise",
            date=today.strftime('%Y-%m-%d'),
            start_time="07:00",
            end_time="08:00",
            location="Gym",
            description="Physical activity"
        ))
    
    # If no patterns matched, create a generic event
    if not events:
        events.append(EventItem(
            title=prompt[:50] if len(prompt) > 50 else prompt,
            date=today.strftime('%Y-%m-%d'),
            start_time="12:00",
            end_time="13:00",
            location="",
            description=prompt
        ))
    
    return ScheduleResponse(
        events=events,
        summary=f"⚠️ Created {len(events)} event(s) using fallback mode. OpenAI quota exceeded - add credits at https://platform.openai.com/account/billing"
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
    return f"""You are a helpful calendar assistant. The user wants to schedule activities.

User request: "{user_prompt}"

Today's date: {today.strftime('%Y-%m-%d')}
Tomorrow's date: {tomorrow.strftime('%Y-%m-%d')}

Analyze the user's request and break it down into multiple calendar events. For example:
- If they mention "pray all prayers", create separate events for Fajr, Dhuhr, Asr, Maghrib, Isha
- If they mention "morning routine", break it into wake up, breakfast, exercise, etc.
- If they mention multiple activities, create separate events for each

Return a JSON array of events. Each event should have:
- title: Short, clear title
- date: YYYY-MM-DD format (use today or tomorrow based on context, or infer from "Monday", "next week", etc.)
- start_time: HH:MM format (24-hour)
- end_time: HH:MM format (24-hour)
- location: Optional location if mentioned
- description: Brief description of the activity

If the user mentions relative times like "morning", "afternoon", "evening", use appropriate times:
- Morning: 6:00-12:00
- Afternoon: 12:00-17:00
- Evening: 17:00-21:00
- Night: 21:00-23:00

For prayers, use standard times:
- Fajr: 5:30-6:00
- Dhuhr: 12:30-13:00
- Asr: 15:30-16:00
- Maghrib: 18:30-19:00
- Isha: 20:00-20:30

Return ONLY valid JSON array, no other text. Example format:
[
  {{"title": "Wake Up", "date": "2025-12-10", "start_time": "06:00", "end_time": "06:15", "location": "", "description": "Wake up and morning routine"}},
  {{"title": "Fajr Prayer", "date": "2025-12-10", "start_time": "06:15", "end_time": "06:30", "location": "", "description": "Morning prayer"}}
]"""

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
    Generate multiple calendar events from natural language description.
    Example: "I want to wake up at 6 AM, pray Fajr, then study from 8-10 AM"
    """
    try:
        # Get current date context
        today = datetime.now()
        tomorrow = today + timedelta(days=1)
        
        # Check if OpenAI API key is valid (starts with "sk-")
        api_key = os.getenv("OPENAI_API_KEY")
        has_valid_openai_key = api_key and is_valid_openai_key(api_key)
        
        # Try OpenAI first (only if we have a valid key)
        client = None
        if has_valid_openai_key:
            client = get_openai_client()
        
        if not client:
            # No OpenAI, try alternatives directly
            gemini_model = get_gemini_model()
            if gemini_model:
                try:
                    prompt = _build_ai_prompt(payload.prompt, today, tomorrow)
                    gemini_response = gemini_model.generate_content(prompt)
                    if gemini_response and gemini_response.text:
                        events_data = _parse_ai_response(gemini_response.text, today)
                        if events_data:
                            return ScheduleResponse(
                                events=events_data,
                                summary=f"✅ Generated {len(events_data)} event(s) using Google Gemini"
                            )
                except Exception as e:
                    print(f"Gemini error: {e}")
            
            # Try Ollama
            prompt = _build_ai_prompt(payload.prompt, today, tomorrow)
            ollama_response = call_ollama(prompt)
            if ollama_response:
                events_data = _parse_ai_response(ollama_response, today)
                if events_data:
                    return ScheduleResponse(
                        events=events_data,
                        summary=f"✅ Generated {len(events_data)} event(s) using Ollama"
                    )
            
            # Fallback
            return _create_fallback_events(payload.prompt, today)
        
        # Build the prompt
        prompt = _build_ai_prompt(payload.prompt, today, tomorrow)
        
        # Try different models in order of preference
        models_to_try = ["gpt-4o-mini", "gpt-3.5-turbo"]
        response = None
        last_error = None
        quota_exceeded = False
        
        for model_name in models_to_try:
            try:
                response = client.chat.completions.create(
                    model=model_name,
                    messages=[
                        {"role": "system", "content": "You are a helpful calendar assistant. Always return valid JSON arrays."},
                        {"role": "user", "content": prompt}
                    ],
                    temperature=0.7,
                    max_tokens=2000,
                )
                break  # Success, exit the loop
            except Exception as openai_error:
                last_error = openai_error
                error_str = str(openai_error)
                print(f"Failed to use model {model_name}: {error_str}")
                
                # Check for quota exceeded
                if "429" in error_str or "insufficient_quota" in error_str or "quota" in error_str.lower():
                    quota_exceeded = True
                    break  # Don't try other models if quota is exceeded
                
                continue  # Try next model
        
        # Handle OpenAI errors - try free alternatives (no keys needed!)
        if response is None:
            error_msg = str(last_error) if last_error else "Unknown error"
            print(f"OpenAI failed: {error_msg}. Trying free alternatives (no API keys needed)...")
            
            # Try Ollama first (completely free, no keys, runs locally)
            print("Trying Ollama (local LLM, no keys needed)...")
            ollama_response = call_ollama(prompt)
            if ollama_response:
                try:
                    events_data = _parse_ai_response(ollama_response, today)
                    if events_data:
                        return ScheduleResponse(
                            events=events_data,
                            summary=f"✅ Generated {len(events_data)} event(s) using Ollama (local, free, no keys needed!)"
                        )
                except Exception as ollama_error:
                    print(f"Ollama parsing error: {ollama_error}")
            
            # Try Google Gemini (free tier, needs GEMINI_API_KEY)
            gemini_model = get_gemini_model()
            if gemini_model:
                try:
                    print("Trying Google Gemini (free tier)...")
                    gemini_response = gemini_model.generate_content(prompt)
                    if gemini_response and gemini_response.text:
                        content = gemini_response.text.strip()
                        print(f"Gemini response received: {content[:200]}")
                        events_data = _parse_ai_response(content, today)
                        if events_data:
                            return ScheduleResponse(
                                events=events_data,
                                summary=f"✅ Generated {len(events_data)} event(s) using Google Gemini (free tier)"
                            )
                except Exception as gemini_error:
                    print(f"Gemini error: {gemini_error}")
            
            # Fallback to keyword-based events (always works, no keys needed)
            print("Using fallback keyword-based generation (no keys needed)...")
            return _create_fallback_events(payload.prompt, today)

        if not response.choices or not response.choices[0].message:
            raise HTTPException(status_code=500, detail="OpenAI returned empty response")
        
        content = response.choices[0].message.content
        if not content:
            raise HTTPException(status_code=500, detail="OpenAI returned empty content")
        
        content = content.strip()
        
        # Clean up the response (remove markdown code blocks if present)
        if content.startswith("```json"):
            content = content[7:]
        if content.startswith("```"):
            content = content[3:]
        if content.endswith("```"):
            content = content[:-3]
        content = content.strip()
        
        print(f"AI Response content (first 500 chars): {content[:500]}")  # Debug log

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
                    raise HTTPException(
                        status_code=500, 
                        detail=f"Failed to parse AI response as JSON. Error: {str(e)}. Content: {content[:200]}"
                    )
            else:
                raise HTTPException(
                    status_code=500, 
                    detail=f"Failed to parse AI response: {str(e)}. Content preview: {content[:200]}"
                )
        
        if not isinstance(events_data, list):
            raise HTTPException(status_code=500, detail="AI response is not a list of events")

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
            except Exception as e:
                # Skip invalid events
                continue

        if not events:
            raise HTTPException(status_code=500, detail="AI generated no valid events")

        return ScheduleResponse(
            events=events,
            summary=f"Generated {len(events)} event(s) from your request"
        )

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

