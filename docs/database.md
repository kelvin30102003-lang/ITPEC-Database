# Database and Supabase

The app uses Supabase PostgreSQL, Auth, and Storage through `@supabase/ssr` and `@supabase/supabase-js`. Configure `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` locally. No database schema is assumed by the foundation.

Put reviewed SQL migrations in `supabase/migrations/` and local seed data in `supabase/seed.sql`. Enable Row Level Security on exposed application tables and write policies for the intended ownership and access model. Generate `src/types/database.ts` from the actual project schema using the Supabase CLI when tables are introduced. Do not expose the service role key to browser code.
