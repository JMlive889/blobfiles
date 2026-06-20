-- Section 2: basic RLS policies for public.users

alter table public.users enable row level security;

-- ---------------------------------------------------------------------------
-- SELECT: users can read their own profile
-- ---------------------------------------------------------------------------
create policy users_select_own
on public.users
for select
to authenticated
using (auth.uid() = id);

-- Optional (future): allow reading public fields of active users
-- create policy users_select_public_profiles
-- on public.users
-- for select
-- to authenticated
-- using (status = 'active');

-- ---------------------------------------------------------------------------
-- UPDATE: users can update their own profile only
-- ---------------------------------------------------------------------------
create policy users_update_own
on public.users
for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

-- Prevent clients from changing immutable identity columns (RLS cannot do this alone).
create or replace function public.users_prevent_immutable_column_changes()
returns trigger
language plpgsql
as $$
begin
  if new.id is distinct from old.id then
    raise exception 'Cannot change id';
  end if;

  if new.short_id is distinct from old.short_id then
    raise exception 'Cannot change short_id';
  end if;

  if new.anon_id is distinct from old.anon_id then
    raise exception 'Cannot change anon_id';
  end if;

  return new;
end;
$$;

create trigger users_prevent_immutable_column_changes
before update on public.users
for each row
execute function public.users_prevent_immutable_column_changes();

-- ---------------------------------------------------------------------------
-- INSERT: no client policy — profiles should be created via auth signup trigger
-- or service_role. To allow self-insert later, uncomment:
--
-- create policy users_insert_own
-- on public.users
-- for insert
-- to authenticated
-- with check (auth.uid() = id);
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- DELETE: intentionally no policy — use status = 'deleted' + deleted_at instead
-- ---------------------------------------------------------------------------