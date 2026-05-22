"""ML router — delegates all logic to ml package."""
from fastapi import APIRouter, Depends
from app.schemas.ml import ChatRequest, ChatResponse
from app.dependencies.auth import get_current_user
import ml.services.chat as chat_svc

router = APIRouter()


@router.post("/chat", response_model=ChatResponse)
async def chat(req: ChatRequest, user=Depends(get_current_user)):
    """Run one LLM chat completion."""
    return await chat_svc.run_chat(req)
