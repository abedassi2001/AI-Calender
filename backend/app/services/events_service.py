import os


class EventsService:
    def __init__(self, db):
        self.db = db

    def add_event_to_user(self, user_id: str, event: dict) -> None:
        self.db.add_event(user_id, event)
        