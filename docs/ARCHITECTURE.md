# Architecture

## Overview

```
Browser → Next.js (Vercel) → FastAPI (ngrok) → llama.cpp (local GPU)
                                   ↕
                              Supabase (Postgres + Auth)
```

## Layer responsibilities

| Layer      | Responsibility                                           |
|------------|----------------------------------------------------------|
| frontend/  | UI, Auth via Supabase, proxy ML + DB calls to API_URL    |
| backend/   | HTTP routing, JWT validation, thin delegation            |
| ml/        | All LLM and predictive model logic                       |
| database/  | Schema, migrations, RLS policies                         |

## API prefixes

| Prefix      | Implemented by                                       |
|-------------|------------------------------------------------------|
| /api/ml/*   | ml/services/ via backend/app/routers/ml.py           |
| /api/db/*   | backend/app/services/database.py via routers/db.py   |
| /health     | backend/app/main.py                                  |

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

## Database — key tables

| Table               | Purpose                                          |
|---------------------|--------------------------------------------------|
| profiles            | Extends auth.users — role, locale, timezone      |
| pets                | Core pet profile — species, breed, weight        |
| pet_members         | User ↔ pet access control (basis for all RLS)    |
| menu_items          | Dynamic navigation — role-aware, self-referential|
| vet_visits          | Visit records with weight/temp snapshots         |
| diagnoses           | Linked to visits; status lifecycle               |
| treatments          | Medications and therapies per diagnosis          |
| allergies           | Confirmed/suspected allergens                    |
| vaccinations        | Vaccine records with next_due_date               |
| lab_tests           | Test session (blood/urine/feces/imaging)         |
| lab_results         | Individual parameters with reference ranges      |
| diet_entries        | Current and historical diet entries              |
| lab_interpretations | LLM plain-language summary per lab test          |
| diet_analyses       | LLM diet analysis per pet                        |
| insurance_policies  | Policies with renewal date tracking              |
| attachments         | Polymorphic file storage (Supabase Storage)      |
| reminders           | Scheduled alerts — multi-channel                 |
| notifications       | In-app inbox                                     |
