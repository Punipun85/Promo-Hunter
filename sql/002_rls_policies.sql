alter table stores enable row level security;
alter table categories enable row level security;
alter table promos enable row level security;
alter table profiles enable row level security;
alter table favorites enable row level security;
alter table reminders enable row level security;
alter table shopping_lists enable row level security;
alter table price_comparisons enable row level security;

drop policy if exists "stores_public_read" on stores;
create policy "stores_public_read"
on stores
for select
to anon, authenticated
using (true);

drop policy if exists "categories_public_read" on categories;
create policy "categories_public_read"
on categories
for select
to anon, authenticated
using (true);

drop policy if exists "promos_public_read" on promos;
create policy "promos_public_read"
on promos
for select
to anon, authenticated
using (true);

drop policy if exists "profiles_select_own" on profiles;
create policy "profiles_select_own"
on profiles
for select
to authenticated
using (auth.uid() = id);

drop policy if exists "profiles_insert_own" on profiles;
create policy "profiles_insert_own"
on profiles
for insert
to authenticated
with check (auth.uid() = id);

drop policy if exists "profiles_update_own" on profiles;
create policy "profiles_update_own"
on profiles
for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists "favorites_select_own" on favorites;
create policy "favorites_select_own"
on favorites
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "favorites_insert_own" on favorites;
create policy "favorites_insert_own"
on favorites
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "favorites_delete_own" on favorites;
create policy "favorites_delete_own"
on favorites
for delete
to authenticated
using (auth.uid() = user_id);

drop policy if exists "reminders_select_own" on reminders;
create policy "reminders_select_own"
on reminders
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "reminders_insert_own" on reminders;
create policy "reminders_insert_own"
on reminders
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "reminders_update_own" on reminders;
create policy "reminders_update_own"
on reminders
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "reminders_delete_own" on reminders;
create policy "reminders_delete_own"
on reminders
for delete
to authenticated
using (auth.uid() = user_id);

drop policy if exists "shopping_lists_select_own" on shopping_lists;
create policy "shopping_lists_select_own"
on shopping_lists
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "shopping_lists_insert_own" on shopping_lists;
create policy "shopping_lists_insert_own"
on shopping_lists
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "shopping_lists_update_own" on shopping_lists;
create policy "shopping_lists_update_own"
on shopping_lists
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "shopping_lists_delete_own" on shopping_lists;
create policy "shopping_lists_delete_own"
on shopping_lists
for delete
to authenticated
using (auth.uid() = user_id);

drop policy if exists "price_comparisons_select_own" on price_comparisons;
create policy "price_comparisons_select_own"
on price_comparisons
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "price_comparisons_insert_own" on price_comparisons;
create policy "price_comparisons_insert_own"
on price_comparisons
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "price_comparisons_delete_own" on price_comparisons;
create policy "price_comparisons_delete_own"
on price_comparisons
for delete
to authenticated
using (auth.uid() = user_id);
