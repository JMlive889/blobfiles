-- Enforce case-insensitive username uniqueness on public.users

drop index if exists public.users_username_idx;

create unique index users_username_lower_idx
  on public.users (lower(username));

comment on index public.users_username_lower_idx is
  'Case-insensitive unique usernames (e.g. "John" and "john" cannot coexist)';