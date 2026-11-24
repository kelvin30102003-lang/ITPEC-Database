# Feature modules

Feature code lives by capability. Keep feature components, hooks, services, types, and validation schemas together inside the relevant feature. Add a subfolder only when that feature gains code for that concern. Routes compose feature exports; they should not hold business rules. Shared infrastructure and UI remain in `src/lib` and `src/components`.

Planned modules: `auth`, `dashboard`, `question-bank`, `practice`, `examination`, `knowledge-base`, `bookmarks`, `analytics`, and `donations`.
