-- Section 2: basic RLS policies for public.user_badges

alter table public.user_badges enable row level security;

-- SELECT: users can read their own badges only
drop policy if exists user_badges_select_own on public.user_badges;

create policy user_badges_select_own
on public.user_badges
for select
to authenticated
using (auth.uid() = user_id);

-- Optional (future): allow reading public badge types on other users' profiles
-- create policy user_badges_select_public
-- on public.user_badges
-- for select
-- to authenticated
-- using (badge_type in ('member', 'curator', 'researcher', 'podcaster'));

-- No INSERT, UPDATE, or DELETE policies — managed by backend/admin
-- (service_role or SECURITY DEFINER functions).