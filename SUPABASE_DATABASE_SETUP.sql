-- ============================================================
-- HeartbeatSchedule / Supabase Database Setup
-- ------------------------------------------------------------
-- Usage:
-- 1. Open Supabase SQL Editor
-- 2. Paste this script
-- 3. Execute once
--
-- This script creates:
-- - public.profiles
-- - public.invite_codes
-- - public.couples
-- - public.courses
-- - public.couple_events
-- - public.shared_todos
-- - public.user_devices
-- - public.reminder_messages
-- - public.course_overrides
--
-- It also creates:
-- - updated_at triggers
-- - auth.users -> public.profiles auto-create trigger
-- - baseline RLS policies
-- ============================================================

create extension if not exists pgcrypto;

-- ============================================================
-- Helper functions
-- ============================================================

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.default_section_times()
returns jsonb
language sql
immutable
as $$
  select '[
    {"section":1,"startHour":8,"startMinute":0,"endHour":8,"endMinute":50},
    {"section":2,"startHour":8,"startMinute":55,"endHour":9,"endMinute":45},
    {"section":3,"startHour":10,"startMinute":0,"endHour":10,"endMinute":50},
    {"section":4,"startHour":10,"startMinute":55,"endHour":11,"endMinute":45},
    {"section":5,"startHour":14,"startMinute":0,"endHour":14,"endMinute":50},
    {"section":6,"startHour":14,"startMinute":55,"endHour":15,"endMinute":45},
    {"section":7,"startHour":16,"startMinute":0,"endHour":16,"endMinute":50},
    {"section":8,"startHour":16,"startMinute":55,"endHour":17,"endMinute":45},
    {"section":9,"startHour":19,"startMinute":0,"endHour":19,"endMinute":50},
    {"section":10,"startHour":19,"startMinute":55,"endHour":20,"endMinute":45},
    {"section":11,"startHour":20,"startMinute":50,"endHour":21,"endMinute":40},
    {"section":12,"startHour":21,"startMinute":45,"endHour":22,"endMinute":30}
  ]'::jsonb;
$$;

-- ============================================================
-- Core tables
-- ============================================================

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  nickname text not null,
  avatar_url text,
  couple_id uuid,
  semester_start_date timestamptz,
  total_weeks smallint not null default 20 check (total_weeks between 1 and 24),
  current_week_offset smallint not null default 0,
  theme_mode text not null default 'blue' check (theme_mode in ('blue', 'pink')),
  section_times jsonb not null default public.default_section_times(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.invite_codes (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  creator_id uuid not null references public.profiles(id) on delete cascade,
  used_by_id uuid references public.profiles(id) on delete set null,
  couple_id uuid,
  status text not null default 'active' check (status in ('active', 'used', 'revoked', 'expired')),
  expires_at timestamptz,
  used_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.couples (
  id uuid primary key default gen_random_uuid(),
  user_a_id uuid not null references public.profiles(id) on delete cascade,
  user_b_id uuid not null references public.profiles(id) on delete cascade,
  invite_code_id uuid references public.invite_codes(id) on delete set null,
  anniversary_date timestamptz,
  status text not null default 'active' check (status in ('active', 'unbound')),
  bound_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint couples_distinct_users check (user_a_id <> user_b_id)
);

create table if not exists public.courses (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  couple_id uuid references public.couples(id) on delete set null,
  name text not null,
  location text,
  teacher text,
  day_of_week smallint not null check (day_of_week between 1 and 7),
  start_section smallint not null check (start_section >= 1),
  duration smallint not null check (duration >= 1),
  weeks int[] not null,
  color text not null default '#87CEFA',
  is_private boolean not null default false,
  source text not null default 'manual' check (source in ('manual', 'imported', 'synced')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.shared_todos (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples(id) on delete cascade,
  content text not null,
  created_by uuid not null references public.profiles(id) on delete cascade,
  is_completed boolean not null default false,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.couple_events (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples(id) on delete cascade,
  title text not null,
  week integer not null check (week >= 1),
  day_of_week smallint not null check (day_of_week between 1 and 7),
  start_section smallint not null check (start_section >= 1),
  end_section smallint not null check (end_section >= start_section),
  created_by uuid not null references public.profiles(id) on delete cascade,
  reply_content text,
  replied_by uuid references public.profiles(id) on delete set null,
  replied_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================
-- Optional expansion tables
-- ============================================================

create table if not exists public.user_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  platform text not null,
  push_token text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.reminder_messages (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  receiver_id uuid not null references public.profiles(id) on delete cascade,
  message_type text not null,
  content text not null,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.course_overrides (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete cascade,
  week integer not null check (week >= 1),
  override_type text not null check (override_type in ('reschedule', 'makeup', 'cancel')),
  new_day_of_week smallint check (new_day_of_week between 1 and 7),
  new_start_section smallint check (new_start_section >= 1),
  new_duration smallint check (new_duration >= 1),
  new_location text,
  created_at timestamptz not null default now()
);

-- ============================================================
-- Relationship helper functions
-- ------------------------------------------------------------
-- These functions depend on public.couples, so they must be
-- created only after the couples table exists.
-- ============================================================

create or replace function public.is_couple_member(target_couple_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.couples c
    where c.id = target_couple_id
      and c.status = 'active'
      and auth.uid() in (c.user_a_id, c.user_b_id)
  );
$$;

create or replace function public.is_partner_of_user(target_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.couples c
    where c.status = 'active'
      and (
        (c.user_a_id = auth.uid() and c.user_b_id = target_user_id)
        or
        (c.user_b_id = auth.uid() and c.user_a_id = target_user_id)
      )
  );
$$;

-- ============================================================
-- Foreign keys added after dependent tables exist
-- ============================================================

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'profiles_couple_id_fkey'
  ) then
    alter table public.profiles
      add constraint profiles_couple_id_fkey
      foreign key (couple_id) references public.couples(id) on delete set null;
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'invite_codes_couple_id_fkey'
  ) then
    alter table public.invite_codes
      add constraint invite_codes_couple_id_fkey
      foreign key (couple_id) references public.couples(id) on delete set null;
  end if;
end
$$;

-- ============================================================
-- Indexes
-- ============================================================

create index if not exists idx_profiles_couple_id on public.profiles(couple_id);

create index if not exists idx_invite_codes_creator_id on public.invite_codes(creator_id);
create index if not exists idx_invite_codes_status on public.invite_codes(status);
create unique index if not exists idx_invite_codes_one_active_per_creator
  on public.invite_codes(creator_id)
  where status = 'active';

create index if not exists idx_couples_user_a_id on public.couples(user_a_id);
create index if not exists idx_couples_user_b_id on public.couples(user_b_id);
create index if not exists idx_couples_status on public.couples(status);
create unique index if not exists idx_couples_unique_pair
  on public.couples(least(user_a_id, user_b_id), greatest(user_a_id, user_b_id))
  where status = 'active';

create index if not exists idx_courses_owner_id on public.courses(owner_id);
create index if not exists idx_courses_couple_id on public.courses(couple_id);
create index if not exists idx_courses_owner_day_section on public.courses(owner_id, day_of_week, start_section);
create index if not exists idx_courses_weeks_gin on public.courses using gin(weeks);

create index if not exists idx_couple_events_couple_id on public.couple_events(couple_id);
create index if not exists idx_couple_events_week on public.couple_events(week);
create index if not exists idx_couple_events_day_of_week on public.couple_events(day_of_week);

create index if not exists idx_shared_todos_couple_id on public.shared_todos(couple_id);
create index if not exists idx_shared_todos_couple_created_at on public.shared_todos(couple_id, created_at desc);

create index if not exists idx_user_devices_user_id on public.user_devices(user_id);
create index if not exists idx_reminder_messages_couple_id on public.reminder_messages(couple_id);
create index if not exists idx_course_overrides_course_id on public.course_overrides(course_id);

-- ============================================================
-- updated_at triggers
-- ============================================================

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
before update on public.profiles
for each row execute procedure public.set_updated_at();

drop trigger if exists set_couples_updated_at on public.couples;
create trigger set_couples_updated_at
before update on public.couples
for each row execute procedure public.set_updated_at();

drop trigger if exists set_courses_updated_at on public.courses;
create trigger set_courses_updated_at
before update on public.courses
for each row execute procedure public.set_updated_at();

drop trigger if exists set_shared_todos_updated_at on public.shared_todos;
create trigger set_shared_todos_updated_at
before update on public.shared_todos
for each row execute procedure public.set_updated_at();

drop trigger if exists set_couple_events_updated_at on public.couple_events;
create trigger set_couple_events_updated_at
before update on public.couple_events
for each row execute procedure public.set_updated_at();

drop trigger if exists set_user_devices_updated_at on public.user_devices;
create trigger set_user_devices_updated_at
before update on public.user_devices
for each row execute procedure public.set_updated_at();

-- ============================================================
-- auth.users -> profiles auto create
-- ============================================================

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  generated_nickname text;
begin
  generated_nickname := coalesce(nullif(split_part(new.email, '@', 1), ''), '用户');

  insert into public.profiles (
    id,
    email,
    nickname,
    section_times
  )
  values (
    new.id,
    new.email,
    generated_nickname,
    public.default_section_times()
  )
  on conflict (id) do update
    set email = excluded.email;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- ============================================================
-- RLS
-- ============================================================

alter table public.profiles enable row level security;
alter table public.invite_codes enable row level security;
alter table public.couples enable row level security;
alter table public.courses enable row level security;
alter table public.couple_events enable row level security;
alter table public.shared_todos enable row level security;
alter table public.user_devices enable row level security;
alter table public.reminder_messages enable row level security;
alter table public.course_overrides enable row level security;

-- profiles
drop policy if exists "profiles_select_self_or_partner" on public.profiles;
create policy "profiles_select_self_or_partner"
on public.profiles
for select
using (
  auth.uid() = id
  or public.is_partner_of_user(id)
);

drop policy if exists "profiles_update_self" on public.profiles;
create policy "profiles_update_self"
on public.profiles
for update
using (auth.uid() = id)
with check (auth.uid() = id);

-- invite_codes
drop policy if exists "invite_codes_select_active_or_own" on public.invite_codes;
create policy "invite_codes_select_active_or_own"
on public.invite_codes
for select
using (
  creator_id = auth.uid()
  or status = 'active'
);

drop policy if exists "invite_codes_insert_own" on public.invite_codes;
create policy "invite_codes_insert_own"
on public.invite_codes
for insert
with check (creator_id = auth.uid());

drop policy if exists "invite_codes_update_active_or_own" on public.invite_codes;
create policy "invite_codes_update_active_or_own"
on public.invite_codes
for update
using (
  creator_id = auth.uid()
  or status = 'active'
);

-- couples
drop policy if exists "couples_select_members" on public.couples;
create policy "couples_select_members"
on public.couples
for select
using (auth.uid() in (user_a_id, user_b_id));

drop policy if exists "couples_insert_members" on public.couples;
create policy "couples_insert_members"
on public.couples
for insert
with check (auth.uid() in (user_a_id, user_b_id));

drop policy if exists "couples_update_members" on public.couples;
create policy "couples_update_members"
on public.couples
for update
using (auth.uid() in (user_a_id, user_b_id));

drop policy if exists "couples_delete_members" on public.couples;
create policy "couples_delete_members"
on public.couples
for delete
using (auth.uid() in (user_a_id, user_b_id));

-- courses
drop policy if exists "courses_select_owner_or_partner_visible" on public.courses;
create policy "courses_select_owner_or_partner_visible"
on public.courses
for select
using (
  owner_id = auth.uid()
  or (
    not is_private
    and couple_id is not null
    and public.is_couple_member(couple_id)
  )
);

drop policy if exists "courses_insert_owner" on public.courses;
create policy "courses_insert_owner"
on public.courses
for insert
with check (owner_id = auth.uid());

drop policy if exists "courses_update_owner" on public.courses;
create policy "courses_update_owner"
on public.courses
for update
using (owner_id = auth.uid())
with check (owner_id = auth.uid());

drop policy if exists "courses_delete_owner" on public.courses;
create policy "courses_delete_owner"
on public.courses
for delete
using (owner_id = auth.uid());

-- shared_todos
drop policy if exists "shared_todos_select_couple_members" on public.shared_todos;
create policy "shared_todos_select_couple_members"
on public.shared_todos
for select
using (public.is_couple_member(couple_id));

drop policy if exists "shared_todos_insert_couple_members" on public.shared_todos;
create policy "shared_todos_insert_couple_members"
on public.shared_todos
for insert
with check (
  public.is_couple_member(couple_id)
  and created_by = auth.uid()
);

drop policy if exists "shared_todos_update_couple_members" on public.shared_todos;
create policy "shared_todos_update_couple_members"
on public.shared_todos
for update
using (public.is_couple_member(couple_id));

drop policy if exists "shared_todos_delete_couple_members" on public.shared_todos;
create policy "shared_todos_delete_couple_members"
on public.shared_todos
for delete
using (public.is_couple_member(couple_id));

-- couple_events
drop policy if exists "couple_events_select_couple_members" on public.couple_events;
create policy "couple_events_select_couple_members"
on public.couple_events
for select
using (public.is_couple_member(couple_id));

drop policy if exists "couple_events_insert_couple_members" on public.couple_events;
create policy "couple_events_insert_couple_members"
on public.couple_events
for insert
with check (
  public.is_couple_member(couple_id)
  and created_by = auth.uid()
);

drop policy if exists "couple_events_update_couple_members" on public.couple_events;
create policy "couple_events_update_couple_members"
on public.couple_events
for update
using (public.is_couple_member(couple_id));

drop policy if exists "couple_events_delete_couple_members" on public.couple_events;
create policy "couple_events_delete_couple_members"
on public.couple_events
for delete
using (public.is_couple_member(couple_id));

-- user_devices
drop policy if exists "user_devices_select_own" on public.user_devices;
create policy "user_devices_select_own"
on public.user_devices
for select
using (user_id = auth.uid());

drop policy if exists "user_devices_insert_own" on public.user_devices;
create policy "user_devices_insert_own"
on public.user_devices
for insert
with check (user_id = auth.uid());

drop policy if exists "user_devices_update_own" on public.user_devices;
create policy "user_devices_update_own"
on public.user_devices
for update
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "user_devices_delete_own" on public.user_devices;
create policy "user_devices_delete_own"
on public.user_devices
for delete
using (user_id = auth.uid());

-- reminder_messages
drop policy if exists "reminder_messages_select_sender_or_receiver" on public.reminder_messages;
create policy "reminder_messages_select_sender_or_receiver"
on public.reminder_messages
for select
using (auth.uid() in (sender_id, receiver_id));

drop policy if exists "reminder_messages_insert_sender" on public.reminder_messages;
create policy "reminder_messages_insert_sender"
on public.reminder_messages
for insert
with check (
  sender_id = auth.uid()
  and public.is_couple_member(couple_id)
);

drop policy if exists "reminder_messages_update_sender_or_receiver" on public.reminder_messages;
create policy "reminder_messages_update_sender_or_receiver"
on public.reminder_messages
for update
using (auth.uid() in (sender_id, receiver_id));

-- course_overrides
drop policy if exists "course_overrides_select_owner" on public.course_overrides;
create policy "course_overrides_select_owner"
on public.course_overrides
for select
using (
  exists (
    select 1 from public.courses c
    where c.id = course_id
      and c.owner_id = auth.uid()
  )
);

drop policy if exists "course_overrides_insert_owner" on public.course_overrides;
create policy "course_overrides_insert_owner"
on public.course_overrides
for insert
with check (
  exists (
    select 1 from public.courses c
    where c.id = course_id
      and c.owner_id = auth.uid()
  )
);

drop policy if exists "course_overrides_update_owner" on public.course_overrides;
create policy "course_overrides_update_owner"
on public.course_overrides
for update
using (
  exists (
    select 1 from public.courses c
    where c.id = course_id
      and c.owner_id = auth.uid()
  )
);

drop policy if exists "course_overrides_delete_owner" on public.course_overrides;
create policy "course_overrides_delete_owner"
on public.course_overrides
for delete
using (
  exists (
    select 1 from public.courses c
    where c.id = course_id
      and c.owner_id = auth.uid()
  )
);

-- ============================================================
-- Notes
-- ------------------------------------------------------------
-- 1. invite_codes update policy is intentionally broad enough
--    for the current client-driven binding flow to work.
--    In a later hardened version, this should be moved to
--    RPC / Edge Function / server-side binding logic.
--
-- 2. The application currently plans to standardize on
--    "profiles" instead of "users" as the public business table.
-- ============================================================
