-- Teams and team membership for BlobFiles.

-- ---------------------------------------------------------------------------
-- teams
-- ---------------------------------------------------------------------------
create table public.teams (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  owner_id uuid not null references public.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.teams is 'Collaborative teams; each team has one owner.';
comment on column public.teams.owner_id is 'User who owns and manages the team.';

create index teams_owner_id_idx on public.teams (owner_id);

create trigger teams_set_updated_at
before update on public.teams
for each row
execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- team_members
-- ---------------------------------------------------------------------------
create table public.team_members (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams (id) on delete cascade,
  user_id uuid not null references public.users (id) on delete cascade,
  role text not null default 'member' check (role in ('owner', 'admin', 'member')),
  joined_at timestamptz not null default now(),
  constraint team_members_team_user_unique unique (team_id, user_id)
);

comment on table public.team_members is 'Membership roster for teams.';
comment on column public.team_members.role is 'owner, admin, or member.';

create index team_members_user_id_idx on public.team_members (user_id);
create index team_members_team_id_idx on public.team_members (team_id);

-- Add the owner to team_members when a team is created.
create or replace function public.teams_add_owner_membership()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.team_members (team_id, user_id, role)
  values (new.id, new.owner_id, 'owner');
  return new;
end;
$$;

create trigger teams_add_owner_membership
after insert on public.teams
for each row
execute function public.teams_add_owner_membership();

-- ---------------------------------------------------------------------------
-- RLS helpers (SECURITY DEFINER — bypass RLS for membership checks)
-- ---------------------------------------------------------------------------
create or replace function public.is_team_member(p_team_id uuid)
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
  );
$$;

create or replace function public.is_team_owner(p_team_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1
    from public.teams
    where id = p_team_id
      and owner_id = auth.uid()
  );
$$;

revoke all on function public.is_team_member(uuid) from public;
grant execute on function public.is_team_member(uuid) to authenticated;

revoke all on function public.is_team_owner(uuid) from public;
grant execute on function public.is_team_owner(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------
alter table public.teams enable row level security;
alter table public.team_members enable row level security;

-- teams: members (and owners) can read; only owners can write.
drop policy if exists teams_select_member on public.teams;
create policy teams_select_member
on public.teams
for select
to authenticated
using (
  owner_id = auth.uid()
  or public.is_team_member(id)
);

drop policy if exists teams_insert_owner on public.teams;
create policy teams_insert_owner
on public.teams
for insert
to authenticated
with check (owner_id = auth.uid());

drop policy if exists teams_update_owner on public.teams;
create policy teams_update_owner
on public.teams
for update
to authenticated
using (owner_id = auth.uid())
with check (owner_id = auth.uid());

drop policy if exists teams_delete_owner on public.teams;
create policy teams_delete_owner
on public.teams
for delete
to authenticated
using (owner_id = auth.uid());

-- team_members: members can read roster; only owners manage membership.
drop policy if exists team_members_select_member on public.team_members;
create policy team_members_select_member
on public.team_members
for select
to authenticated
using (public.is_team_member(team_id));

drop policy if exists team_members_insert_owner on public.team_members;
create policy team_members_insert_owner
on public.team_members
for insert
to authenticated
with check (public.is_team_owner(team_id));

drop policy if exists team_members_update_owner on public.team_members;
create policy team_members_update_owner
on public.team_members
for update
to authenticated
using (public.is_team_owner(team_id))
with check (public.is_team_owner(team_id));

drop policy if exists team_members_delete_owner on public.team_members;
create policy team_members_delete_owner
on public.team_members
for delete
to authenticated
using (public.is_team_owner(team_id));