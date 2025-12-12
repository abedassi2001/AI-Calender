import os


class EventsService:
    def __init__(self, db):
        self.db = db

    def add_event_to_user(self, user_id: str, event: dict) -> None:
        self.db.add_event(user_id, event)

    def update_event_for_user(self, user_id: str, event_index: int, event: dict) -> None:
        self.db.update_event(user_id, event_index, event)

    def delete_event_for_user(self, user_id: str, event_index: int) -> None:
        self.db.delete_event(user_id, event_index)
        