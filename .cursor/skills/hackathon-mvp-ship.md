# Skill: Hackathon MVP Ship Order

Follow this order to avoid blockers:

1. Define domain tables in `database/supabase/schema.sql` → run in Supabase SQL Editor
2. `backend/app/services/database.py` → verify Supabase connection
3. `backend/app/routers/db.py` → test `GET /api/db/items` returns 200
4. `ml/clients/llama.py` → verify `health_check()` passes
5. `ml/services/chat.py` → test `POST /api/ml/chat` returns reply
6. `frontend/src/lib/api.ts` → wire endpoints
7. Frontend UI → build pages using shadcn/ui + layout components
8. ngrok → expose backend, set API_URL in Vercel env vars
9. Vercel deploy → push, verify production
