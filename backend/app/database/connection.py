from typing import Dict, Optional

from pydantic import BaseModel


class StoredUser(BaseModel):
  id: str
  name: str
  email: str
  password: str  # NOTE: plaintext for demo; replace with hashing in production


class InMemoryDB:
  def __init__(self) -> None:
    self._users: Dict[str, StoredUser] = {}

  def get_by_email(self, email: str) -> Optional[StoredUser]:
    return next((u for u in self._users.values() if u.email == email), None)

  def create_user(self, user: StoredUser) -> StoredUser:
    self._users[user.id] = user
    return user
  def add_event(self, user_id: str, event: Dict) -> None:
    user = self._users.get(user_id)
    if not user:
      raise ValueError("User not found")
    if not hasattr(user, 'events'):
      user.events = []
    user.events.append(event)


# Singleton in-memory store for this demo
db = InMemoryDB()
