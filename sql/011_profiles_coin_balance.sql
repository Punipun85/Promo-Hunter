alter table public.profiles
add column if not exists coin_balance integer not null default 0;
