from fastapi import APIRouter, HTTPException
from app.database.ai_schema import AIRequest, AIResponse
from app.services.openai_service import AIService

router = APIRouter(prefix="/ai", tags=["ai"])
ai_service = AIService()

@router.post("/generate", response_model=AIResponse)
async def generate_event(data: AIRequest):
    """
    Generate a structured event from natural language using AI.
    Example Input:
        "I want to study math next Monday from 3 pm to 5 pm"

    Returns:
        A formal event object (title, date, start_time, end_time, description)
    """

    try:
        event = await ai_service.generate_event_from_text(data.user_text)
        return event

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
