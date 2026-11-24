# Architecture

The application uses the Next.js App Router and a feature-based organization beneath `src`. Route files in `src/app` own URL composition, layouts, metadata, and request boundaries. Feature modules own domain behavior. Shared UI belongs in `src/components`; cross-cutting infrastructure belongs in `src/lib`.

## Rendering and state

Pages and layouts are Server Components by default. Add `"use client"` only for browser APIs, local interaction, or client state. TanStack Query is available for client-side server state; Zustand should be introduced only for genuinely shared client state. React Hook Form and Zod are the form and validation standard.

## Supabase

Use the browser client only in Client Components and the server client in Server Components, Server Actions, and Route Handlers. Both use the public publishable key and typed `Database` shape. Never place a service role key in a public environment variable. `src/proxy.ts` refreshes auth cookies using `getClaims()` under the Next.js 16 proxy convention. Authorization must still be enforced in server-side handlers and database RLS policies.

## Route groups

Route groups `(marketing)` and `(auth)` organize pages without changing their URLs. Student and admin layouts use their own URL prefixes. Dynamic knowledge and exam URLs use `[category]`, `[slug]`, and `[attemptId]` segments.
