"""Pydantic schemas for ML API contract."""
from pydantic import BaseModel


class ChatRequest(BaseModel):
    message: str
    max_tokens: int = 256


class ChatResponse(BaseModel):
    reply: str
    tokens_used: int
