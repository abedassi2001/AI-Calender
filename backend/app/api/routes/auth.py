from fastapi import APIRouter, HTTPException
from uuid import uuid4

from app.database.connection import db, StoredUser
from app.database.schemas import UserCreate, UserLogin, TokenResponse, UserPublic

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=TokenResponse)
def register(payload: UserCreate):
  existing = db.get_by_email(payload.email)
  if existing:
    raise HTTPException(status_code=400, detail="Email already registered")

  user = StoredUser(
    id=str(uuid4()),
    name=payload.name,
    email=payload.email,
    password=payload.password,  # NOTE: plaintext for demo; hash in production
  )
  db.create_user(user)

  token = f"demo-token-{user.id}"
  return TokenResponse(token=token, user=UserPublic(**user.model_dump()))


@router.post("/login", response_model=TokenResponse)
def login(payload: UserLogin):
  user = db.get_by_email(payload.email)
  if not user or user.password != payload.password:
    raise HTTPException(status_code=401, detail="Invalid credentials")

  token = f"demo-token-{user.id}"
  return TokenResponse(token=token, user=UserPublic(**user.model_dump()))
