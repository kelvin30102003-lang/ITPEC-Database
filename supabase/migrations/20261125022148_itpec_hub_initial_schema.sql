-- ITPEC Hub initial schema.
-- This migration intentionally does not create or alter the existing `todos` table.

create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;
create extension if not exists pg_trgm with schema extensions;

-- Abort instead of colliding with pre-existing user tables; reconcile them in a separate migration first.
do $$
declare
  existing_tables text[];
  existing_storage_policies text[];
begin
  select array_agg(c.relname order by c.relname) into existing_tables
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relkind in ('r', 'p')
    and c.relname = any (array[
      'profiles', 'exam_types', 'subjects', 'topics', 'questions', 'question_options',
      'question_answer_keys', 'exams', 'exam_sections', 'exam_questions', 'exam_attempts',
      'attempt_answers', 'practice_sessions', 'practice_session_questions', 'bookmarks',
      'question_reports', 'knowledge_categories', 'knowledge_articles', 'article_tags',
      'article_questions', 'donations', 'announcements', 'admin_logs'
    ]);
  if existing_tables is not null then
    raise exception 'ITPEC Hub migration stopped: public tables already exist: %. Reconcile them before applying this migration.', existing_tables;
  end if;

  select array_agg(policyname order by policyname) into existing_storage_policies
  from pg_policies
  where schemaname = 'storage' and tablename = 'objects'
    and policyname = any (array[
      'donation_proofs_upload_own', 'donation_proofs_read_own_or_admin',
      'donation_proofs_update_own_or_admin', 'donation_proofs_delete_own_or_admin'
    ]);
  if existing_storage_policies is not null then
    raise exception 'ITPEC Hub migration stopped: donation-proof storage policies already exist: %. Reconcile them before applying this migration.', existing_storage_policies;
  end if;
end;
$$;

create schema if not exists itpec_private;
revoke all on schema itpec_private from public, anon, authenticated;
grant usage on schema itpec_private to authenticated, service_role;

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text,
  full_name text,
  avatar_url text,
  role text not null default 'student' check (role in ('student', 'admin')),
  preferred_language text not null default 'en' check (preferred_language in ('my', 'en')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_username_format check (username is null or username ~ '^[A-Za-z0-9_]{3,32}$'),
  constraint profiles_full_name_length check (full_name is null or length(full_name) <= 160)
);

create unique index profiles_username_lower_uidx on public.profiles (lower(username)) where username is not null;

create table public.exam_types (
  id uuid primary key default gen_random_uuid(),
  code text not null unique check (code in ('IP', 'FE')),
  name_en text not null,
  name_my text not null,
  description_en text,
  description_my text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.subjects (
  id uuid primary key default gen_random_uuid(),
  exam_type_id uuid references public.exam_types (id) on delete restrict,
  name_en text not null,
  name_my text not null,
  slug text not null unique check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  description_en text,
  description_my text,
  display_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.topics (
  id uuid primary key default gen_random_uuid(),
  subject_id uuid not null references public.subjects (id) on delete cascade,
  parent_id uuid,
  name_en text not null,
  name_my text not null,
  slug text not null check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  description_en text,
  description_my text,
  display_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint topics_id_subject_unique unique (id, subject_id),
  constraint topics_parent_same_subject_fk foreign key (parent_id, subject_id)
    references public.topics (id, subject_id) on delete cascade,
  constraint topics_not_own_parent check (parent_id is distinct from id),
  constraint topics_slug_per_subject_unique unique (subject_id, slug)
);

create table public.questions (
  id uuid primary key default gen_random_uuid(),
  exam_type_id uuid not null references public.exam_types (id) on delete restrict,
  subject_id uuid not null references public.subjects (id) on delete restrict,
  topic_id uuid,
  question_code text unique,
  question_text_en text not null,
  question_text_my text,
  question_type text not null check (question_type in ('single_choice', 'multiple_choice')),
  difficulty text not null default 'medium' check (difficulty in ('easy', 'medium', 'hard')),
  explanation_en text,
  explanation_my text,
  source_year integer check (source_year is null or source_year between 1900 and 2200),
  source_session text,
  source_reference text,
  copyright_status text not null default 'unknown'
    check (copyright_status in ('unknown', 'original', 'licensed', 'public_domain', 'permission_required', 'restricted')),
  status text not null default 'draft' check (status in ('draft', 'published', 'archived')),
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  search_vector_en tsvector generated always as (
    to_tsvector('simple'::regconfig, coalesce(question_text_en, ''))
  ) stored,
  search_vector_my tsvector generated always as (
    to_tsvector('simple'::regconfig, coalesce(question_text_my, ''))
  ) stored,
  constraint questions_topic_subject_fk foreign key (topic_id, subject_id)
    references public.topics (id, subject_id) on delete set null (topic_id)
);

create table public.question_options (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null references public.questions (id) on delete cascade,
  option_label text not null check (length(btrim(option_label)) between 1 and 12),
  option_text_en text not null,
  option_text_my text,
  display_order integer not null default 0,
  created_at timestamptz not null default now(),
  constraint question_options_label_unique unique (question_id, option_label)
);

create table public.question_answer_keys (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null unique references public.questions (id) on delete cascade,
  correct_option_ids uuid[] not null check (
    cardinality(correct_option_ids) > 0 and array_position(correct_option_ids, null::uuid) is null
  ),
  explanation_en text,
  explanation_my text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.exams (
  id uuid primary key default gen_random_uuid(),
  exam_type_id uuid not null references public.exam_types (id) on delete restrict,
  title_en text not null,
  title_my text not null,
  description_en text,
  description_my text,
  exam_mode text not null default 'full' check (exam_mode in ('full', 'custom', 'random')),
  duration_minutes integer not null check (duration_minutes > 0),
  total_questions integer not null default 0 check (total_questions >= 0),
  total_marks numeric(8,2) not null default 0 check (total_marks >= 0),
  passing_marks numeric(8,2) not null default 0 check (passing_marks >= 0 and passing_marks <= total_marks),
  is_published boolean not null default false,
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.exam_sections (
  id uuid primary key default gen_random_uuid(),
  exam_id uuid not null references public.exams (id) on delete cascade,
  title_en text not null,
  title_my text not null,
  duration_minutes integer check (duration_minutes is null or duration_minutes > 0),
  question_count integer not null default 0 check (question_count >= 0),
  display_order integer not null default 0,
  created_at timestamptz not null default now(),
  constraint exam_sections_id_exam_unique unique (id, exam_id),
  constraint exam_sections_order_unique unique (exam_id, display_order)
);

create table public.exam_questions (
  id uuid primary key default gen_random_uuid(),
  exam_id uuid not null references public.exams (id) on delete cascade,
  section_id uuid,
  question_id uuid not null references public.questions (id) on delete restrict,
  marks numeric(8,2) not null default 1 check (marks > 0),
  display_order integer not null default 0,
  created_at timestamptz not null default now(),
  constraint exam_questions_section_exam_fk foreign key (section_id, exam_id)
    references public.exam_sections (id, exam_id) on delete cascade,
  constraint exam_questions_unique_question unique (exam_id, question_id),
  constraint exam_questions_order_unique unique nulls not distinct (exam_id, section_id, display_order)
);

create table public.exam_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  exam_id uuid not null references public.exams (id) on delete restrict,
  status text not null default 'in_progress' check (status in ('in_progress', 'submitted', 'expired')),
  started_at timestamptz not null default now(),
  submitted_at timestamptz,
  time_spent_seconds integer check (time_spent_seconds is null or time_spent_seconds >= 0),
  total_score numeric(8,2) check (total_score is null or total_score >= 0),
  max_score numeric(8,2) check (max_score is null or max_score >= 0),
  correct_count integer check (correct_count is null or correct_count >= 0),
  incorrect_count integer check (incorrect_count is null or incorrect_count >= 0),
  unanswered_count integer check (unanswered_count is null or unanswered_count >= 0),
  created_at timestamptz not null default now(),
  constraint exam_attempts_submission_state check (
    (status = 'in_progress' and submitted_at is null) or
    (status in ('submitted', 'expired') and submitted_at is not null)
  )
);

create table public.attempt_answers (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null,
  question_id uuid not null,
  selected_option_ids uuid[] not null default '{}'::uuid[]
    check (cardinality(selected_option_ids) <= 20 and array_position(selected_option_ids, null::uuid) is null),
  is_correct boolean,
  marks_awarded numeric(8,2) not null default 0 check (marks_awarded >= 0),
  answered_at timestamptz,
  is_marked_for_review boolean not null default false,
  created_at timestamptz not null default now(),
  constraint attempt_answers_attempt_fk foreign key (attempt_id) references public.exam_attempts (id) on delete cascade,
  constraint attempt_answers_question_fk foreign key (question_id) references public.questions (id) on delete restrict,
  constraint attempt_answers_unique unique (attempt_id, question_id)
);

create table public.practice_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  exam_type_id uuid not null references public.exam_types (id) on delete restrict,
  subject_id uuid references public.subjects (id) on delete set null,
  topic_id uuid references public.topics (id) on delete set null,
  question_count integer not null check (question_count > 0),
  practice_mode text not null default 'study' check (practice_mode in ('study', 'exam')),
  status text not null default 'in_progress' check (status in ('in_progress', 'completed', 'abandoned')),
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  correct_count integer not null default 0 check (correct_count >= 0),
  total_score numeric(8,2) not null default 0 check (total_score >= 0),
  created_at timestamptz not null default now(),
  constraint practice_sessions_scope_check check (topic_id is null or subject_id is not null),
  constraint practice_sessions_completion_check check (
    (status = 'in_progress' and completed_at is null) or
    (status <> 'in_progress' and completed_at is not null)
  )
);

create table public.practice_session_questions (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.practice_sessions (id) on delete cascade,
  question_id uuid not null references public.questions (id) on delete restrict,
  display_order integer not null,
  selected_option_ids uuid[] not null default '{}'::uuid[]
    check (cardinality(selected_option_ids) <= 20 and array_position(selected_option_ids, null::uuid) is null),
  is_correct boolean,
  marks_awarded numeric(8,2) not null default 0 check (marks_awarded >= 0),
  answered_at timestamptz,
  created_at timestamptz not null default now(),
  constraint practice_session_questions_unique unique (session_id, question_id),
  constraint practice_session_questions_order_unique unique (session_id, display_order)
);

create table public.bookmarks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  question_id uuid not null references public.questions (id) on delete cascade,
  created_at timestamptz not null default now(),
  constraint bookmarks_user_question_unique unique (user_id, question_id)
);

create table public.question_reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  question_id uuid not null references public.questions (id) on delete cascade,
  report_type text not null check (report_type in ('incorrect_answer', 'unclear', 'typo', 'formatting', 'other')),
  description text not null check (length(btrim(description)) between 1 and 5000),
  status text not null default 'open' check (status in ('open', 'reviewing', 'resolved', 'dismissed')),
  created_at timestamptz not null default now(),
  reviewed_at timestamptz
);

create table public.knowledge_categories (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid references public.knowledge_categories (id) on delete set null,
  name_en text not null,
  name_my text not null,
  slug text not null unique check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  description_en text,
  description_my text,
  icon text,
  display_order integer not null default 0,
  is_published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint knowledge_categories_not_own_parent check (parent_id is distinct from id)
);

create table public.knowledge_articles (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.knowledge_categories (id) on delete restrict,
  title_en text not null,
  title_my text not null,
  slug text not null unique check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  summary_en text,
  summary_my text,
  content_en text not null default '',
  content_my text not null default '',
  cover_image text,
  difficulty text not null default 'medium' check (difficulty in ('easy', 'medium', 'hard')),
  reading_time_minutes integer not null default 1 check (reading_time_minutes > 0),
  status text not null default 'draft' check (status in ('draft', 'published', 'archived')),
  created_by uuid references public.profiles (id) on delete set null,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  search_vector_en tsvector generated always as (
    to_tsvector('simple'::regconfig, coalesce(title_en, '') || ' ' || coalesce(summary_en, '') || ' ' || coalesce(content_en, ''))
  ) stored,
  search_vector_my tsvector generated always as (
    to_tsvector('simple'::regconfig, coalesce(title_my, '') || ' ' || coalesce(summary_my, '') || ' ' || coalesce(content_my, ''))
  ) stored
);

create table public.article_tags (
  id uuid primary key default gen_random_uuid(),
  article_id uuid not null references public.knowledge_articles (id) on delete cascade,
  tag_name text not null check (length(btrim(tag_name)) between 1 and 80),
  created_at timestamptz not null default now()
);

create unique index article_tags_article_name_uidx on public.article_tags (article_id, lower(tag_name));

create table public.article_questions (
  id uuid primary key default gen_random_uuid(),
  article_id uuid not null references public.knowledge_articles (id) on delete cascade,
  question_id uuid not null references public.questions (id) on delete cascade,
  display_order integer not null default 0,
  created_at timestamptz not null default now(),
  constraint article_questions_unique unique (article_id, question_id)
);

create table public.donations (
  id uuid primary key default gen_random_uuid(),
  donor_user_id uuid references public.profiles (id) on delete set null,
  donor_name text,
  amount numeric(12,2) not null check (amount > 0),
  currency text not null default 'MMK' check (currency = 'MMK'),
  donation_type text not null check (donation_type in ('coffee', 'burger', 'mohinga', 'ohn_no_khauk_swe', 'custom')),
  payment_method text not null check (payment_method in ('bank_transfer', 'mobile_wallet', 'other')),
  transaction_reference text,
  payment_proof_path text,
  message text check (message is null or length(message) <= 2000),
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  is_anonymous boolean not null default false,
  verified_by uuid references public.profiles (id) on delete set null,
  verified_at timestamptz,
  created_at timestamptz not null default now(),
  constraint donations_verification_state check (
    (status = 'pending' and verified_at is null and verified_by is null) or
    (status in ('approved', 'rejected') and verified_at is not null and verified_by is not null)
  ),
  constraint donations_proof_path_owner check (
    payment_proof_path is null or donor_user_id is null or split_part(payment_proof_path, '/', 1) = donor_user_id::text
  )
);

create table public.announcements (
  id uuid primary key default gen_random_uuid(),
  title_en text not null,
  title_my text not null,
  content_en text not null,
  content_my text not null,
  is_published boolean not null default false,
  created_by uuid references public.profiles (id) on delete set null,
  published_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.admin_logs (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid not null references public.profiles (id) on delete restrict,
  action text not null check (length(btrim(action)) between 1 and 120),
  entity_type text not null check (length(btrim(entity_type)) between 1 and 120),
  entity_id uuid,
  details jsonb not null default '{}'::jsonb check (jsonb_typeof(details) = 'object'),
  created_at timestamptz not null default now()
);

-- Timestamp and auth-profile helpers.
create function itpec_private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create function itpec_private.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.role = 'admin'
  );
$$;

create function itpec_private.create_profile_for_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name)
  values (
    new.id,
    left(nullif(btrim(new.raw_user_meta_data ->> 'full_name'), ''), 160)
  );
  return new;
end;
$$;

revoke all on function itpec_private.set_updated_at() from public, anon, authenticated, service_role;
revoke all on function itpec_private.is_admin() from public, anon, authenticated, service_role;
revoke all on function itpec_private.create_profile_for_auth_user() from public, anon, authenticated, service_role;
grant execute on function itpec_private.is_admin() to authenticated, service_role;

create trigger auth_user_created_profile
  after insert on auth.users
  for each row execute function itpec_private.create_profile_for_auth_user();

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'profiles', 'exam_types', 'subjects', 'topics', 'questions', 'question_answer_keys',
    'exams', 'knowledge_categories', 'knowledge_articles'
  ] loop
    execute format(
      'create trigger %I_set_updated_at before update on public.%I for each row execute function itpec_private.set_updated_at()',
      table_name, table_name
    );
  end loop;
end;
$$;

-- Validate that stored answer IDs belong to the referenced question.
create function itpec_private.validate_question_answer_key()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  v_question_type text;
  v_option_count integer;
begin
  select q.question_type into v_question_type
  from public.questions q where q.id = new.question_id;
  if v_question_type is null then
    raise exception 'Question % does not exist', new.question_id using errcode = '23503';
  end if;

  select count(*) into v_option_count
  from unnest(new.correct_option_ids) selected(option_id)
  where exists (
    select 1 from public.question_options qo
    where qo.id = selected.option_id and qo.question_id = new.question_id
  );
  if v_option_count <> cardinality(new.correct_option_ids) then
    raise exception 'Every correct option must belong to the answer key question' using errcode = '23514';
  end if;
  if v_question_type = 'single_choice' and cardinality(new.correct_option_ids) <> 1 then
    raise exception 'A single-choice question must have exactly one correct option' using errcode = '23514';
  end if;
  if cardinality(new.correct_option_ids) <> (select count(distinct option_id) from unnest(new.correct_option_ids) ids(option_id)) then
    raise exception 'Correct option IDs must be unique' using errcode = '23514';
  end if;
  return new;
end;
$$;

create trigger question_answer_key_options_valid
  before insert or update of question_id, correct_option_ids on public.question_answer_keys
  for each row execute function itpec_private.validate_question_answer_key();

create function itpec_private.validate_selected_options()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  v_question_type text;
  v_option_count integer;
begin
  select q.question_type into v_question_type
  from public.questions q where q.id = new.question_id;
  if v_question_type is null then
    raise exception 'Question % does not exist', new.question_id using errcode = '23503';
  end if;
  if v_question_type = 'single_choice' and cardinality(new.selected_option_ids) > 1 then
    raise exception 'A single-choice question accepts at most one selected option' using errcode = '23514';
  end if;

  select count(*) into v_option_count
  from unnest(new.selected_option_ids) selected(option_id)
  where exists (
    select 1 from public.question_options qo
    where qo.id = selected.option_id and qo.question_id = new.question_id
  );
  if v_option_count <> cardinality(new.selected_option_ids) then
    raise exception 'Every selected option must belong to the answered question' using errcode = '23514';
  end if;
  if cardinality(new.selected_option_ids) <> (select count(distinct option_id) from unnest(new.selected_option_ids) ids(option_id)) then
    raise exception 'Selected option IDs must be unique' using errcode = '23514';
  end if;

  if tg_table_name = 'attempt_answers' and not exists (
    select 1 from public.exam_attempts a
    join public.exam_questions eq on eq.exam_id = a.exam_id and eq.question_id = new.question_id
    where a.id = new.attempt_id and a.status = 'in_progress'
  ) then
    raise exception 'Question is not part of an in-progress attempt' using errcode = '23514';
  end if;
  if tg_table_name = 'practice_session_questions' and not exists (
    select 1 from public.practice_sessions s
    join public.questions q on q.id = new.question_id
    where s.id = new.session_id and s.status = 'in_progress'
      and q.status = 'published'
      and q.exam_type_id = s.exam_type_id
      and (s.subject_id is null or q.subject_id = s.subject_id)
      and (s.topic_id is null or q.topic_id = s.topic_id)
  ) then
    raise exception 'Question can only be changed in an in-progress practice session' using errcode = '23514';
  end if;
  return new;
end;
$$;

create function itpec_private.validate_question_exam_type()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.subjects s
    where s.id = new.subject_id and (s.exam_type_id is null or s.exam_type_id = new.exam_type_id)
  ) then
    raise exception 'Question exam type must match its subject, unless that subject is shared' using errcode = '23514';
  end if;
  return new;
end;
$$;

create trigger questions_exam_type_valid
  before insert or update of exam_type_id, subject_id on public.questions
  for each row execute function itpec_private.validate_question_exam_type();

create function itpec_private.validate_subject_exam_type_change()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.exam_type_id is not null and exists (
    select 1 from public.questions q
    where q.subject_id = new.id and q.exam_type_id <> new.exam_type_id
  ) then
    raise exception 'Subject exam type cannot conflict with questions already assigned to it' using errcode = '23514';
  end if;
  return new;
end;
$$;

create trigger subjects_exam_type_consistent
  before update of exam_type_id on public.subjects
  for each row execute function itpec_private.validate_subject_exam_type_change();

create function itpec_private.validate_exam_question_type()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if not exists (
    select 1
    from public.exams e
    join public.questions q on q.id = new.question_id
    where e.id = new.exam_id and e.exam_type_id = q.exam_type_id
  ) then
    raise exception 'Exam and question must use the same exam type' using errcode = '23514';
  end if;
  return new;
end;
$$;

create trigger exam_questions_exam_type_valid
  before insert or update of exam_id, question_id on public.exam_questions
  for each row execute function itpec_private.validate_exam_question_type();

create function itpec_private.validate_exam_exam_type_change()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if exists (
    select 1 from public.exam_questions eq
    join public.questions q on q.id = eq.question_id
    where eq.exam_id = new.id and q.exam_type_id <> new.exam_type_id
  ) then
    raise exception 'Exam type cannot conflict with questions already assigned to the exam' using errcode = '23514';
  end if;
  return new;
end;
$$;

create trigger exams_exam_type_consistent
  before update of exam_type_id on public.exams
  for each row execute function itpec_private.validate_exam_exam_type_change();

create trigger attempt_answers_options_valid
  before insert or update of question_id, selected_option_ids on public.attempt_answers
  for each row execute function itpec_private.validate_selected_options();
create trigger practice_answers_options_valid
  before insert or update of question_id, selected_option_ids on public.practice_session_questions
  for each row execute function itpec_private.validate_selected_options();

-- This function reveals no answer key and can only be invoked with the server-only service role.
create function itpec_private.grade_exam_attempt(p_attempt_id uuid)
returns void
language plpgsql
set search_path = ''
as $$
declare
  v_exam_id uuid;
  v_status text;
begin
  if current_user <> 'service_role' then
    raise exception 'Only trusted server-side grading may execute this function' using errcode = '42501';
  end if;

  select a.exam_id, a.status into v_exam_id, v_status
  from public.exam_attempts a where a.id = p_attempt_id for update;
  if v_exam_id is null then
    raise exception 'Attempt not found' using errcode = 'P0002';
  end if;
  if v_status not in ('submitted', 'expired') then
    raise exception 'Only submitted or expired attempts can be graded' using errcode = '23514';
  end if;
  if exists (
    select 1 from public.exam_questions eq
    left join public.question_answer_keys ak on ak.question_id = eq.question_id
    where eq.exam_id = v_exam_id and ak.id is null
  ) then
    raise exception 'Every question in the exam must have a protected answer key before grading' using errcode = '23514';
  end if;

  update public.attempt_answers aa
  set is_correct = (
        select array_agg(answer_id order by answer_id)
        from unnest(aa.selected_option_ids) selected(answer_id)
      ) is not distinct from (
        select array_agg(answer_id order by answer_id)
        from unnest(ak.correct_option_ids) correct(answer_id)
      ),
      marks_awarded = case when (
        select array_agg(answer_id order by answer_id)
        from unnest(aa.selected_option_ids) selected(answer_id)
      ) is not distinct from (
        select array_agg(answer_id order by answer_id)
        from unnest(ak.correct_option_ids) correct(answer_id)
      ) then eq.marks else 0 end
  from public.exam_questions eq
  join public.question_answer_keys ak on ak.question_id = eq.question_id
  where aa.attempt_id = p_attempt_id and eq.exam_id = v_exam_id and eq.question_id = aa.question_id;

  update public.exam_attempts a
  set total_score = stats.total_score,
      max_score = stats.max_score,
      correct_count = stats.correct_count,
      incorrect_count = stats.incorrect_count,
      unanswered_count = stats.unanswered_count,
      time_spent_seconds = coalesce(a.time_spent_seconds, greatest(0, floor(extract(epoch from (a.submitted_at - a.started_at)))::integer))
  from (
    select coalesce(sum(coalesce(aa.marks_awarded, 0)), 0)::numeric(8,2) as total_score,
           coalesce(sum(eq.marks), 0)::numeric(8,2) as max_score,
           count(*) filter (where aa.is_correct is true)::integer as correct_count,
           count(*) filter (where aa.is_correct is false)::integer as incorrect_count,
           count(*) filter (where aa.id is null)::integer as unanswered_count
    from public.exam_questions eq
    left join public.attempt_answers aa on aa.attempt_id = p_attempt_id and aa.question_id = eq.question_id
    where eq.exam_id = v_exam_id
  ) stats
  where a.id = p_attempt_id;
end;
$$;

create function itpec_private.complete_practice_session(p_session_id uuid)
returns void
language plpgsql
set search_path = ''
as $$
declare
  v_status text;
begin
  if current_user <> 'service_role' then
    raise exception 'Only trusted server-side grading may execute this function' using errcode = '42501';
  end if;

  select s.status into v_status
  from public.practice_sessions s where s.id = p_session_id for update;
  if v_status is null then
    raise exception 'Practice session not found' using errcode = 'P0002';
  end if;
  if v_status <> 'in_progress' then
    raise exception 'Only an in-progress practice session can be completed' using errcode = '23514';
  end if;
  if exists (
    select 1 from public.practice_session_questions pq
    left join public.question_answer_keys ak on ak.question_id = pq.question_id
    where pq.session_id = p_session_id and ak.id is null
  ) then
    raise exception 'Every practice question must have a protected answer key before completion' using errcode = '23514';
  end if;

  update public.practice_session_questions pq
  set is_correct = (
        select array_agg(answer_id order by answer_id)
        from unnest(pq.selected_option_ids) selected(answer_id)
      ) is not distinct from (
        select array_agg(answer_id order by answer_id)
        from unnest(ak.correct_option_ids) correct(answer_id)
      ),
      marks_awarded = case when (
        select array_agg(answer_id order by answer_id)
        from unnest(pq.selected_option_ids) selected(answer_id)
      ) is not distinct from (
        select array_agg(answer_id order by answer_id)
        from unnest(ak.correct_option_ids) correct(answer_id)
      ) then 1 else 0 end
  from public.question_answer_keys ak
  where pq.session_id = p_session_id and ak.question_id = pq.question_id;

  update public.practice_sessions s
  set status = 'completed',
      completed_at = now(),
      correct_count = stats.correct_count,
      total_score = stats.total_score
  from (
    select count(*) filter (where pq.is_correct is true)::integer as correct_count,
           coalesce(sum(pq.marks_awarded), 0)::numeric(8,2) as total_score
    from public.practice_session_questions pq where pq.session_id = p_session_id
  ) stats
  where s.id = p_session_id;
end;
$$;

-- Exposed RPC wrappers are invoker-only and executable by service_role, never by client roles.
create function public.grade_exam_attempt(p_attempt_id uuid)
returns void
language sql
security invoker
set search_path = ''
as $$
  select itpec_private.grade_exam_attempt(p_attempt_id);
$$;

create function public.complete_practice_session(p_session_id uuid)
returns void
language sql
security invoker
set search_path = ''
as $$
  select itpec_private.complete_practice_session(p_session_id);
$$;

revoke all on function itpec_private.validate_question_answer_key() from public, anon, authenticated, service_role;
revoke all on function itpec_private.validate_selected_options() from public, anon, authenticated, service_role;
revoke all on function itpec_private.validate_question_exam_type() from public, anon, authenticated, service_role;
revoke all on function itpec_private.validate_exam_question_type() from public, anon, authenticated, service_role;
revoke all on function itpec_private.validate_subject_exam_type_change() from public, anon, authenticated, service_role;
revoke all on function itpec_private.validate_exam_exam_type_change() from public, anon, authenticated, service_role;
revoke all on function itpec_private.grade_exam_attempt(uuid) from public, anon, authenticated, service_role;
revoke all on function itpec_private.complete_practice_session(uuid) from public, anon, authenticated, service_role;
grant execute on function itpec_private.grade_exam_attempt(uuid) to service_role;
grant execute on function itpec_private.complete_practice_session(uuid) to service_role;
revoke all on function public.grade_exam_attempt(uuid) from public, anon, authenticated, service_role;
revoke all on function public.complete_practice_session(uuid) from public, anon, authenticated, service_role;
grant execute on function public.grade_exam_attempt(uuid) to service_role;
grant execute on function public.complete_practice_session(uuid) to service_role;

-- Foreign-key and common filter indexes. Unique constraints already index their key columns.
create index subjects_exam_type_id_idx on public.subjects (exam_type_id) where exam_type_id is not null;
create index topics_subject_id_idx on public.topics (subject_id);
create index topics_parent_subject_idx on public.topics (parent_id, subject_id) where parent_id is not null;
create index questions_exam_type_subject_topic_idx on public.questions (exam_type_id, subject_id, topic_id);
create index questions_subject_id_idx on public.questions (subject_id);
create index questions_topic_id_idx on public.questions (topic_id) where topic_id is not null;
create index questions_status_difficulty_idx on public.questions (status, difficulty);
create index questions_source_year_exam_type_idx on public.questions (source_year, exam_type_id) where source_year is not null;
create index questions_created_by_idx on public.questions (created_by) where created_by is not null;
create index questions_search_en_idx on public.questions using gin (search_vector_en);
create index questions_search_my_idx on public.questions using gin (search_vector_my);
create index question_options_question_order_idx on public.question_options (question_id, display_order);
create index exams_exam_type_published_idx on public.exams (exam_type_id, is_published);
create index exam_questions_exam_order_idx on public.exam_questions (exam_id, display_order);
create index exam_questions_question_id_idx on public.exam_questions (question_id);
create index exam_questions_section_id_idx on public.exam_questions (section_id) where section_id is not null;
create index exam_attempts_user_created_idx on public.exam_attempts (user_id, created_at desc);
create index exam_attempts_user_status_idx on public.exam_attempts (user_id, status);
create index exam_attempts_exam_id_idx on public.exam_attempts (exam_id);
create index exams_created_by_idx on public.exams (created_by) where created_by is not null;
create index attempt_answers_question_id_idx on public.attempt_answers (question_id);
create index practice_sessions_user_started_idx on public.practice_sessions (user_id, started_at desc);
create index practice_sessions_user_status_idx on public.practice_sessions (user_id, status);
create index practice_sessions_exam_type_idx on public.practice_sessions (exam_type_id);
create index practice_sessions_subject_topic_idx on public.practice_sessions (subject_id, topic_id);
create index practice_sessions_topic_id_idx on public.practice_sessions (topic_id) where topic_id is not null;
create index practice_session_questions_question_id_idx on public.practice_session_questions (question_id);
create index bookmarks_question_id_idx on public.bookmarks (question_id);
create index question_reports_user_created_idx on public.question_reports (user_id, created_at desc);
create index question_reports_status_created_idx on public.question_reports (status, created_at desc);
create index question_reports_question_id_idx on public.question_reports (question_id);
create index knowledge_categories_parent_id_idx on public.knowledge_categories (parent_id) where parent_id is not null;
create index knowledge_articles_category_status_idx on public.knowledge_articles (category_id, status);
create index knowledge_articles_created_by_idx on public.knowledge_articles (created_by) where created_by is not null;
create index knowledge_articles_search_en_idx on public.knowledge_articles using gin (search_vector_en);
create index knowledge_articles_search_my_idx on public.knowledge_articles using gin (search_vector_my);
create index article_tags_article_id_idx on public.article_tags (article_id);
create index article_questions_question_id_idx on public.article_questions (question_id);
create index donations_user_created_idx on public.donations (donor_user_id, created_at desc) where donor_user_id is not null;
create index donations_status_created_idx on public.donations (status, created_at desc);
create index donations_verified_by_idx on public.donations (verified_by) where verified_by is not null;
create index announcements_published_created_idx on public.announcements (created_at desc) where is_published;
create index announcements_created_by_idx on public.announcements (created_by) where created_by is not null;
create index admin_logs_admin_created_idx on public.admin_logs (admin_id, created_at desc);
create index admin_logs_entity_idx on public.admin_logs (entity_type, entity_id, created_at desc);

-- Resolve the installed pg_trgm operator-class schema instead of assuming where it was enabled.
do $$
declare
  trgm_schema text;
begin
  select n.nspname into trgm_schema
  from pg_extension e
  join pg_namespace n on n.oid = e.extnamespace
  where e.extname = 'pg_trgm';

  execute format('create index questions_text_en_trgm_idx on public.questions using gin (question_text_en %I.gin_trgm_ops)', trgm_schema);
  execute format('create index questions_text_my_trgm_idx on public.questions using gin (question_text_my %I.gin_trgm_ops) where question_text_my is not null', trgm_schema);
  execute format('create index knowledge_articles_text_en_trgm_idx on public.knowledge_articles using gin (title_en %I.gin_trgm_ops)', trgm_schema);
  execute format('create index knowledge_articles_text_my_trgm_idx on public.knowledge_articles using gin (title_my %I.gin_trgm_ops)', trgm_schema);
end;
$$;

-- RLS: all application tables are protected. Policies are operation-specific.
alter table public.profiles enable row level security;
alter table public.exam_types enable row level security;
alter table public.subjects enable row level security;
alter table public.topics enable row level security;
alter table public.questions enable row level security;
alter table public.question_options enable row level security;
alter table public.question_answer_keys enable row level security;
alter table public.exams enable row level security;
alter table public.exam_sections enable row level security;
alter table public.exam_questions enable row level security;
alter table public.exam_attempts enable row level security;
alter table public.attempt_answers enable row level security;
alter table public.practice_sessions enable row level security;
alter table public.practice_session_questions enable row level security;
alter table public.bookmarks enable row level security;
alter table public.question_reports enable row level security;
alter table public.knowledge_categories enable row level security;
alter table public.knowledge_articles enable row level security;
alter table public.article_tags enable row level security;
alter table public.article_questions enable row level security;
alter table public.donations enable row level security;
alter table public.announcements enable row level security;
alter table public.admin_logs enable row level security;

create policy profiles_read_self_or_admin on public.profiles for select to authenticated
  using ((select auth.uid()) = id or (select itpec_private.is_admin()));
create policy profiles_update_self on public.profiles for update to authenticated
  using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

create policy exam_types_read_active on public.exam_types for select to anon, authenticated
  using (is_active);
create policy exam_types_admin_all on public.exam_types for all to authenticated
  using ((select itpec_private.is_admin())) with check ((select itpec_private.is_admin()));

create policy subjects_read_active on public.subjects for select to anon, authenticated
  using (is_active and (exam_type_id is null or exists (
    select 1 from public.exam_types et where et.id = exam_type_id and et.is_active
  )));
create policy subjects_admin_all on public.subjects for all to authenticated
  using ((select itpec_private.is_admin())) with check ((select itpec_private.is_admin()));

create policy topics_read_active_subject on public.topics for select to anon, authenticated
  using (exists (select 1 from public.subjects s where s.id = subject_id and s.is_active));
create policy topics_admin_all on public.topics for all to authenticated
  using ((select itpec_private.is_admin())) with check ((select itpec_private.is_admin()));

create policy questions_read_published on public.questions for select to anon, authenticated
  using (status = 'published');
create policy questions_admin_all on public.questions for all to authenticated
  using ((select itpec_private.is_admin())) with check ((select itpec_private.is_admin()));

create policy question_options_read_published on public.question_options for select to anon, authenticated
  using (exists (select 1 from public.questions q where q.id = question_id and q.status = 'published'));
create policy question_options_admin_all on public.question_options for all to authenticated
  using ((select itpec_private.is_admin())) with check ((select itpec_private.is_admin()));
-- Deliberately no client grants or policies for answer keys.

create policy exams_read_published on public.exams for select to anon, authenticated
  using (is_published);
create policy exams_admin_all on public.exams for all to authenticated
  using ((select itpec_private.is_admin())) with check ((select itpec_private.is_admin()));
create policy exam_sections_read_published on public.exam_sections for select to anon, authenticated
  using (exists (select 1 from public.exams e where e.id = exam_id and e.is_published));
create policy exam_sections_admin_all on public.exam_sections for all to authenticated
  using ((select itpec_private.is_admin())) with check ((select itpec_private.is_admin()));
create policy exam_questions_read_published on public.exam_questions for select to anon, authenticated
  using (exists (select 1 from public.exams e where e.id = exam_id and e.is_published));
create policy exam_questions_admin_all on public.exam_questions for all to authenticated
  using ((select itpec_private.is_admin())) with check ((select itpec_private.is_admin()));

create policy exam_attempts_read_self on public.exam_attempts for select to authenticated
  using ((select auth.uid()) = user_id);
create policy exam_attempts_create_self on public.exam_attempts for insert to authenticated
  with check ((select auth.uid()) = user_id and status = 'in_progress' and exists (
    select 1 from public.exams e where e.id = exam_id and e.is_published
  ));
create policy attempt_answers_read_self on public.attempt_answers for select to authenticated
  using (exists (select 1 from public.exam_attempts a where a.id = attempt_id and a.user_id = (select auth.uid())));
create policy attempt_answers_create_self on public.attempt_answers for insert to authenticated
  with check (is_correct is null and marks_awarded = 0 and exists (
    select 1 from public.exam_attempts a where a.id = attempt_id and a.user_id = (select auth.uid()) and a.status = 'in_progress'
  ));
create policy attempt_answers_update_self on public.attempt_answers for update to authenticated
  using (exists (select 1 from public.exam_attempts a where a.id = attempt_id and a.user_id = (select auth.uid()) and a.status = 'in_progress'))
  with check (is_correct is null and marks_awarded = 0 and exists (
    select 1 from public.exam_attempts a where a.id = attempt_id and a.user_id = (select auth.uid()) and a.status = 'in_progress'
  ));

create policy practice_sessions_read_self on public.practice_sessions for select to authenticated
  using ((select auth.uid()) = user_id);
create policy practice_sessions_create_self on public.practice_sessions for insert to authenticated
  with check ((select auth.uid()) = user_id and status = 'in_progress' and exists (
    select 1 from public.exam_types et where et.id = exam_type_id and et.is_active
  ));
create policy practice_questions_read_self on public.practice_session_questions for select to authenticated
  using (exists (select 1 from public.practice_sessions s where s.id = session_id and s.user_id = (select auth.uid())));
create policy practice_questions_create_self on public.practice_session_questions for insert to authenticated
  with check (is_correct is null and marks_awarded = 0 and exists (
    select 1 from public.practice_sessions s where s.id = session_id and s.user_id = (select auth.uid()) and s.status = 'in_progress'
  ) and exists (select 1 from public.questions q where q.id = question_id and q.status = 'published'));
create policy practice_questions_update_self on public.practice_session_questions for update to authenticated
  using (exists (select 1 from public.practice_sessions s where s.id = session_id and s.user_id = (select auth.uid()) and s.status = 'in_progress'))
  with check (is_correct is null and marks_awarded = 0 and exists (
    select 1 from public.practice_sessions s where s.id = session_id and s.user_id = (select auth.uid()) and s.status = 'in_progress'
  ));

create policy bookmarks_read_self on public.bookmarks for select to authenticated using ((select auth.uid()) = user_id);
create policy bookmarks_create_self on public.bookmarks for insert to authenticated
  with check ((select auth.uid()) = user_id and exists (
    select 1 from public.questions q where q.id = question_id and q.status = 'published'
  ));
create policy bookmarks_delete_self on public.bookmarks for delete to authenticated using ((select auth.uid()) = user_id);

create policy question_reports_read_self_or_admin on public.question_reports for select to authenticated
  using ((select auth.uid()) = user_id or (select itpec_private.is_admin()));
create policy question_reports_create_self on public.question_reports for insert to authenticated
  with check ((select auth.uid()) = user_id and status = 'open' and reviewed_at is null);
create policy question_reports_admin_update on public.question_reports for update to authenticated
  using ((select itpec_private.is_admin())) with check ((select itpec_private.is_admin()));

create policy knowledge_categories_read_published on public.knowledge_categories for select to anon, authenticated
  using (is_published);
create policy knowledge_categories_admin_all on public.knowledge_categories for all to authenticated
  using ((select itpec_private.is_admin())) with check ((select itpec_private.is_admin()));
create policy knowledge_articles_read_published on public.knowledge_articles for select to anon, authenticated
  using (status = 'published');
create policy knowledge_articles_admin_all on public.knowledge_articles for all to authenticated
  using ((select itpec_private.is_admin())) with check ((select itpec_private.is_admin()));
create policy article_tags_read_published on public.article_tags for select to anon, authenticated
  using (exists (select 1 from public.knowledge_articles a where a.id = article_id and a.status = 'published'));
create policy article_tags_admin_all on public.article_tags for all to authenticated
  using ((select itpec_private.is_admin())) with check ((select itpec_private.is_admin()));
create policy article_questions_read_published on public.article_questions for select to anon, authenticated
  using (exists (select 1 from public.knowledge_articles a where a.id = article_id and a.status = 'published')
     and exists (select 1 from public.questions q where q.id = question_id and q.status = 'published'));
create policy article_questions_admin_all on public.article_questions for all to authenticated
  using ((select itpec_private.is_admin())) with check ((select itpec_private.is_admin()));

create policy donations_read_own_or_admin on public.donations for select to authenticated
  using ((select auth.uid()) = donor_user_id or (select itpec_private.is_admin()));
create policy donations_create_authenticated on public.donations for insert to authenticated
  with check (donor_user_id = (select auth.uid()) and status = 'pending' and verified_by is null and verified_at is null);
create policy donations_create_anonymous on public.donations for insert to anon
  with check (donor_user_id is null and status = 'pending' and verified_by is null and verified_at is null);
create policy donations_admin_update on public.donations for update to authenticated
  using ((select itpec_private.is_admin()))
  with check ((select itpec_private.is_admin()) and verified_by = (select auth.uid()));

create policy announcements_read_published on public.announcements for select to anon, authenticated
  using (is_published);
create policy announcements_admin_all on public.announcements for all to authenticated
  using ((select itpec_private.is_admin())) with check ((select itpec_private.is_admin()));
create policy admin_logs_read_admin on public.admin_logs for select to authenticated
  using ((select itpec_private.is_admin()));
create policy admin_logs_create_admin on public.admin_logs for insert to authenticated
  with check ((select itpec_private.is_admin()) and admin_id = (select auth.uid()));

-- Revoke broad defaults, then grant only the operations used by the client.
revoke all on public.profiles, public.exam_types, public.subjects, public.topics, public.questions,
  public.question_options, public.question_answer_keys, public.exams, public.exam_sections,
  public.exam_questions, public.exam_attempts, public.attempt_answers, public.practice_sessions,
  public.practice_session_questions, public.bookmarks, public.question_reports, public.knowledge_categories,
  public.knowledge_articles, public.article_tags, public.article_questions, public.donations,
  public.announcements, public.admin_logs from public, anon, authenticated, service_role;

grant select on public.profiles to authenticated;
grant update (username, full_name, avatar_url, preferred_language) on public.profiles to authenticated;
grant select on public.exam_types, public.subjects, public.topics, public.question_options,
  public.exams, public.exam_sections, public.exam_questions, public.knowledge_categories,
  public.knowledge_articles, public.article_tags, public.article_questions, public.announcements to anon, authenticated;
grant select (id, exam_type_id, subject_id, topic_id, question_code, question_text_en, question_text_my,
  question_type, difficulty, source_year, source_session, source_reference, copyright_status, status,
  created_by, created_at, updated_at, search_vector_en, search_vector_my) on public.questions to anon, authenticated;
grant insert, update, delete on public.questions to authenticated;
grant select, insert, update, delete on public.exam_types, public.subjects, public.topics,
  public.question_options, public.exams, public.exam_sections, public.exam_questions,
  public.knowledge_categories, public.knowledge_articles, public.article_tags,
  public.article_questions, public.announcements to authenticated;

grant select on public.exam_attempts to authenticated;
grant insert (user_id, exam_id) on public.exam_attempts to authenticated;
grant select (id, attempt_id, question_id, selected_option_ids, answered_at, is_marked_for_review, created_at)
  on public.attempt_answers to authenticated;
grant insert (attempt_id, question_id, selected_option_ids, answered_at, is_marked_for_review)
  on public.attempt_answers to authenticated;
grant update (selected_option_ids, answered_at, is_marked_for_review)
  on public.attempt_answers to authenticated;
grant select on public.practice_sessions to authenticated;
grant insert (user_id, exam_type_id, subject_id, topic_id, question_count, practice_mode)
  on public.practice_sessions to authenticated;
grant select (id, session_id, question_id, display_order, selected_option_ids, answered_at, created_at)
  on public.practice_session_questions to authenticated;
grant insert (session_id, question_id, display_order, selected_option_ids, answered_at)
  on public.practice_session_questions to authenticated;
grant update (selected_option_ids, answered_at) on public.practice_session_questions to authenticated;
grant select, insert, delete on public.bookmarks to authenticated;
grant select, insert, update on public.question_reports to authenticated;
grant select, insert on public.donations to anon, authenticated;
grant update on public.donations to authenticated;
grant select, insert on public.admin_logs to authenticated;

-- The secret server role handles protected content and grading; it is never used in browser code.
grant all on public.profiles, public.exam_types, public.subjects, public.topics, public.questions,
  public.question_options, public.question_answer_keys, public.exams, public.exam_sections,
  public.exam_questions, public.exam_attempts, public.attempt_answers, public.practice_sessions,
  public.practice_session_questions, public.bookmarks, public.question_reports, public.knowledge_categories,
  public.knowledge_articles, public.article_tags, public.article_questions, public.donations,
  public.announcements, public.admin_logs to service_role;

-- A private bucket for donation proofs; force an existing bucket with this ID to remain private.
insert into storage.buckets (id, name, public)
values ('donation-proofs', 'donation-proofs', false)
on conflict (id) do update set public = false;

create policy donation_proofs_upload_own on storage.objects for insert to authenticated
  with check (bucket_id = 'donation-proofs' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy donation_proofs_read_own_or_admin on storage.objects for select to authenticated
  using (bucket_id = 'donation-proofs' and (
    (storage.foldername(name))[1] = (select auth.uid())::text or (select itpec_private.is_admin())
  ));
create policy donation_proofs_update_own_or_admin on storage.objects for update to authenticated
  using (bucket_id = 'donation-proofs' and (
    (storage.foldername(name))[1] = (select auth.uid())::text or (select itpec_private.is_admin())
  ))
  with check (bucket_id = 'donation-proofs' and (
    (storage.foldername(name))[1] = (select auth.uid())::text or (select itpec_private.is_admin())
  ));
create policy donation_proofs_delete_own_or_admin on storage.objects for delete to authenticated
  using (bucket_id = 'donation-proofs' and (
    (storage.foldername(name))[1] = (select auth.uid())::text or (select itpec_private.is_admin())
  ));

comment on table public.question_answer_keys is
  'Private grading data. Never grant anon or authenticated access; grade through trusted server-side logic only.';
comment on column public.questions.explanation_en is
  'Private from browser roles; retrieve only through a trusted post-submission server flow.';
comment on column public.questions.explanation_my is
  'Private from browser roles; retrieve only through a trusted post-submission server flow.';
comment on table public.donations is
  'Contains private donor and payment reference metadata. Payment proofs live in the private donation-proofs bucket.';
comment on index public.questions_exam_type_subject_topic_idx is
  'Supports the common exam type plus subject/topic question-bank filters.';
comment on index public.exam_attempts_user_created_idx is
  'Supports a user''s attempt history ordered newest first.';
comment on index public.exam_attempts_user_status_idx is
  'Supports active-attempt and status-filtered dashboard lookups.';
comment on index public.knowledge_articles_search_en_idx is
  'English article search. The simple dictionary preserves technical tokens and avoids English-only stemming.';
comment on index public.knowledge_articles_search_my_idx is
  'Myanmar article search. The simple dictionary avoids applying English stemming to Myanmar text.';



