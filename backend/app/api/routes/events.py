from fastapi import APIRouter

router = APIRouter(prefix="/events", tags=["events"])


@router.post("/add")
def add_event():
    pass

