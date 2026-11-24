# ITPEC Hub

ITPEC Hub is a bilingual Myanmar and English learning platform foundation for ITPEC exam preparation. The project is structured for incremental feature development; the current routes and pages are architectural scaffolding, not complete learning features.

## Technology

Next.js App Router, React, TypeScript, Tailwind CSS, shadcn/ui-compatible primitives, Lucide React, Supabase PostgreSQL/Auth/Storage, React Hook Form, Zod, Zustand, TanStack Query, Recharts, React Markdown, and KaTeX.

## Requirements

- Node.js compatible with the installed Next.js version (Node.js 20.9 or later)
- npm
- A Supabase project for database and authentication features

## Install and run

```bash
npm install
Copy-Item .env.example .env.local # PowerShell; use cp on macOS/Linux
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

## Environment setup

Set `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` in `.env.local`. These are the project URL and publishable key from Supabase. Never use a `service_role` or secret key in client code or a `NEXT_PUBLIC_` variable.

## Commands

```bash
npm run dev       # Local development
npm run typecheck # TypeScript check
npm run lint      # ESLint
npm run build     # Production build
npm run start     # Serve a production build
```

## Supabase setup

Create a Supabase project, copy the project URL and publishable key into `.env.local`, and configure the allowed redirect URLs in Supabase Auth for local and deployed environments. The app uses `@supabase/ssr`: browser and server clients are in `src/lib/supabase`, and Next.js 16 session refresh is handled by `src/proxy.ts`. Database types in `src/types/database.ts` are a starter and should be generated from the actual schema before querying application tables.

The initial SQL schema is in `supabase/migrations/`. Install and link the Supabase CLI to the intended project before running `supabase db push --remote`; inspect the project first because the migration deliberately aborts if any of its table names already exist. Set `SUPABASE_SECRET_KEY` only for trusted server-side grading and protected content management. The `createAdminClient()` helper is server-only; it also accepts the legacy `SUPABASE_SERVICE_ROLE_KEY` name. Never place either value in a `NEXT_PUBLIC_` variable. See `docs/database.md` for RLS, answer-key, grading, storage, and type-generation details. Promote the first administrator through a trusted database operator after the user profile is created.

## Documentation

See `docs/architecture.md`, `docs/project-structure.md`, `docs/development-guide.md`, `docs/internationalization.md`, and `docs/database.md`.
