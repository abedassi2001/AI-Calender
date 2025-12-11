from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.services.events_service import EventsService
from app.database.connection import db

router = APIRouter(prefix="/events", tags=["events"]) 


class EventCreate(BaseModel):
    user_id: str
    vevent: str


events_service = EventsService(db)


@router.post("/add")
def add_event(payload: EventCreate):
    """Add a VEVENT provided by the user to their calendar.

    Body: { "user_id": "<id>", "vevent": "BEGIN:VTIMEZONE...END:VEVENT" }
    """
    try:
        # store the raw VEVENT string as the event payload; services/db may extend later
        events_service.add_event_to_user(payload.user_id, {"vevent": payload.vevent})
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

    return {"status": "ok", "message": "Event added"}

