# API Contract

## Health

```
GET /health
→ { "status": "ok" }
```

## ML

```
POST /api/ml/chat
Body:   { "message": string, "max_tokens": int }
→      { "reply": string, "tokens_used": int }
Auth:  Authorization: Bearer <supabase-jwt>
```

## DB

```
GET /api/db/items
→ [{ "id": uuid, "user_id": uuid, "content": string, "created_at": string }]
Auth: Authorization: Bearer <supabase-jwt>
```

> Extend this file every time a new endpoint is added.
> Keep it as the single source of truth for the API contract.
