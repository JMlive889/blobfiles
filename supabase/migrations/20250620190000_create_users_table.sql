-- Section 2: User Configuration & Tiers — core public.users profile table

create table public.users (
  id uuid primary key references auth.users (id) on delete cascade,
  short_id text,
  anon_id uuid not null default gen_random_uuid(),
  username text not null,
  full_name text,
  avatar_url text,
  bio text,
  status text not null default 'active' check (status in ('active', 'deactivated', 'deleted')),
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.users is 'BlobFiles user profiles linked to auth.users';
comment on column public.users.short_id is 'User-facing short ID, e.g. user_44665544';
comment on column public.users.anon_id is 'Anonymized ID for internal/admin use only';
comment on column public.users.status is 'Account state: active, deactivated, or deleted';

create unique index users_username_idx on public.users (username);
create unique index users_short_id_idx on public.users (short_id);
create unique index users_anon_id_idx on public.users (anon_id);

alter table public.users enable row level security;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger users_set_updated_at
before update on public.users
for each row
execute function public.set_updated_at();