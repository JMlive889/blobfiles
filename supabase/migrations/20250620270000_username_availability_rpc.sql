-- Case-insensitive username uniqueness (idempotent) + availability RPC for RLS-safe checks.

drop index if exists public.users_username_idx;

create unique index if not exists users_username_lower_idx
  on public.users (lower(username));

create or replace function public.is_username_available(
  p_username text,
  p_user_id uuid
)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select not exists (
    select 1
    from public.users
    where lower(username) = lower(trim(p_username))
      and id <> p_user_id
  );
$$;

revoke all on function public.is_username_available(text, uuid) from public;
grant execute on function public.is_username_available(text, uuid) to authenticated;