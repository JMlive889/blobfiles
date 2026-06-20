-- Allow authenticated users to create their own public.users profile row once.

drop policy if exists users_insert_own on public.users;

create policy users_insert_own
on public.users
for insert
to authenticated
with check (auth.uid() = id);