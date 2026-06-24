-- PromoHunter n8n direct insert RPC
-- Run this in Supabase SQL Editor before enabling n8n direct insert.

create or replace function public.upsert_promo_from_n8n(payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_product_name text := nullif(trim(payload->>'product_name'), '');
  v_brand text := nullif(trim(payload->>'brand'), '');
  v_store_name text := coalesce(nullif(trim(payload->>'store_name'), ''), 'Promo Online');
  v_store_address text := coalesce(nullif(trim(payload->>'store_address'), ''), 'Sumber promo online');
  v_category_name text := coalesce(
    nullif(trim(payload->>'category_name'), ''),
    nullif(trim(payload->>'category'), ''),
    'Promo Online'
  );
  v_image_url text := coalesce(
    nullif(trim(payload->>'image_url'), ''),
    'https://images.unsplash.com/photo-1607083206968-13611e3d76db?w=1200'
  );
  v_normal_price numeric := coalesce(nullif(payload->>'normal_price', '')::numeric, 0);
  v_promo_price numeric := coalesce(nullif(payload->>'promo_price', '')::numeric, 0);
  v_unit_size numeric := coalesce(nullif(payload->>'unit_size', '')::numeric, 1);
  v_unit_type text := coalesce(nullif(trim(payload->>'unit_type'), ''), 'pcs');
  v_start_date date := coalesce(nullif(payload->>'start_date', '')::date, current_date);
  v_end_date date := coalesce(nullif(payload->>'end_date', '')::date, current_date + interval '14 days');
  v_terms text := coalesce(nullif(trim(payload->>'terms'), ''), 'Diimpor otomatis dari workflow n8n.');
  v_source_url text := coalesce(nullif(trim(payload->>'source_url'), ''), '');
  v_store_id bigint;
  v_category_id bigint;
  v_existing_id bigint;
  v_inserted_id bigint;
  v_discount_percent numeric;
begin
  if v_product_name is null then
    return jsonb_build_object(
      'direct_insert', true,
      'inserted_count', 0,
      'skipped_count', 1,
      'failed_count', 0,
      'status', 'skipped',
      'message', 'product_name kosong'
    );
  end if;

  if v_promo_price <= 0 then
    return jsonb_build_object(
      'direct_insert', true,
      'inserted_count', 0,
      'skipped_count', 1,
      'failed_count', 0,
      'status', 'skipped',
      'message', 'promo_price tidak valid'
    );
  end if;

  if v_normal_price <= 0 or v_normal_price < v_promo_price then
    v_normal_price := v_promo_price;
  end if;

  if v_end_date < current_date then
    return jsonb_build_object(
      'direct_insert', true,
      'inserted_count', 0,
      'skipped_count', 1,
      'failed_count', 0,
      'status', 'skipped',
      'message', 'promo expired'
    );
  end if;

  select id
    into v_store_id
    from stores
   where lower(name) = lower(v_store_name)
   order by id
   limit 1;

  if v_store_id is null then
    insert into stores (name, address, city, google_maps_url, opening_hours)
    values (
      v_store_name,
      v_store_address,
      'Indonesia',
      'https://maps.google.com/?q=' || replace(v_store_name, ' ', '+'),
      '08.00 - 22.00'
    )
    returning id into v_store_id;
  end if;

  select id
    into v_category_id
    from categories
   where lower(name) = lower(v_category_name)
   order by id
   limit 1;

  if v_category_id is null then
    insert into categories (name, icon)
    values (v_category_name, 'category')
    returning id into v_category_id;
  end if;

  select id
    into v_existing_id
    from promos
   where lower(product_name) = lower(v_product_name)
     and store_id = v_store_id
     and end_date = v_end_date
     and coalesce(source_url, '') = v_source_url
   order by id
   limit 1;

  if v_existing_id is not null then
    return jsonb_build_object(
      'direct_insert', true,
      'inserted_to_supabase', true,
      'inserted_count', 0,
      'skipped_count', 1,
      'failed_count', 0,
      'status', 'duplicate',
      'promo_id', v_existing_id,
      'message', 'promo sudah ada'
    );
  end if;

  v_discount_percent := case
    when v_normal_price > 0 then round(((v_normal_price - v_promo_price) / v_normal_price) * 100, 2)
    else 0
  end;

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
  values (
    v_store_id,
    v_category_id,
    v_product_name,
    coalesce(v_brand, v_store_name),
    v_image_url,
    v_normal_price,
    v_promo_price,
    v_unit_size,
    v_unit_type,
    v_discount_percent,
    v_start_date,
    v_end_date,
    v_terms,
    v_source_url,
    true
  )
  returning id into v_inserted_id;

  return jsonb_build_object(
    'direct_insert', true,
    'inserted_to_supabase', true,
    'inserted_count', 1,
    'skipped_count', 0,
    'failed_count', 0,
    'status', 'inserted',
    'promo_id', v_inserted_id,
    'message', 'promo berhasil disimpan'
  );
exception
  when others then
    return jsonb_build_object(
      'direct_insert', true,
      'inserted_to_supabase', false,
      'inserted_count', 0,
      'skipped_count', 0,
      'failed_count', 1,
      'status', 'error',
      'message', sqlerrm
    );
end;
$$;

grant execute on function public.upsert_promo_from_n8n(jsonb) to service_role;
