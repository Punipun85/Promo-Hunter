insert into stores (name, address, city, google_maps_url, opening_hours)
select *
from (
  values
    ('Indomaret Sudirman', 'Jl. Sudirman No. 8', 'Jakarta', 'https://maps.google.com/?q=Jl.+Sudirman+No.+8+Jakarta', '07.00 - 22.00'),
    ('Alfamart Merdeka', 'Jl. Merdeka No. 15', 'Bandung', 'https://maps.google.com/?q=Jl.+Merdeka+No.+15+Bandung', '24 jam'),
    ('Super Indo Melati', 'Jl. Melati No. 22', 'Surabaya', 'https://maps.google.com/?q=Jl.+Melati+No.+22+Surabaya', '08.00 - 21.00')
) as seed(name, address, city, google_maps_url, opening_hours)
where not exists (
  select 1 from stores s where s.name = seed.name
);

insert into categories (name, icon)
select *
from (
  values
    ('Beras', 'rice'),
    ('Minyak', 'oil'),
    ('Susu', 'milk'),
    ('Deterjen', 'soap'),
    ('Snack', 'snack'),
    ('Minuman', 'drink')
) as seed(name, icon)
where not exists (
  select 1 from categories c where c.name = seed.name
);

insert into promos (
  store_id,
  category_id,
  product_name,
  brand,
  image_url,
  normal_price,
  promo_price,
  unit_size,
  unit_type,
  discount_percent,
  start_date,
  end_date,
  terms,
  source_url,
  is_active
)
select
  (select id from stores where name = seed.store_name),
  (select id from categories where name = seed.category_name),
  seed.product_name,
  seed.brand,
  seed.image_url,
  seed.normal_price,
  seed.promo_price,
  seed.unit_size,
  seed.unit_type,
  round(((seed.normal_price - seed.promo_price) / seed.normal_price) * 100, 2),
  current_date - seed.start_offset,
  current_date + seed.end_offset,
  seed.terms,
  seed.source_url,
  true
from (
  values
    ('Indomaret Sudirman', 'Minyak', 'Minyak Goreng Hemat 2L', 'SunFresh', 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=1200', 32000::numeric, 28900::numeric, 2::numeric, 'liter', 1, 2, 'Berlaku selama stok tersedia.', 'https://example.com/promos/minyak-hemat-2l'),
    ('Super Indo Melati', 'Beras', 'Beras Premium 5kg', 'Makmur', 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=1200', 79000::numeric, 69900::numeric, 5::numeric, 'kg', 2, 4, 'Maksimal 2 produk per transaksi.', 'https://example.com/promos/beras-premium-5kg'),
    ('Alfamart Merdeka', 'Susu', 'Susu UHT Cokelat 1L', 'Milko', 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=1200', 21000::numeric, 16900::numeric, 1::numeric, 'liter', 1, 1, 'Khusus member.', 'https://example.com/promos/susu-uht-cokelat-1l'),
    ('Indomaret Sudirman', 'Deterjen', 'Deterjen Cair 800ml', 'CleanPro', 'https://images.unsplash.com/photo-1563453392212-326f5e854473?w=1200', 24000::numeric, 19900::numeric, 800::numeric, 'ml', 3, 5, 'Tidak berlaku digabung voucher lain.', 'https://example.com/promos/deterjen-cair-800ml'),
    ('Alfamart Merdeka', 'Snack', 'Keripik Kentang Family Pack', 'Crunchy', 'https://images.unsplash.com/photo-1512152272829-e3139592d56f?w=1200', 18500::numeric, 14900::numeric, 1::numeric, 'pack', 1, 6, 'Promo weekend.', 'https://example.com/promos/keripik-kentang-family-pack'),
    ('Super Indo Melati', 'Minuman', 'Teh Botol 450ml', 'FreshTea', 'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=1200', 7000::numeric, 5500::numeric, 450::numeric, 'ml', 1, 2, 'Beli 2 lebih hemat.', 'https://example.com/promos/teh-botol-450ml'),
    ('Indomaret Sudirman', 'Susu', 'Susu Bubuk Anak 800g', 'NutriKids', 'https://images.unsplash.com/photo-1517448931760-9bf4414148c5?w=1200', 98000::numeric, 84500::numeric, 800::numeric, 'gram', 2, 7, 'Berlaku untuk semua pelanggan.', 'https://example.com/promos/susu-bubuk-anak-800g'),
    ('Super Indo Melati', 'Minyak', 'Minyak Goreng 1L', 'Golden Drop', 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=1200', 18000::numeric, 15900::numeric, 1::numeric, 'liter', 1, 3, 'Harga khusus akhir pekan.', 'https://example.com/promos/minyak-goreng-1l'),
    ('Alfamart Merdeka', 'Beras', 'Beras Ramos 2.5kg', 'Sawah Indah', 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=1200', 43000::numeric, 38900::numeric, 2.5::numeric, 'kg', 1, 5, 'Stok terbatas setiap hari.', 'https://example.com/promos/beras-ramos-25kg'),
    ('Indomaret Sudirman', 'Minuman', 'Air Mineral 600ml', 'AquaFresh', 'https://images.unsplash.com/photo-1564419320461-6870880221ad?w=1200', 4500::numeric, 3500::numeric, 600::numeric, 'ml', 1, 2, 'Maksimal 6 botol per transaksi.', 'https://example.com/promos/air-mineral-600ml')
) as seed(
  store_name,
  category_name,
  product_name,
  brand,
  image_url,
  normal_price,
  promo_price,
  unit_size,
  unit_type,
  start_offset,
  end_offset,
  terms,
  source_url
)
where not exists (
  select 1
  from promos p
  where p.product_name = seed.product_name
    and p.brand = seed.brand
);
