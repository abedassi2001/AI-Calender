from fastapi import APIRouter, HTTPException

from app.database.connection import db
from app.database.schemas import UserPublic

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/me", response_model=UserPublic)
def me(email: str):
  user = db.get_by_email(email)
  if not user:
    raise HTTPException(status_code=404, detail="User not found")
  return UserPublic(**user.model_dump())

