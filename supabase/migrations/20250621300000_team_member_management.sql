-- Allow team owners/admins to add members; lookup users by username for invites.

create or replace function public.is_team_manager(p_team_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1
    from public.team_members
    where team_id = p_team_id
      and user_id = auth.uid()
      and role in ('owner', 'admin')
  );
$$;

create or replace function public.find_user_id_by_username(p_username text)
returns uuid
language sql
security definer
stable
set search_path = public
as $$
  select id
  from public.users
  where lower(username) = lower(trim(p_username))
  limit 1;
$$;

revoke all on function public.is_team_manager(uuid) from public;
grant execute on function public.is_team_manager(uuid) to authenticated;

revoke all on function public.find_user_id_by_username(text) from public;
grant execute on function public.find_user_id_by_username(text) to authenticated;

drop policy if exists team_members_insert_owner on public.team_members;

create policy team_members_insert_manager
on public.team_members
for insert
to authenticated
with check (public.is_team_manager(team_id));