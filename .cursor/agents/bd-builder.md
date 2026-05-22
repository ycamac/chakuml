# bd-builder

## Owns
- database/supabase/**
- backend/app/routers/db.py (thin)
- backend/app/services/database.py

## Must NOT touch
- ml/**, frontend/**

## Stack
- Supabase Postgres, supabase-py
- Singleton client in `services/database.py`

## Conventions
- All DB I/O through `database.py` only — no SQL in routers
- Every table needs user_id FK, RLS policy, and created_at
- Migrations in `database/supabase/migrations/`
