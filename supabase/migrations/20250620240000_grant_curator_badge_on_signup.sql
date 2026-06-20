-- Grant every new public.users row the Curator badge (level 1) automatically.

create or replace function public.grant_curator_badge_on_user_create()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.user_badges (user_id, badge_type, level, source)
  values (new.id, 'curator', 1, 'automatic')
  on conflict (user_id, badge_type) do nothing;

  return new;
end;
$$;

drop trigger if exists users_grant_curator_badge on public.users;

create trigger users_grant_curator_badge
after insert on public.users
for each row
execute function public.grant_curator_badge_on_user_create();