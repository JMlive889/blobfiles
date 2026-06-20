-- Section 2: User Configuration & Tiers — user_badges table

create table public.user_badges (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (id) on delete cascade,
  badge_type text not null,
  level integer not null default 1 check (level between 1 and 3),
  earned_at timestamptz not null default now(),
  source text check (source is null or source in ('automatic', 'manual', 'paid')),
  unique (user_id, badge_type)
);

comment on table public.user_badges is 'Badges earned by users (member, curator, researcher, podcaster, etc.)';
comment on column public.user_badges.badge_type is 'Badge identifier, e.g. member, curator, researcher, podcaster';
comment on column public.user_badges.level is 'Progress level (1–3) for dot indicator UI';
comment on column public.user_badges.source is 'How the badge was awarded: automatic, manual, or paid';

create index user_badges_user_id_idx on public.user_badges (user_id);

alter table public.user_badges enable row level security;

-- Users can read their own badges only.
create policy user_badges_select_own
on public.user_badges
for select
to authenticated
using (auth.uid() = user_id);

-- No INSERT, UPDATE, or DELETE policies — managed by backend/admin (service_role or SECURITY DEFINER functions).