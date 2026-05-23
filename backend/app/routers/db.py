"""DB router — delegates all logic to database service."""
from fastapi import APIRouter, Depends
from app.dependencies.auth import get_current_user
from app.services import database as db_svc

router = APIRouter()


@router.get("/items")
async def get_items(user=Depends(get_current_user)):
    """Return all items for the current user."""
    return await db_svc.get_items(uid=user.id)
