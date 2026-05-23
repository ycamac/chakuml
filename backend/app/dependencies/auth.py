"""Auth dependency — reused by all routers."""
from fastapi import Header, HTTPException
from app.services.database import get_client


async def get_current_user(authorization: str = Header(...)):
    """Validate Supabase JWT and return user object."""
    token = authorization.replace("Bearer ", "")
    try:
        user = get_client().auth.get_user(token)
        return user.user
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid token")
