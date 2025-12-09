from fastapi import APIRouter

from app.database.schemas import ScheduleRequest, ScheduleResponse

router = APIRouter(prefix="/chat", tags=["chat"])


@router.post("/generate", response_model=ScheduleResponse)
def generate_schedule(payload: ScheduleRequest):
  # Demo response; replace with real AI logic
  return ScheduleResponse(
    title="AI Scheduled Task",
    time_range="Tomorrow · 3:00 PM – 5:00 PM",
    location="Library, 2nd Floor",
    note="Includes 15m break; remind 20m before.",
    timeline=[
      "3:00 PM  Deep focus block",
      "4:00 PM  Break + review notes",
      "4:15 PM  Flashcards & practice",
      "5:00 PM  Wrap & summary",
    ],
  )

