# Agents

| Agent            | Owns                                                      | Must NOT touch            |
|------------------|-----------------------------------------------------------|---------------------------|
| frontend-builder | frontend/**                                               | backend/, ml/, database/  |
| backend-builder  | main.py, dependencies/, routers/, schemas/                | Inference code in routers |
| bd-builder       | database/supabase/**, routers/db.py, services/database.py | ml/**, frontend/**        |
| ml-ops           | ml/**                                                     | database/, frontend/      |
| test-guard       | tests/**, tools/validate.sh                               | Feature code              |

## Ownership map

```
frontend/                          → frontend-builder
backend/app/main.py, dependencies/ → backend-builder
backend/app/routers/db.py          → bd-builder
backend/app/services/database.py   → bd-builder
backend/app/routers/ml.py          → backend-builder (wiring) + ml-ops (logic in ml/)
backend/app/schemas/               → backend-builder
ml/                                → ml-ops
database/supabase/                 → bd-builder
tests/**, tools/validate.sh        → test-guard
docs/                              → orchestrator / all agents (read-only)
```

## Collaboration rules

1. Define `docs/API.md` and domain types on Day 1 before splitting work.
2. backend-builder wires `app.include_router`; ml-ops and bd-builder own service bodies.
3. `shared/` is for code used by 2+ layers only — keep it minimal.
4. Never push directly to main — use short-lived feature branches.
5. Run `bash tools/validate.sh` before every commit.
