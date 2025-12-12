from pydantic import BaseModel, EmailStr
from typing import Optional, List


class UserCreate(BaseModel):
  name: str
  email: EmailStr
  password: str


class UserLogin(BaseModel):
  email: EmailStr
  password: str


class UserPublic(BaseModel):
  id: str
  name: str
  email: EmailStr


class TokenResponse(BaseModel):
  token: str
  user: UserPublic


class ScheduleRequest(BaseModel):
  prompt: str


class EventItem(BaseModel):
  title: str
  date: str  # YYYY-MM-DD
  start_time: str  # HH:MM
  end_time: str  # HH:MM
  location: str = ""
  description: str = ""


class ScheduleResponse(BaseModel):
  events: List[EventItem]
  summary: str = ""  # Optional summary of what was generated
