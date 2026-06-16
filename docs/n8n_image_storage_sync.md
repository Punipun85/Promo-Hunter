# n8n Sync: Promo + Supabase Storage Images

Dokumen ini dipakai untuk mode sync admin PromoHunter dengan alur:

```text
Flutter Admin Sync
  -> n8n webhook
  -> scrape promo + image_url
  -> n8n download image
  -> upload image ke Supabase Storage bucket promo-images
  -> upsert stores/categories/promos
  -> Flutter refresh data
```

## Webhook

Gunakan method `POST` dan path:

```text
promohunter-import-promos
```

Flutter akan mengirim payload berisi:

```json
{
  "mode": "multi_source_web_scrape_with_supabase_insert",
  "sync_strategy": "n8n_download_images_upload_storage_insert_supabase",
  "supabase_target": {
    "storage_bucket": "promo-images",
    "image_upload": {
      "enabled": true,
      "folder": "n8n-promos",
      "save_public_url_to": "promos.image_url"
    }
  }
}
```

## Credentials n8n

Simpan sebagai credential/environment di n8n, jangan di Flutter:

```text
SUPABASE_URL=https://ujltafrzoeeklcudihgm.supabase.co
SUPABASE_SERVICE_ROLE_KEY=...
SUPABASE_STORAGE_BUCKET=promo-images
```

Service role dipakai hanya di n8n/backend agar bisa insert database dan upload storage tanpa membuka policy publik untuk write.

## Format Promo Internal

Setiap item promo hasil scraping sebaiknya dinormalisasi menjadi:

```json
{
  "product_name": "Minyak Goreng 2L",
  "brand": "Bimoli",
  "normal_price": 38000,
  "promo_price": 32000,
  "store_name": "Indomaret",
  "store_address": "Gerai Indomaret terdekat",
  "category": "Minyak",
  "unit_size": 2,
  "unit_type": "liter",
  "start_date": "2026-06-01",
  "end_date": "2026-06-30",
  "terms": "Selama persediaan masih ada.",
  "source_url": "https://example.com/promo",
  "image_url": "https://source.example/image.jpg"
}
```

## Upload Gambar

Untuk setiap promo:

1. Ambil `image_url` dari hasil scraping.
2. Download binary gambar dengan HTTP Request.
3. Tentukan extension dari `content-type`:
   - `image/png` -> `.png`
   - `image/webp` -> `.webp`
   - selain itu -> `.jpg`
4. Upload ke Supabase Storage:

```text
POST {SUPABASE_URL}/storage/v1/object/promo-images/n8n-promos/{slug}-{timestamp}.jpg
Authorization: Bearer {SUPABASE_SERVICE_ROLE_KEY}
apikey: {SUPABASE_SERVICE_ROLE_KEY}
Content-Type: image/jpeg
```

5. Simpan public URL ke `promos.image_url`:

```text
{SUPABASE_URL}/storage/v1/object/public/promo-images/n8n-promos/{filename}
```

Jika download/upload gagal, pakai fallback:

```text
https://images.unsplash.com/photo-1607083206968-13611e3d76db?w=1200
```

## Upsert Database

Urutan aman:

1. Upsert `stores` berdasarkan `name`.
2. Upsert `categories` berdasarkan `name`.
3. Insert promo ke `promos` dengan `store_id` dan `category_id`.
4. Hindari duplikat dengan kombinasi:

```text
product_name + store_id + end_date + source_url
```

## Response ke Flutter

Jika n8n sudah menulis langsung ke Supabase, response wajib memberi tanda `direct_insert: true`:

```json
{
  "direct_insert": true,
  "inserted_to_supabase": true,
  "inserted_count": 12,
  "skipped_count": 3,
  "failed_count": 0,
  "source_name": "PromoHunter n8n Storage Sync",
  "message": "Promo dan gambar berhasil disimpan ke Supabase."
}
```

Dengan response ini, Flutter tidak akan insert ulang. Flutter hanya menjalankan refresh data dari Supabase.
