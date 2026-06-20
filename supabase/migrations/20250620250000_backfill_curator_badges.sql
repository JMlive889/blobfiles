-- One-time backfill: grant Curator badge (level 1) to existing public.users rows.

insert into public.user_badges (user_id, badge_type, level, source)
select id, 'curator', 1, 'automatic'
from public.users
on conflict (user_id, badge_type) do nothing;