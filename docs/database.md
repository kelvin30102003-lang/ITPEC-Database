# Database and Supabase

The app uses Supabase PostgreSQL, Auth, and Storage through `@supabase/ssr` and `@supabase/supabase-js`. Configure `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` locally. The initial schema is in `supabase/migrations/20261125022148_itpec_hub_initial_schema.sql`.

The migration adds profiles, exam configuration, questions/options/answer keys, exams/attempts, practice, bookmarks/reports, knowledge articles, donations, announcements, and admin audit logs. It does not create or change the existing `todos` table. A preflight check aborts if any of the new table names already exist so existing schemas are not overwritten.

All application tables enable RLS. Published catalog content is readable by visitors; user-owned attempts, practice data, bookmarks, reports, and donations are scoped to the signed-in owner. Profiles are bootstrapped from Auth with the `student` role; an administrator must be promoted manually by a trusted database operator. User-facing grants cannot update profile role or attempt/practice scoring fields.

`question_answer_keys` has RLS enabled and no grants or policies for `anon` or `authenticated`. Question explanations are also withheld from browser roles, and question search vectors include only visible question text. The private grading and practice-completion functions are exposed through invoker-only `public` RPC wrappers granted only to `service_role`; they grade a submitted/expired attempt or complete an in-progress session without returning answer keys. Call these RPCs only with `createAdminClient()` from trusted server code after checking the user is allowed to submit that attempt/session. `SUPABASE_SECRET_KEY` is server-only (legacy `SUPABASE_SERVICE_ROLE_KEY` is accepted as fallback); never use either in a browser bundle. Student answer-row grants omit `is_correct` and `marks_awarded`.

Trusted server call shape (perform the user's ownership check before this call):

```ts
const supabase = createAdminClient();
const { error } = await supabase.rpc("grade_exam_attempt", { p_attempt_id: attemptId });
```

Donation proofs use a private `donation-proofs` Storage bucket with per-user folder access and administrator review access. The migration forces that bucket to remain private. Do not expose proof object paths through public pages or create public signed URLs.

English and Myanmar search use PostgreSQL `simple` text vectors (no English stemming) and GIN indexes. Trigram indexes support partial matching; Myanmar text segmentation is application/corpus dependent, so validate ranking and matching against real Myanmar content before launch. Main composite indexes cover question exam/subject/topic filters, per-user attempt history/status, and article category/status. Unique constraints already provide indexes for their corresponding lookups, so duplicate single-column indexes are omitted where a unique index has the needed leading columns.

The database does not bootstrap an administrator from Auth metadata. After a trusted operator verifies the intended account, promote its profile with a SQL Editor command such as `update public.profiles set role = 'admin' where id = '<verified-auth-user-uuid>';`. Never expose an admin-promotion endpoint to ordinary users.

Apply reviewed migrations with the Supabase CLI (`supabase db push --remote`) after linking the intended project. This migration has not been applied to a remote project. Then generate exact app types with `supabase gen types typescript --remote --schema public > src/types/database.ts`, review the generated diff, and update the existing `todos` type if that table remains in use. The `--remote` flag matters with current CLI releases because database commands target the local stack by default. Do not expose a service role key to browser code.
