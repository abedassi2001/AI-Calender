from pydantic import BaseModel

class AIRequest(BaseModel):
    user_text: str

class AIResponse(BaseModel):
    title: str
    date: str
    start_time: str
    end_time: str
    description: str | None = None
