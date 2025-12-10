import os
from openai import OpenAI
from app.database.ai_schema import AIResponse
from app.utils.config import OPENAI_KEY
class AIService:
    def __init__(self):
        self.client = OpenAI(api_key=OPENAI_KEY)


    async def generate_event_from_text(self, text: str) -> AIResponse:
        prompt = f"""
        Convert this text into a structured calendar event:

        "{text}"

        Respond ONLY as JSON with:
        - title
        - date (YYYY-MM-DD)
        - start_time (HH:MM)
        - end_time (HH:MM)
        - description
        """

        response = self.client.chat.completions.create(
            model="gpt-4.1",
            messages=[{"role": "user", "content": prompt}]
        )

        event_json = response.choices[0].message.content.strip()
        event_dict = eval(event_json)   # or use json.loads()

        return AIResponse(**event_dict)
