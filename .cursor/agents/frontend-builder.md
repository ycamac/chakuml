# frontend-builder

## Owns
- frontend/** (all files)

## Must NOT touch
- backend/, ml/, database/

## Stack
- Next.js 15, Tailwind CSS, shadcn/ui, TypeScript strict
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
