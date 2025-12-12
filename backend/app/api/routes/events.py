from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Dict

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
    # Debug: Check if user exists
    user = db.get_by_id(payload.user_id)
    if not user:
        # List available user IDs for debugging
        available_ids = list(db._users.keys())
        print(f"DEBUG: User {payload.user_id} not found. Available users: {available_ids}")
        raise HTTPException(
            status_code=404, 
            detail=f"User not found with ID: {payload.user_id}. The server may have restarted. Please log in again. Available users: {len(available_ids)}"
        )
    
    try:
        # store the raw VEVENT string as the event payload; services/db may extend later
        events_service.add_event_to_user(payload.user_id, {"vevent": payload.vevent})
    except ValueError as e:
        # Provide more helpful error message
        raise HTTPException(
            status_code=404, 
            detail=f"User not found with ID: {payload.user_id}. Make sure you're logged in and the user exists."
        )

    return {"status": "ok", "message": "Event added successfully"}


@router.get("/{user_id}", response_model=List[Dict])
def get_user_events(user_id: str):
    """Get all events for a user by user_id."""
    user = db.get_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail=f"User not found with ID: {user_id}")
    
    return user.events

