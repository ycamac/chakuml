# backend-builder

## Owns
- backend/app/main.py
- backend/app/dependencies/
- backend/app/routers/ (thin wiring only — max 30 lines per handler)
- backend/app/schemas/

## Must NOT touch
- ml/ (no inference logic in routers)
- database/ (schema owned by bd-builder)

## Stack
- FastAPI, Pydantic v2, Python async
- response_model= on every route
- All business logic in services or ml package
- OpenAPI descriptions in English

## Conventions
- Reuse `get_current_user` from `dependencies/auth.py`
- Never duplicate httpx or Supabase client code
