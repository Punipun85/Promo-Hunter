-- Allows signed-in admins to manage catalog content while keeping public reads.
-- Run this after sql/002_rls_policies.sql in the Supabase SQL editor.

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'admin'
  );
$$;

drop policy if exists "stores_admin_insert" on stores;
create policy "stores_admin_insert"
on stores
for insert
to authenticated
with check (public.is_admin());

drop policy if exists "stores_admin_update" on stores;
create policy "stores_admin_update"
on stores
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "stores_admin_delete" on stores;
create policy "stores_admin_delete"
on stores
for delete
to authenticated
using (public.is_admin());

drop policy if exists "categories_admin_insert" on categories;
create policy "categories_admin_insert"
on categories
for insert
to authenticated
with check (public.is_admin());

drop policy if exists "categories_admin_update" on categories;
create policy "categories_admin_update"
on categories
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "categories_admin_delete" on categories;
create policy "categories_admin_delete"
on categories
for delete
to authenticated
using (public.is_admin());

drop policy if exists "promos_admin_insert" on promos;
create policy "promos_admin_insert"
on promos
for insert
to authenticated
with check (public.is_admin());

drop policy if exists "promos_admin_update" on promos;
create policy "promos_admin_update"
on promos
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "promos_admin_delete" on promos;
create policy "promos_admin_delete"
on promos
for delete
to authenticated
using (public.is_admin());
