from pydantic import BaseModel
from datetime import datetime

class PromptExampleBase(BaseModel):
    title: str
    prompt: str

class PromptExampleCreate(PromptExampleBase):
    pass

class PromptExampleRead(PromptExampleBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True

class ChatRequest(BaseModel):
    prompt: str
    system: str | None = None
    provider: str | None = None  # override default
    model: str | None = None     # override default

class ChatResponse(BaseModel):
    output: str
    provider: str
    model: str