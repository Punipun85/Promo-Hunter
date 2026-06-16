insert into stores (
  name,
  address,
  city,
  google_maps_url,
  opening_hours,
  latitude,
  longitude
)
select *
from (
  values
    ('Hypermart', 'Gerai Hypermart terdekat', 'Indonesia', 'https://maps.google.com/?q=Hypermart', '10.00 - 22.00', -6.1767::double precision, 106.7906::double precision),
    ('Transmart', 'Gerai Transmart terdekat', 'Indonesia', 'https://maps.google.com/?q=Transmart', '10.00 - 22.00', -6.2431::double precision, 106.8448::double precision),
    ('Lotte Mart', 'Gerai Lotte Mart terdekat', 'Indonesia', 'https://maps.google.com/?q=Lotte+Mart', '09.00 - 22.00', -6.2271::double precision, 106.8331::double precision),
    ('Farmers Market', 'Gerai Farmers Market terdekat', 'Indonesia', 'https://maps.google.com/?q=Farmers+Market', '08.00 - 22.00', -6.2440::double precision, 106.7990::double precision),
    ('Ranch Market', 'Gerai Ranch Market terdekat', 'Indonesia', 'https://maps.google.com/?q=Ranch+Market', '08.00 - 22.00', -6.2088::double precision, 106.8200::double precision),
    ('Grand Lucky', 'Gerai Grand Lucky terdekat', 'Indonesia', 'https://maps.google.com/?q=Grand+Lucky+Superstore', '08.00 - 22.00', -6.2364::double precision, 106.7815::double precision),
    ('Hero Supermarket', 'Gerai Hero Supermarket terdekat', 'Indonesia', 'https://maps.google.com/?q=Hero+Supermarket', '08.00 - 22.00', -6.2297::double precision, 106.8140::double precision),
    ('Klik Indomaret', 'Layanan online Klik Indomaret', 'Indonesia', 'https://maps.google.com/?q=Klik+Indomaret', '24 jam', -6.2000::double precision, 106.8167::double precision),
    ('Alfagift', 'Layanan online Alfagift', 'Indonesia', 'https://maps.google.com/?q=Alfagift', '24 jam', -6.2091::double precision, 106.8459::double precision)
) as seed(
  name,
  address,
  city,
  google_maps_url,
  opening_hours,
  latitude,
  longitude
)
where not exists (
  select 1 from stores s where lower(s.name) = lower(seed.name)
);

update stores
set
  address = case
    when address is null or address = '' or address = 'Sumber promo dari n8n'
    then 'Gerai ' || name || ' terdekat'
    else address
  end,
  city = coalesce(nullif(city, ''), 'Indonesia'),
  google_maps_url = case
    when google_maps_url is null or google_maps_url = ''
    then 'https://maps.google.com/?q=' || replace(name, ' ', '+')
    else google_maps_url
  end,
  opening_hours = coalesce(nullif(opening_hours, ''), '08.00 - 22.00'),
  latitude = coalesce(
    latitude,
    case
      when lower(name) like '%alfamart%' then -6.2091
      when lower(name) like '%super indo%' then -6.2245
      when lower(name) like '%hypermart%' then -6.1767
      when lower(name) like '%transmart%' then -6.2431
      when lower(name) like '%lotte%' then -6.2271
      when lower(name) like '%farmers%' then -6.2440
      when lower(name) like '%ranch%' then -6.2088
      when lower(name) like '%grand lucky%' then -6.2364
      when lower(name) like '%hero%' then -6.2297
      else -6.2000
    end
  ),
  longitude = coalesce(
    longitude,
    case
      when lower(name) like '%alfamart%' then 106.8459
      when lower(name) like '%super indo%' then 106.8098
      when lower(name) like '%hypermart%' then 106.7906
      when lower(name) like '%transmart%' then 106.8448
      when lower(name) like '%lotte%' then 106.8331
      when lower(name) like '%farmers%' then 106.7990
      when lower(name) like '%ranch%' then 106.8200
      when lower(name) like '%grand lucky%' then 106.7815
      when lower(name) like '%hero%' then 106.8140
      else 106.8167
    end
  )
where name in (
  'Indomaret',
  'Alfamart',
  'Super Indo',
  'Hypermart',
  'Transmart',
  'Lotte Mart',
  'Farmers Market',
  'Ranch Market',
  'Grand Lucky',
  'Hero Supermarket',
  'Klik Indomaret',
  'Alfagift'
);
