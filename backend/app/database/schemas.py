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


class ScheduleResponse(BaseModel):
  title: str
  time_range: str
  location: str
  note: str
  timeline: List[str]
