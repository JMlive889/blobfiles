-- Let teammates read each other's basic profile fields for team rosters.

drop policy if exists users_select_team_members on public.users;

create policy users_select_team_members
on public.users
for select
to authenticated
using (
  exists (
    select 1
    from public.team_members viewer
    join public.team_members teammate
      on viewer.team_id = teammate.team_id
    where viewer.user_id = auth.uid()
      and teammate.user_id = users.id
  )
);