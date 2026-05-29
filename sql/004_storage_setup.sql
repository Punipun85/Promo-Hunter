insert into storage.buckets (id, name, public)
values ('promo-images', 'promo-images', true)
on conflict (id) do nothing;

create policy "Public read promo images"
on storage.objects
for select
to public
using (bucket_id = 'promo-images');

create policy "Authenticated upload promo images"
on storage.objects
for insert
to authenticated
with check (bucket_id = 'promo-images');

create policy "Authenticated update promo images"
on storage.objects
for update
to authenticated
using (bucket_id = 'promo-images')
with check (bucket_id = 'promo-images');

create policy "Authenticated delete promo images"
on storage.objects
for delete
to authenticated
using (bucket_id = 'promo-images');
