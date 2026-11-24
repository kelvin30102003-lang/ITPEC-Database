# Development guide

1. Install dependencies with `npm install` and copy `.env.example` to `.env.local`.
2. Run `npm run dev` to start Next.js.
3. Add a route in `src/app` and keep its business behavior in an appropriate feature module.
4. Validate user input with reusable Zod schemas; keep forms accessible and keyboard-operable.
5. Use Server Components by default. Add client boundaries only around interactive controls.
6. Run `npm run typecheck`, `npm run lint`, and `npm run build` before handing off a change.

Avoid duplicating Supabase client creation, validation rules, or translation strings. Keep original ITPEC question language intact.
