# Chaku Cursor — Project Scaffold
> Infrastructure baseline for a 24-hour hackathon.
> Topic-specific code (DB schema, business logic, ML prompts) is added on top of this scaffold — never inside it.

---

## Stack

| Layer    | Technology                          | Host                     |
|----------|-------------------------------------|--------------------------|
| Frontend | Next.js 14 + Tailwind + shadcn/ui   | Vercel                   |
| Backend  | FastAPI (Python)                    | Local laptop via ngrok   |
| ML / LLM | llama.cpp (local GPU RTX 4000)      | Local laptop             |
| Database | Supabase (Postgres + Auth)          | Supabase Cloud           |

---

## 1. Root structure

```
chaku_cursor/
├── frontend/
├── backend/
├── ml/
├── database/
├── shared/
├── tests/
├── tools/
├── docs/
├── .cursor/
│   ├── agents/
│   ├── rules/
│   └── skills/
├── .env.example
├── .gitignore
├── Makefile
└── AGENTS.md
```

---

## 2. Environment variables

**File: `.env.example`**

```bash
# ── frontend (Vercel) ──────────────────────────────
NEXT_PUBLIC_SUPA_URL=          # Supabase project URL (auth only)
NEXT_PUBLIC_SUPA_ANON_KEY=     # anon key (auth only)
API_URL=http://127.0.0.1:8000  # FastAPI base URL (server-side only, not exposed to browser)

# ── backend ────────────────────────────────────────
SUPA_URL=
SUPA_SERVICE_KEY=              # service role key — backend only, never in frontend
API_CORS_ORIGINS=http://localhost:3000

# ── ml ─────────────────────────────────────────────
LLAMA_BASE_URL=http://127.0.0.1:8080/v1
ML_MODELS_DIR=./models
CHAT_MODEL_PATH=./models/chat.gguf
```

---

## 3. Makefile

**File: `Makefile`**

```makefile
.PHONY: dev-ml dev-backend dev-frontend dev-all test-contracts lint validate

dev-ml:
	cd ml && bash startup.sh

dev-backend:
	cd backend && uvicorn app.main:app --reload --port 8000

dev-frontend:
	cd frontend && npm run dev

dev-all:
	make dev-ml & make dev-backend & make dev-frontend

test-contracts:
	cd tests/contracts && pytest -v

lint:
	ruff check backend/ ml/

validate:
	bash tools/validate.sh
```

---

## 4. Frontend

### 4.1 Package

**File: `frontend/package.json`**

```json
{
  "name": "chaku-frontend",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start"
  },
  "dependencies": {
    "next": "14.2.0",
    "react": "^18",
    "react-dom": "^18",
    "@supabase/supabase-js": "^2",
    "@supabase/ssr": "^0.1.0",
    "class-variance-authority": "^0.7.0",
    "clsx": "^2.1.0",
    "lucide-react": "^0.395.0",
    "tailwind-merge": "^2.3.0"
  },
  "devDependencies": {
    "typescript": "^5",
    "@types/react": "^18",
    "@types/node": "^20",
    "tailwindcss": "^3",
    "autoprefixer": "^10",
    "postcss": "^8"
  }
}
```

> After `npm install`, initialise shadcn/ui: `npx shadcn-ui@latest init`
> Answer: TypeScript yes, style Default, base color Slate, CSS variables yes, `src/` yes, App Router yes.
> Components land in `frontend/src/components/ui/` — never edit them manually.

### 4.2 TypeScript config

**File: `frontend/tsconfig.json`**

```json
{
  "compilerOptions": {
    "target": "ES2017",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
```

### 4.3 Tailwind config

**File: `frontend/tailwind.config.ts`**

```typescript
import type { Config } from 'tailwindcss'

const config: Config = {
  darkMode: ['class'],
  content: [
    './src/pages/**/*.{ts,tsx}',
    './src/components/**/*.{ts,tsx}',
    './src/app/**/*.{ts,tsx}',
  ],
  theme: {
    container: {
      center: true,
      padding: '2rem',
      screens: { '2xl': '1400px' },
    },
    extend: {
      // All colors reference CSS variables defined in globals.css.
      // Change the variables once — the whole UI updates.
      colors: {
        border: 'hsl(var(--border))',
        input: 'hsl(var(--input))',
        ring: 'hsl(var(--ring))',
        background: 'hsl(var(--background))',
        foreground: 'hsl(var(--foreground))',
        primary: {
          DEFAULT: 'hsl(var(--primary))',
          foreground: 'hsl(var(--primary-foreground))',
        },
        secondary: {
          DEFAULT: 'hsl(var(--secondary))',
          foreground: 'hsl(var(--secondary-foreground))',
        },
        destructive: {
          DEFAULT: 'hsl(var(--destructive))',
          foreground: 'hsl(var(--destructive-foreground))',
        },
        muted: {
          DEFAULT: 'hsl(var(--muted))',
          foreground: 'hsl(var(--muted-foreground))',
        },
        accent: {
          DEFAULT: 'hsl(var(--accent))',
          foreground: 'hsl(var(--accent-foreground))',
        },
        card: {
          DEFAULT: 'hsl(var(--card))',
          foreground: 'hsl(var(--card-foreground))',
        },
      },
      borderRadius: {
        lg: 'var(--radius)',
        md: 'calc(var(--radius) - 2px)',
        sm: 'calc(var(--radius) - 4px)',
      },
      fontFamily: {
        sans: ['var(--font-sans)', 'system-ui', 'sans-serif'],
        mono: ['var(--font-mono)', 'monospace'],
      },
      // Single type scale — use these classes everywhere, never arbitrary sizes.
      fontSize: {
        'display': ['3rem', { lineHeight: '1.1', fontWeight: '700' }],
        'heading': ['1.5rem', { lineHeight: '1.3', fontWeight: '600' }],
        'subheading': ['1.125rem', { lineHeight: '1.4', fontWeight: '600' }],
        'body': ['0.9375rem', { lineHeight: '1.6', fontWeight: '400' }],
        'small': ['0.8125rem', { lineHeight: '1.5', fontWeight: '400' }],
        'label': ['0.75rem', { lineHeight: '1.4', fontWeight: '500', letterSpacing: '0.05em' }],
      },
    },
  },
  plugins: [require('tailwindcss-animate')],
}

export default config
```

### 4.4 Global CSS — design tokens

**File: `frontend/src/app/globals.css`**

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

/*
  CSS variables follow shadcn/ui convention (HSL without the hsl() wrapper).
  Adjust hue/saturation/lightness here to retheme the whole product.
  Light mode defaults — Slate base, Indigo primary.
*/
@layer base {
  :root {
    --background:    0 0% 100%;
    --foreground:    222 47% 11%;

    --card:          0 0% 100%;
    --card-foreground: 222 47% 11%;

    --primary:       243 75% 59%;    /* Indigo-500 */
    --primary-foreground: 0 0% 100%;

    --secondary:     215 25% 95%;
    --secondary-foreground: 222 47% 11%;

    --muted:         215 25% 95%;
    --muted-foreground: 215 16% 47%;

    --accent:        243 75% 95%;
    --accent-foreground: 243 75% 35%;

    --destructive:   0 84% 60%;
    --destructive-foreground: 0 0% 100%;

    --border:        215 25% 90%;
    --input:         215 25% 90%;
    --ring:          243 75% 59%;

    --radius:        0.625rem;

    --font-sans: 'Geist', 'Inter', system-ui, sans-serif;
    --font-mono: 'Geist Mono', 'Fira Code', monospace;
  }

  .dark {
    --background:    222 47% 8%;
    --foreground:    213 31% 91%;

    --card:          222 47% 11%;
    --card-foreground: 213 31% 91%;

    --primary:       243 75% 65%;
    --primary-foreground: 222 47% 8%;

    --secondary:     222 47% 15%;
    --secondary-foreground: 213 31% 91%;

    --muted:         222 47% 15%;
    --muted-foreground: 215 16% 60%;

    --accent:        243 75% 20%;
    --accent-foreground: 243 75% 80%;

    --destructive:   0 63% 55%;
    --destructive-foreground: 0 0% 100%;

    --border:        222 47% 18%;
    --input:         222 47% 18%;
    --ring:          243 75% 65%;
  }

  * {
    @apply border-border;
  }

  body {
    @apply bg-background text-foreground font-sans antialiased;
    font-size: theme('fontSize.body[0]');
    line-height: theme('fontSize.body[1].lineHeight');
  }

  /* Typography helpers — use these classes, never arbitrary sizes */
  .text-display   { @apply text-display tracking-tight; }
  .text-heading   { @apply text-heading; }
  .text-subheading{ @apply text-subheading; }
  .text-body      { @apply text-body; }
  .text-small     { @apply text-small; }
  .text-label     { @apply text-label uppercase tracking-widest; }
}
```

### 4.5 Root layout

**File: `frontend/src/app/layout.tsx`**

```tsx
import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'Chaku',
  description: 'Hackathon project',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body>{children}</body>
    </html>
  )
}
```

### 4.6 Home page

**File: `frontend/src/app/page.tsx`**

```tsx
export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center gap-4 p-8">
      <h1 className="text-display">Chaku</h1>
      <p className="text-body text-muted-foreground">Hackathon — ready to build.</p>
    </main>
  )
}
```

### 4.7 Shared layout components

These transversal components enforce consistent spacing, max-width, and navigation across every page.
Add or extend them; never recreate equivalent wrappers elsewhere.

**File: `frontend/src/components/layout/PageWrapper.tsx`**

```tsx
import { cn } from '@/lib/utils'

interface PageWrapperProps {
  children: React.ReactNode
  className?: string
}

/** Full-height page container with consistent max-width and padding. */
export function PageWrapper({ children, className }: PageWrapperProps) {
  return (
    <div className={cn('mx-auto w-full max-w-screen-xl px-4 py-8 sm:px-8', className)}>
      {children}
    </div>
  )
}
```

**File: `frontend/src/components/layout/Header.tsx`**

```tsx
import Link from 'next/link'

/** Top navigation bar — update nav items as features are added. */
export function Header() {
  return (
    <header className="sticky top-0 z-40 w-full border-b border-border bg-background/80 backdrop-blur">
      <div className="mx-auto flex h-14 max-w-screen-xl items-center justify-between px-4 sm:px-8">
        <Link href="/" className="text-subheading font-bold text-primary">
          Chaku
        </Link>
        <nav className="flex items-center gap-4 text-small text-muted-foreground">
          {/* Add nav links here */}
        </nav>
      </div>
    </header>
  )
}
```

**File: `frontend/src/components/layout/index.ts`**

```typescript
export { Header } from './Header'
export { PageWrapper } from './PageWrapper'
```

### 4.8 Utility — cn helper

shadcn/ui requires this. Verify it was created by `shadcn-ui init`; add it manually if not.

**File: `frontend/src/lib/utils.ts`**

```typescript
import { clsx, type ClassValue } from 'clsx'
import { twMerge } from 'tailwind-merge'

/** Merge Tailwind classes without conflicts. Used by all shadcn/ui components. */
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}
```

### 4.9 API client

**File: `frontend/src/lib/api.ts`**

```typescript
const API_URL = process.env.NEXT_PUBLIC_API_URL ?? ''

/** Call a FastAPI /api/ml/* endpoint and return JSON. */
export async function callML(endpoint: string, body: unknown) {
  const res = await fetch(`${API_URL}/api/ml/${endpoint}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  })
  if (!res.ok) throw new Error(`ML API error: ${res.status}`)
  return res.json()
}

/** Call a FastAPI /api/db/* endpoint and return JSON. */
export async function callDB(endpoint: string, body?: unknown) {
  const res = await fetch(`${API_URL}/api/db/${endpoint}`, {
    method: body ? 'POST' : 'GET',
    headers: { 'Content-Type': 'application/json' },
    body: body ? JSON.stringify(body) : undefined,
  })
  if (!res.ok) throw new Error(`DB API error: ${res.status}`)
  return res.json()
}
```

### 4.10 Supabase client (auth only)

**File: `frontend/src/lib/supabase.ts`**

```typescript
import { createBrowserClient } from '@supabase/ssr'

/** Auth-only Supabase client. Never use for table CRUD — use callDB() instead. */
export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPA_URL!,
    process.env.NEXT_PUBLIC_SUPA_ANON_KEY!
  )
}
```

### 4.11 Next.js config

**File: `frontend/next.config.js`**

```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
  async rewrites() {
    return [
      {
        source: '/api/ml/:path*',
        destination: `${process.env.API_URL}/api/ml/:path*`,
      },
      {
        source: '/api/db/:path*',
        destination: `${process.env.API_URL}/api/db/:path*`,
      },
    ]
  },
}

module.exports = nextConfig
```

---

## 5. Backend

**File: `backend/requirements.txt`**

```
fastapi>=0.111.0
uvicorn[standard]>=0.29.0
httpx>=0.27.0
pydantic>=2.0.0
supabase>=2.4.0
python-dotenv>=1.0.0
ruff>=0.4.0
pytest>=8.0.0
```

**File: `backend/app/main.py`**

```python
"""FastAPI application factory."""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import os

from app.routers import ml, db

load_dotenv()

app = FastAPI(title="Chaku API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("API_CORS_ORIGINS", "http://localhost:3000").split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(ml.router, prefix="/api/ml", tags=["ml"])
app.include_router(db.router, prefix="/api/db", tags=["db"])


@app.get("/health")
async def health():
    return {"status": "ok"}
```

**File: `backend/app/routers/ml.py`**

```python
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
```

**File: `backend/app/routers/db.py`**

```python
"""DB router — delegates all logic to database service."""
from fastapi import APIRouter, Depends
from app.dependencies.auth import get_current_user
from app.services import database as db_svc

router = APIRouter()


@router.get("/items")
async def get_items(user=Depends(get_current_user)):
    """Return all items for the current user."""
    return await db_svc.get_items(uid=user.id)
```

**File: `backend/app/schemas/ml.py`**

```python
"""Pydantic schemas for ML API contract."""
from pydantic import BaseModel


class ChatRequest(BaseModel):
    message: str
    max_tokens: int = 256


class ChatResponse(BaseModel):
    reply: str
    tokens_used: int
```

**File: `backend/app/services/database.py`**

```python
"""Single Supabase client module — only place for DB I/O."""
from supabase import create_client, Client
from dotenv import load_dotenv
import os

load_dotenv()

_client: Client | None = None


def get_client() -> Client:
    """Return singleton Supabase client."""
    global _client
    if _client is None:
        _client = create_client(
            os.environ["SUPA_URL"],
            os.environ["SUPA_SERVICE_KEY"],
        )
    return _client


async def get_items(uid: str) -> list:
    """Fetch all items belonging to user uid."""
    client = get_client()
    resp = client.table("items").select("*").eq("user_id", uid).execute()
    return resp.data
```

**File: `backend/app/dependencies/auth.py`**

```python
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
```

---

## 6. ML package

**File: `ml/config.py`**

```python
"""ML environment config — single source of truth for paths and URLs."""
from dotenv import load_dotenv
import os

load_dotenv()

LLAMA_BASE_URL: str = os.getenv("LLAMA_BASE_URL", "http://127.0.0.1:8080/v1")
ML_MODELS_DIR: str = os.getenv("ML_MODELS_DIR", "./models")
CHAT_MODEL_PATH: str = os.getenv("CHAT_MODEL_PATH", "./models/chat.gguf")
```

**File: `ml/clients/llama.py`**

```python
"""HTTP client for llama.cpp server."""
import httpx
from ml.config import LLAMA_BASE_URL


async def complete(prompt: str, max_tokens: int = 256) -> dict:
    """Send a completion request to llama.cpp and return raw response."""
    async with httpx.AsyncClient(timeout=60.0) as client:
        resp = await client.post(
            f"{LLAMA_BASE_URL}/completions",
            json={"prompt": prompt, "n_predict": max_tokens},
        )
        resp.raise_for_status()
        return resp.json()


async def health_check() -> bool:
    """Ping llama.cpp server; return True if reachable."""
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            resp = await client.get(f"{LLAMA_BASE_URL}/health")
            return resp.status_code == 200
    except Exception:
        return False
```

**File: `ml/services/chat.py`**

```python
"""LLM chat inference service."""
from ml.clients.llama import complete


async def run_chat(req) -> dict:
    """Run one chat completion against the local LLM."""
    raw = await complete(prompt=req.message, max_tokens=req.max_tokens)
    return {
        "reply": raw.get("content", ""),
        "tokens_used": raw.get("tokens_evaluated", 0),
    }
```

**File: `ml/services/predict.py`**

```python
"""Predictive model service — placeholder for classification/regression."""


async def run_predict(features: dict) -> dict:
    """Run prediction against a loaded model. Implement per use-case."""
    # TODO: load model from ml/config.CHAT_MODEL_PATH and run inference
    return {"prediction": None, "confidence": None}
```

**File: `ml/startup.sh`**

```bash
#!/bin/bash
# Start llama.cpp server with GPU offload (RTX 4000 Ada).
# Adjust -ngl (GPU layers) per model size.
set -e

source ../.env 2>/dev/null || true
MODEL=${CHAT_MODEL_PATH:-./models/chat.gguf}

echo "Starting llama.cpp — model: $MODEL"

./server \
  -m "$MODEL" \
  --host 0.0.0.0 \
  --port 8080 \
  -ngl 35 \
  --ctx-size 2048 \
  --threads 8
```

**File: `ml/runtime.md`**

```markdown
# ML Runtime

## Requirements
- llama.cpp compiled with CUDA support
- RTX 4000 Ada (12 GB VRAM)
- Model file (GGUF) placed in `./models/` — never committed to git

## Start

```bash
make dev-ml
# or: bash ml/startup.sh
```

## Health check

```bash
curl http://localhost:8080/v1/health
```

## Key flags

| Flag        | Value | Description                      |
|-------------|-------|----------------------------------|
| -ngl        | 35    | GPU layers — increase for larger models if VRAM allows |
| --ctx-size  | 2048  | Context window                   |
| --port      | 8080  | llama.cpp port                   |

## Recommended GGUF models (Q4, fits in 12 GB)

- Llama 3.1 8B Q4  (~5 GB VRAM)
- Mistral 7B Q4    (~4 GB VRAM)
- Phi-3 Mini Q4    (~2 GB VRAM)
```

---

## 7. Database

Topic-specific tables and migrations are defined **after** the hackathon domain is decided.
Only the placeholder files are scaffolded here.

**File: `database/supabase/schema.sql`**

```sql
-- Define project-specific tables here.
-- Run in Supabase SQL Editor (Dashboard → SQL Editor → New query).
--
-- Required pattern for every table:
--   id          uuid primary key default gen_random_uuid()
--   user_id     uuid references auth.users(id) on delete cascade
--   created_at  timestamptz default now()
--
-- Add an index on user_id for every user-scoped table:
--   create index if not exists <table>_user_id_idx on <table>(user_id);
--
-- Enable Row Level Security and add policies before going to production.
```

**File: `database/supabase/migrations/.gitkeep`**

```
```

---

## 8. Tests

**File: `tests/contracts/test_health.py`**

```python
"""Contract test: health endpoint must return 200."""
import httpx

BASE_URL = "http://localhost:8000"


def test_health():
    """GET /health returns 200 and status ok."""
    resp = httpx.get(f"{BASE_URL}/health")
    assert resp.status_code == 200
    assert resp.json()["status"] == "ok"
```

**File: `tests/contracts/test_ml_api.py`**

```python
"""Contract test: /api/ml/chat must return 200 or 401, never 500."""
import httpx

BASE_URL = "http://localhost:8000"


def test_ml_chat_shape():
    resp = httpx.post(
        f"{BASE_URL}/api/ml/chat",
        json={"message": "hello", "max_tokens": 10},
        headers={"Authorization": "Bearer test-token"},
    )
    assert resp.status_code in (200, 401)
```

**File: `tests/contracts/test_db_api.py`**

```python
"""Contract test: /api/db/items must return 200 or 401, never 500."""
import httpx

BASE_URL = "http://localhost:8000"


def test_db_items_shape():
    resp = httpx.get(
        f"{BASE_URL}/api/db/items",
        headers={"Authorization": "Bearer test-token"},
    )
    assert resp.status_code in (200, 401)
```

---

## 9. Tools

**File: `tools/validate.sh`**

```bash
#!/bin/bash
# Pre-commit gate. Run before every commit.
set -e

echo "── Contract tests ──"
pytest tests/contracts/ -v

echo "── Lint backend ──"
ruff check backend/

echo "── Lint ml ──"
ruff check ml/

echo "── All checks passed ──"
```

**File: `tools/ngrok.yml`**

```yaml
version: "2"
tunnels:
  backend:
    proto: http
    addr: 8000
    inspect: true
```

---

## 10. Cursor agents

**File: `.cursor/agents/frontend-builder.md`**

```markdown
# frontend-builder

## Owns
- frontend/** (all files)

## Must NOT touch
- backend/, ml/, database/

## Stack
- Next.js 14, Tailwind CSS, shadcn/ui, TypeScript strict
- All API calls through `frontend/src/lib/api.ts`
- Auth only through `frontend/src/lib/supabase.ts`
- Never call Supabase directly for table CRUD

## Conventions
- Components in `frontend/src/components/`
  - `ui/` — shadcn/ui generated components (never hand-edit)
  - `layout/` — Header, PageWrapper, and other transversal wrappers
  - `features/` — one subfolder per feature
- Pages in `frontend/src/app/`
- Consistent typography: use the scale classes defined in globals.css
  (`text-display`, `text-heading`, `text-subheading`, `text-body`, `text-small`, `text-label`)
  Never use arbitrary font sizes (e.g. `text-[17px]`).
- Consistent colors: use semantic tokens (`text-foreground`, `text-muted-foreground`,
  `bg-background`, `bg-card`, `text-primary`, etc.)
  Never use raw Tailwind palette classes (`text-slate-700`, `bg-indigo-500`).
- Use shadcn/ui components before writing custom ones
- Keep components under 100 lines; extract if larger
```

**File: `.cursor/agents/backend-builder.md`**

```markdown
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
```

**File: `.cursor/agents/bd-builder.md`**

```markdown
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
```

**File: `.cursor/agents/ml-ops.md`**

```markdown
# ml-ops

## Owns
- ml/** (entirely)

## Must NOT touch
- database/, frontend/
- No logic inside backend/app/routers/ml.py

## Stack
- Python async, httpx for llama.cpp client
- llama.cpp HTTP API (OpenAI-compatible)
- scikit-learn for predictive models (optional)

## Conventions
- All LLM calls through `ml/clients/llama.py`
- Services in `ml/services/` — one file per concern
- No model weights in git — paths from `ml/config.py`
- Every function has a one-line English docstring
```

**File: `.cursor/agents/test-guard.md`**

```markdown
# test-guard

## Owns
- tests/contracts/**
- tests/e2e/**
- tools/validate.sh

## Must NOT touch
- Feature code, schemas

## Purpose
Pre-commit gate. Updates contract tests when API or schema changes.
Fails if endpoint paths are duplicated or if clients (httpx, Supabase) are
copied across modules instead of using the shared singleton.

## Run
bash tools/validate.sh
```

---

## 11. Cursor rules

**File: `.cursor/rules/code-standards.mdc`**

```
---
alwaysApply: true
---

# Code Standards

- All documentation, comments, docstrings, and commit messages in English.
- Variable names: short but meaningful (uid, req, cfg, resp).
- Every function must have a one-line English docstring.
- DRY: before adding code, check for existing helpers in ml/, backend/app/services/, or shared/.
- Max 30 lines per router handler; extract to service if larger.
- No TODO comments committed — finish it or open an issue.
```

**File: `.cursor/rules/architecture-boundaries.mdc`**

```
---
alwaysApply: true
---

# Architecture Boundaries

- frontend/ → Auth via Supabase only; all ML and data calls via lib/api.ts to API_URL.
- ml/ → no Supabase imports, no Next.js imports.
- backend/app/routers/ml.py → no model weights, prompts, or httpx calls (those belong in ml/).
- No duplicated helpers — extract to shared/ or the owning package.
```

**File: `.cursor/rules/hackathon-ship.mdc`**

```
---
alwaysApply: true
---

# Hackathon Shipping Rules

- MVP scope only. No premature optimisation.
- Small, frequent commits.
- Ship order: database schema → /api/db → ml/ + /api/ml → frontend → ngrok → Vercel.
- If a feature takes more than 2 h, simplify it.
- No custom CSS — use Tailwind utility classes and shadcn/ui components.
- No inline styles.
```

**File: `.cursor/rules/frontend-design-system.mdc`**

```
---
globs: frontend/**
---

# Frontend Design System

## Typography
Use only the scale classes from globals.css:
  text-display | text-heading | text-subheading | text-body | text-small | text-label
Never use arbitrary sizes (text-[15px], text-xl mixed with text-2xl, etc.).

## Colors
Use only semantic tokens:
  text-foreground | text-muted-foreground | text-primary
  bg-background | bg-card | bg-muted
  border-border
Never use raw palette classes (text-slate-700, bg-indigo-500).
To change the brand color, update --primary in globals.css.

## Components
1. shadcn/ui first (Button, Card, Input, Dialog, etc.)
2. Layout wrappers from src/components/layout/ (Header, PageWrapper)
3. Feature components in src/components/features/<feature-name>/
Never re-implement a component that shadcn/ui already provides.

## Spacing
Use the default Tailwind spacing scale (p-4, gap-6, etc.).
Max page width: max-w-screen-xl (set in PageWrapper).
```

**File: `.cursor/rules/fastapi-backend.mdc`**

```
---
globs: backend/**
---

# FastAPI Conventions

- App factory in app/main.py; include routers with prefix + tags.
- APIRouter per domain (ml, db); no business logic in router files.
- Pydantic v2 models in app/schemas/; always use response_model=.
- Dependencies in app/dependencies/ (get_current_user).
- Async routes for all I/O-bound operations.
```

**File: `.cursor/rules/ml-package.mdc`**

```
---
globs: ml/**
---

# ML Package Rules

- All ML inference code lives here — never in backend/app/routers/.
- No model weights committed to git — use paths from ml/config.py.
- Single llama.cpp client in ml/clients/llama.py — never duplicated.
- Services in ml/services/ — one concern per file.
```

---

## 12. Cursor skills

**File: `.cursor/skills/hackathon-mvp-ship.md`**

```markdown
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
```

**File: `.cursor/skills/ngrok-dev-tunnel.md`**

```markdown
# Skill: ngrok Dev Tunnel

## Start

```bash
ngrok start --config tools/ngrok.yml backend
```

## Update frontend

Copy the ngrok HTTPS URL and set in Vercel dashboard:
```
API_URL=https://xxxx.ngrok-free.app
```

## Notes
- Each ngrok restart generates a new URL → update Vercel env and redeploy.
- Verify: `curl https://xxxx.ngrok-free.app/health`
```

---

## 13. Docs

**File: `docs/ARCHITECTURE.md`**

```markdown
# Architecture

## Overview

```
Browser → Next.js (Vercel) → FastAPI (ngrok) → llama.cpp (local GPU)
                                   ↕
                              Supabase (Postgres + Auth)
```

## Layer responsibilities

| Layer      | Responsibility                                            |
|------------|-----------------------------------------------------------|
| frontend/  | UI, Auth via Supabase, proxy ML + DB calls to API_URL     |
| backend/   | HTTP routing, JWT validation, thin delegation             |
| ml/        | All LLM and predictive model logic                        |
| database/  | Schema, migrations (topic-specific — defined separately)  |

## API prefixes

| Prefix       | Implemented by                                       |
|--------------|------------------------------------------------------|
| /api/ml/*    | ml/services/ via backend/app/routers/ml.py           |
| /api/db/*    | backend/app/services/database.py via routers/db.py   |
| /health      | backend/app/main.py                                  |

## Frontend component hierarchy

```
src/
├── app/               ← Next.js App Router pages
│   ├── layout.tsx     ← Root layout (fonts, global CSS)
│   └── page.tsx       ← Home page
├── components/
│   ├── ui/            ← shadcn/ui generated (do not edit)
│   ├── layout/        ← Header, PageWrapper (transversal)
│   └── features/      ← One subfolder per feature
└── lib/
    ├── api.ts         ← All FastAPI calls
    ├── supabase.ts    ← Auth-only Supabase client
    └── utils.ts       ← cn() helper
```
```

**File: `docs/API.md`**

```markdown
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

> Extend this file every time a new endpoint is added. Keep it as the single source of truth for the API contract.
```

---

## 14. AGENTS.md

**File: `AGENTS.md`**

```markdown
# Agents

| Agent            | Owns                                                      | Must NOT touch           |
|------------------|-----------------------------------------------------------|--------------------------|
| frontend-builder | frontend/**                                               | backend/, ml/, database/ |
| backend-builder  | main.py, dependencies/, routers/, schemas/                | Inference code in routers |
| bd-builder       | database/supabase/**, routers/db.py, services/database.py | ml/**, frontend/**       |
| ml-ops           | ml/**                                                     | database/, frontend/     |
| test-guard       | tests/**, tools/validate.sh                               | Feature code             |

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
```

---

## 15. .gitignore

**File: `.gitignore`**

```
# Dependencies
node_modules/
.next/
__pycache__/
*.pyc
.venv/
venv/

# Environment
.env
.env.local
.env.production

# Models — large files, never commit
ml/models/
*.gguf
*.bin
*.safetensors

# Build
dist/
build/
*.egg-info/

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/

# ngrok
*.ngrok-free.app
```

---

## Execution checklist for Claude Code

Run these steps in order after scaffold generation:

1. Create all folders and files above.
2. Frontend: `cd frontend && npm install && npx shadcn-ui@latest init`
3. Backend: `cd backend && pip install -r requirements.txt`
4. Verify backend starts: `cd backend && uvicorn app.main:app --reload`
5. Verify `GET /health` → `{"status": "ok"}`
6. Run `bash tools/validate.sh` — contract tests should pass (401 on auth endpoints is expected)
7. Confirm folder structure matches `docs/ARCHITECTURE.md`
8. Define domain tables in `database/supabase/schema.sql` before writing any feature code.
