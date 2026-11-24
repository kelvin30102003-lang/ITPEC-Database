# Project structure

```text
src/
  app/                 App Router pages, layouts, route handlers, errors
  components/          Shared layout, UI, and content cards
  config/              App, navigation, and theme configuration
  features/            auth, dashboard, question-bank, practice, examination,
                       knowledge-base, bookmarks, analytics, donations
  hooks/               Hooks reused across features
  lib/                 Supabase, i18n, and shared utilities
  types/               Shared TypeScript and database types
supabase/
  migrations/          SQL schema changes
  seed.sql             Local development seed data
docs/                  Architecture and contributor guidance
```

Add feature-specific `components`, `hooks`, `services`, `types`, and `validations` folders only as the feature needs them. This avoids empty scaffolding and keeps domain code close to its owner.
