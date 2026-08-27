-- ============================================================================
--  JharUdyam · SIH26043
--  Supabase schema for the societal challenge platform
--
--  HOW TO RUN
--  1. Open your Supabase project
--  2. Left sidebar -> SQL Editor -> "New query"
--  3. Paste this ENTIRE file, then press "Run"
--
--  Running it twice is safe — everything is written to be re-runnable.
-- ============================================================================


-- ----------------------------------------------------------------------------
--  0. Extensions
-- ----------------------------------------------------------------------------
create extension if not exists pgcrypto;


-- ----------------------------------------------------------------------------
--  1. Enums  (the fixed vocabularies used across the platform)
-- ----------------------------------------------------------------------------

-- Portal roles. Citizens use the mobile app directly without authentication.
do $$ begin
  create type public.user_role as enum ('government', 'university', 'industry');
exception when duplicate_object then null; end $$;

-- The problem lifecycle.
do $$ begin
  create type public.problem_status as enum (
    'submitted',            -- citizen sent it, AI has filled in the details
    'under_review',         -- the assigned department has opened it
    'government_handling',  -- department is handling it internally
    'released',             -- department opened it up for collaboration
    'interest_expressed',   -- a university or industry has put its hand up
    'in_progress',          -- work has started
    'resolved',             -- done (auto-deleted after 24 hours)
    'rejected'              -- rejected with reason (auto-deleted after 1 hour)
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.priority_level as enum ('low', 'medium', 'high', 'critical');
exception when duplicate_object then null; end $$;

-- Who the government has released a problem to.
do $$ begin
  create type public.release_scope as enum ('none', 'university', 'industry', 'both');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.interest_status as enum ('expressed', 'withdrawn');
exception when duplicate_object then null; end $$;


-- ----------------------------------------------------------------------------
--  2. profiles — one row per portal user, holds the role
-- ----------------------------------------------------------------------------
--  department  : filled in for government users (e.g. 'Public Works')
--                a government user sees only problems for their department.
--                Leave it NULL for a state-level account that sees everything.
--  organization: filled in for university / industry users
--                (e.g. 'BIT Mesra', 'Tata Steel')
-- ----------------------------------------------------------------------------
create table if not exists public.profiles (
  id            uuid primary key references auth.users (id) on delete cascade,
  full_name     text not null default '',
  role          public.user_role not null default 'government',
  department    text,
  organization  text,
  phone         text,
  created_at    timestamptz not null default now()
);

comment on table public.profiles is 'Role and identity for portal users (government, university, industry).';


-- ----------------------------------------------------------------------------
--  3. problems — the citizen reports, after AI processing
-- ----------------------------------------------------------------------------
--  The mobile app writes: image_url, image_path, latitude, longitude, address,
--  reporter_id (optional device/anonymous ID), reporter_name, plus the AI output
--  (title, description, category, priority, department, duplicate_of).
--  The web portal reads those and writes: status, released_to, released_at,
--  resolved_at, rejected_at, rejection_reason, rejected_by, released_by, government_note.
-- ----------------------------------------------------------------------------
create sequence if not exists public.problem_ticket_seq;

create table if not exists public.problems (
  id               uuid primary key default gen_random_uuid(),

  -- human-readable reference shown in every dashboard, e.g. JU-26-0001
  ticket_no        text unique,

  -- ---- AI output ----
  title            text not null default '',
  description      text not null default '',
  category         text,
  priority         public.priority_level not null default 'medium',
  department       text,
  duplicate_of     uuid references public.problems (id) on delete set null,

  -- ---- evidence and place ----
  image_url        text,
  image_path       text,
  address          text,
  latitude         double precision,
  longitude        double precision,

  -- ---- reporter (anonymous / unauthenticated citizen) ----
  reporter_id      text,
  reporter_name    text,

  -- ---- government decision ----
  status           public.problem_status not null default 'submitted',
  released_to      public.release_scope not null default 'none',
  released_at      timestamptz,
  resolved_at      timestamptz,
  rejected_at      timestamptz,
  rejection_reason text,
  rejected_by      uuid references auth.users (id) on delete set null,
  released_by      uuid references auth.users (id) on delete set null,
  government_note  text,

  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

create index if not exists problems_department_idx  on public.problems (department);
create index if not exists problems_status_idx      on public.problems (status);
create index if not exists problems_released_to_idx on public.problems (released_to);
create index if not exists problems_created_at_idx  on public.problems (created_at desc);
create index if not exists problems_reporter_idx    on public.problems (reporter_id);

comment on table public.problems is 'Citizen-reported problems, structured by AI and routed to a department.';


-- ----------------------------------------------------------------------------
--  4. interests — a university or industry putting its hand up
-- ----------------------------------------------------------------------------
create table if not exists public.interests (
  id          uuid primary key default gen_random_uuid(),
  problem_id  uuid not null references public.problems (id) on delete cascade,
  org_id      uuid not null references public.profiles (id) on delete cascade,
  org_type    public.user_role not null,
  org_name    text,
  status      public.interest_status not null default 'expressed',
  note        text,
  created_at  timestamptz not null default now(),
  unique (problem_id, org_id)
);

create index if not exists interests_problem_idx on public.interests (problem_id);
create index if not exists interests_org_idx     on public.interests (org_id);

comment on table public.interests is 'Voluntary interest from a university or industry in a released problem.';


-- ----------------------------------------------------------------------------
--  5. notifications — one row per recipient, created by triggers below
-- ----------------------------------------------------------------------------
create table if not exists public.notifications (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  problem_id  uuid references public.problems (id) on delete cascade,
  title       text not null,
  body        text,
  is_read     boolean not null default false,
  created_at  timestamptz not null default now()
);

create index if not exists notifications_user_idx on public.notifications (user_id, is_read, created_at desc);


-- ----------------------------------------------------------------------------
--  6. Helper functions
-- ----------------------------------------------------------------------------
--  These read the caller's own profile. They are SECURITY DEFINER so that the
--  security rules on "profiles" don't call themselves in a loop.
-- ----------------------------------------------------------------------------

create or replace function public.auth_role()
returns public.user_role
language sql
stable
security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid();
$$;

create or replace function public.auth_department()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select department from public.profiles where id = auth.uid();
$$;

-- Does the caller belong to the department that owns this problem?
-- A government user with no department set is treated as state-level (sees all).
create or replace function public.is_my_department(problem_department text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.auth_role() = 'government'
     and (public.auth_department() is null
          or public.auth_department() = problem_department);
$$;

grant execute on function public.auth_role()       to authenticated;
grant execute on function public.auth_department() to authenticated;
grant execute on function public.is_my_department(text) to authenticated;


-- ----------------------------------------------------------------------------
--  7. Triggers
-- ----------------------------------------------------------------------------

-- 7a. New auth user -> create a profile row for portal logins.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, role, department, organization)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    coalesce((new.raw_user_meta_data ->> 'role')::public.user_role, 'government'),
    new.raw_user_meta_data ->> 'department',
    new.raw_user_meta_data ->> 'organization'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();


-- 7b. Ticket number + updated_at + resolved_at + rejected_at
create or replace function public.problems_before_write()
returns trigger
language plpgsql
as $$
begin
  if new.ticket_no is null then
    new.ticket_no := 'JU-' || to_char(now(), 'YY') || '-' ||
                     lpad(nextval('public.problem_ticket_seq')::text, 4, '0');
  end if;

  -- If moving to resolved state, stamp resolved_at with exact current UTC timestamp
  if new.status = 'resolved' and (old is null or old.status is distinct from 'resolved') then
    new.resolved_at := now();
  elsif new.status <> 'resolved' then
    new.resolved_at := null;
  end if;

  -- If moving to rejected state, stamp rejected_at with exact current UTC timestamp
  if new.status = 'rejected' and (old is null or old.status is distinct from 'rejected') then
    new.rejected_at := now();
  elsif new.status <> 'rejected' then
    new.rejected_at := null;
  end if;

  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists problems_before_write_trg on public.problems;
create trigger problems_before_write_trg
  before insert or update on public.problems
  for each row execute function public.problems_before_write();


-- 7c. New problem -> notify the government users of that department
create or replace function public.notify_department_on_new_problem()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.notifications (user_id, problem_id, title, body)
  select p.id,
         new.id,
         'New problem in your department',
         coalesce(new.title, 'A citizen report') || ' · ' || coalesce(new.address, 'location attached')
  from public.profiles p
  where p.role = 'government'
    and (p.department = new.department or p.department is null);
  return new;
end;
$$;

drop trigger if exists notify_new_problem_trg on public.problems;
create trigger notify_new_problem_trg
  after insert on public.problems
  for each row execute function public.notify_department_on_new_problem();


-- 7d. Problem released -> notify the university / industry users it was released to
create or replace function public.notify_on_release()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.released_to = old.released_to then
    return new;
  end if;

  insert into public.notifications (user_id, problem_id, title, body)
  select p.id,
         new.id,
         'New challenge open for collaboration',
         coalesce(new.title, 'A released problem') || ' · ' || coalesce(new.department, 'department')
  from public.profiles p
  where (new.released_to = 'both' and p.role in ('university', 'industry'))
     or (new.released_to = 'university' and p.role = 'university')
     or (new.released_to = 'industry'   and p.role = 'industry');

  return new;
end;
$$;

drop trigger if exists notify_on_release_trg on public.problems;
create trigger notify_on_release_trg
  after update of released_to on public.problems
  for each row execute function public.notify_on_release();


-- 7e. Interest expressed -> move the problem to 'interest_expressed'
--     and notify the owning department
create or replace function public.handle_new_interest()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  prob public.problems;
begin
  select * into prob from public.problems where id = new.problem_id;

  if prob.status = 'released' then
    update public.problems set status = 'interest_expressed' where id = new.problem_id;
  end if;

  insert into public.notifications (user_id, problem_id, title, body)
  select p.id,
         new.problem_id,
         'Interest received',
         coalesce(new.org_name, 'An organisation') || ' wants to work on ' ||
         coalesce(prob.ticket_no, 'a released problem')
  from public.profiles p
  where p.role = 'government'
    and (p.department = prob.department or p.department is null);

  return new;
end;
$$;

drop trigger if exists handle_new_interest_trg on public.interests;
create trigger handle_new_interest_trg
  after insert on public.interests
  for each row execute function public.handle_new_interest();


-- 7f. Interest withdrawn -> if nobody is left interested, put the problem back
--     to 'released' so the department does not see a stale "interest expressed".
--     Deliberately does nothing once work has actually started: a problem that
--     has reached 'in_progress' or 'resolved' must not be dragged backwards.
create or replace function public.handle_interest_removed()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  remaining int;
begin
  select count(*) into remaining
  from public.interests
  where problem_id = old.problem_id
    and status = 'expressed';

  if remaining = 0 then
    update public.problems
       set status = 'released'
     where id = old.problem_id
       and status = 'interest_expressed'
       and released_to <> 'none';
  end if;

  return old;
end;
$$;

drop trigger if exists handle_interest_removed_trg on public.interests;
create trigger handle_interest_removed_trg
  after delete on public.interests
  for each row execute function public.handle_interest_removed();


-- ----------------------------------------------------------------------------
--  8. Row Level Security
-- ----------------------------------------------------------------------------
--  This is what actually enforces role separation.
-- ----------------------------------------------------------------------------

alter table public.profiles      enable row level security;
alter table public.problems      enable row level security;
alter table public.interests     enable row level security;
alter table public.notifications enable row level security;

-- ---- profiles ----
drop policy if exists "read own profile" on public.profiles;
create policy "read own profile" on public.profiles
  for select to authenticated
  using (id = auth.uid());

-- Government needs to see which university / industry expressed interest.
drop policy if exists "government reads profiles" on public.profiles;
create policy "government reads profiles" on public.profiles
  for select to authenticated
  using (public.auth_role() = 'government');

drop policy if exists "update own profile" on public.profiles;
create policy "update own profile" on public.profiles
  for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- ---- problems ----

-- Drop previous policies to ensure clean migration
drop policy if exists "citizen reads own reports" on public.problems;
drop policy if exists "citizen creates report" on public.problems;
drop policy if exists "public reads problems" on public.problems;
drop policy if exists "anyone creates report" on public.problems;

-- Citizens (unauthenticated mobile app users) can browse and view all reported problems.
create policy "public reads problems" on public.problems
  for select
  to anon
  using (true);

-- Anyone (including unauthenticated citizens uploading via mobile app) can submit reports.
create policy "anyone creates report" on public.problems
  for insert
  to anon, authenticated
  with check (true);

-- Government: only its own department's problems (for authenticated portal users).
drop policy if exists "government reads department problems" on public.problems;
create policy "government reads department problems" on public.problems
  for select to authenticated
  using (public.is_my_department(department));

drop policy if exists "government updates department problems" on public.problems;
create policy "government updates department problems" on public.problems
  for update to authenticated
  using (public.is_my_department(department))
  with check (public.is_my_department(department));

-- University: only problems released to universities (for authenticated portal users).
drop policy if exists "university reads released problems" on public.problems;
create policy "university reads released problems" on public.problems
  for select to authenticated
  using (
    public.auth_role() = 'university'
    and released_to in ('university', 'both')
  );

-- Industry: only problems released to industry (for authenticated portal users).
drop policy if exists "industry reads released problems" on public.problems;
create policy "industry reads released problems" on public.problems
  for select to authenticated
  using (
    public.auth_role() = 'industry'
    and released_to in ('industry', 'both')
  );

-- ---- interests ----
drop policy if exists "org reads own interests" on public.interests;
create policy "org reads own interests" on public.interests
  for select to authenticated
  using (org_id = auth.uid());

drop policy if exists "government reads interests on its problems" on public.interests;
create policy "government reads interests on its problems" on public.interests
  for select to authenticated
  using (
    exists (
      select 1 from public.problems pr
      where pr.id = interests.problem_id
        and public.is_my_department(pr.department)
    )
  );

-- An organisation may only register interest in a problem that was actually
-- released to its kind of organisation.
drop policy if exists "org expresses interest" on public.interests;
create policy "org expresses interest" on public.interests
  for insert to authenticated
  with check (
    org_id = auth.uid()
    and public.auth_role() in ('university', 'industry')
    and org_type = public.auth_role()
    and exists (
      select 1 from public.problems pr
      where pr.id = interests.problem_id
        and (
          (public.auth_role() = 'university' and pr.released_to in ('university', 'both'))
          or
          (public.auth_role() = 'industry'   and pr.released_to in ('industry', 'both'))
        )
    )
  );

drop policy if exists "org updates own interest" on public.interests;
create policy "org updates own interest" on public.interests
  for update to authenticated
  using (org_id = auth.uid())
  with check (org_id = auth.uid());

drop policy if exists "org deletes own interest" on public.interests;
create policy "org deletes own interest" on public.interests
  for delete to authenticated
  using (org_id = auth.uid());

-- ---- notifications ----
drop policy if exists "read own notifications" on public.notifications;
create policy "read own notifications" on public.notifications
  for select to authenticated
  using (user_id = auth.uid());

drop policy if exists "update own notifications" on public.notifications;
create policy "update own notifications" on public.notifications
  for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());


-- ----------------------------------------------------------------------------
--  9. Storage bucket for the photographs the citizens upload
-- ----------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('problem-images', 'problem-images', true)
on conflict (id) do nothing;

-- Anyone can view a photo (the bucket is public).
drop policy if exists "public read problem images" on storage.objects;
create policy "public read problem images" on storage.objects
  for select
  using (bucket_id = 'problem-images');

-- Anyone (including unauthenticated citizens on the mobile app) can upload photos.
drop policy if exists "authenticated upload problem images" on storage.objects;
drop policy if exists "public upload problem images" on storage.objects;
create policy "public upload problem images" on storage.objects
  for insert
  to anon, authenticated
  with check (bucket_id = 'problem-images');


-- ----------------------------------------------------------------------------
-- 10. Realtime — so a release shows up on the university/industry board
--     without anyone pressing refresh
-- ----------------------------------------------------------------------------
do $$
begin
  alter publication supabase_realtime add table public.problems;
exception when others then
  raise notice 'problems already in the realtime publication (fine)';
end $$;

do $$
begin
  alter publication supabase_realtime add table public.notifications;
exception when others then
  raise notice 'notifications already in the realtime publication (fine)';
end $$;


-- ----------------------------------------------------------------------------
-- 11. Automated Cleanup (24h for Resolved, 1h for Rejected)
-- ----------------------------------------------------------------------------
create or replace function public.delete_expired_problems()
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  resolved_deleted int := 0;
  rejected_deleted int := 0;
begin
  -- 1. Delete resolved problems older than 24 hours
  delete from public.problems
  where status = 'resolved'
    and resolved_at is not null
    and resolved_at < (now() - interval '24 hours');
  get diagnostics resolved_deleted = row_count;

  -- 2. Delete rejected problems older than 1 hour
  delete from public.problems
  where status = 'rejected'
    and rejected_at is not null
    and rejected_at < (now() - interval '1 hour');
  get diagnostics rejected_deleted = row_count;

  return resolved_deleted + rejected_deleted;
end;
$$;

-- Schedule cron cleanup every 5 minutes if pg_cron extension is available
do $$
begin
  create extension if not exists pg_cron with schema extensions;
  perform cron.unschedule('cleanup-resolved-problems');
  perform cron.unschedule('cleanup-expired-problems');
exception when others then
  null;
end $$;

do $$
begin
  perform cron.schedule(
    'cleanup-expired-problems',
    '*/5 * * * *',
    'select public.delete_expired_problems();'
  );
exception when others then
  raise notice 'pg_cron schedule skipped (handled by database function)';
end $$;


-- ============================================================================
--  Done. Next: run setup_users.sql to give your portal logins their roles.
-- ============================================================================
