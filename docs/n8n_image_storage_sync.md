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
      "required": true,
      "folder": "n8n-promos",
      "save_public_url_to": "promos.image_url",
      "source_image_field": "original_image_url",
      "fallback_image_url": "https://images.unsplash.com/photo-1607083206968-13611e3d76db?w=1200"
    }
  },
  "limits": {
    "max_total_promos": 12,
    "max_promos_per_source": 2,
    "max_pages_per_source": 1,
    "max_image_download_seconds": 8,
    "max_image_size_mb": 3,
    "prefer_response_under_seconds": 45
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
  "original_image_url": "https://source.example/image.jpg"
}
```

## Upload Gambar

Untuk setiap promo:

1. Ambil gambar produk dari halaman yang sama dengan `source_url`.
2. Prioritaskan `og:image`, schema product image, atau `img` terdekat dengan nama produk.
3. Simpan URL gambar asli sebagai `original_image_url`.
4. Download binary gambar dengan HTTP Request.
5. Tentukan extension dari `content-type`:
   - `image/png` -> `.png`
   - `image/webp` -> `.webp`
   - selain itu -> `.jpg`
6. Upload ke Supabase Storage:

```text
POST {SUPABASE_URL}/storage/v1/object/promo-images/n8n-promos/{slug}-{timestamp}.jpg
Authorization: Bearer {SUPABASE_SERVICE_ROLE_KEY}
apikey: {SUPABASE_SERVICE_ROLE_KEY}
Content-Type: image/jpeg
```

7. Simpan public URL ke `promos.image_url`:

```text
{SUPABASE_URL}/storage/v1/object/public/promo-images/n8n-promos/{filename}
```

Jika download/upload gagal, pakai fallback:

```text
https://images.unsplash.com/photo-1607083206968-13611e3d76db?w=1200
```

`promos.image_url` tidak boleh kosong. Jika gambar asli gagal diambil, n8n tetap harus download fallback image, upload fallback tersebut ke Supabase Storage, lalu menyimpan public URL Supabase Storage ke `promos.image_url`.

Aturan penting:

- `promos.image_url` harus berupa URL public Supabase Storage dari bucket `promo-images`, bukan URL eksternal website sumber.
- Jangan simpan response HTML, redirect loop, 403/404, atau file non-gambar sebagai `image_url`.
- Validasi hasil download dengan `content-type` yang diawali `image/`.
- Jika workflow mendekati 45 detik, hentikan scraping dan respons dengan hasil parsial valid agar Flutter tidak timeout.

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
  "image_uploaded_count": 10,
  "image_fallback_count": 2,
  "message": "Promo dan gambar berhasil disimpan ke Supabase."
}
```

Dengan response ini, Flutter tidak akan insert ulang. Flutter hanya menjalankan refresh data dari Supabase.

## Direct Insert Aman via RPC

Untuk direct insert yang rapi, jalankan migration:

```text
sql/009_n8n_direct_insert_rpc.sql
```

Fungsi RPC yang dibuat:

```text
public.upsert_promo_from_n8n(payload jsonb)
```

Kelebihan jalur RPC:

- Validasi `product_name`, harga, dan tanggal expired dilakukan di database.
- Store dan category otomatis dibuat jika belum ada.
- Dedupe dilakukan sebelum insert promo.
- Response selalu berisi `inserted_count`, `skipped_count`, dan `failed_count`.

Endpoint RPC:

```text
POST {SUPABASE_URL}/rest/v1/rpc/upsert_promo_from_n8n
```

Body:

```json
{
  "payload": {
    "product_name": "Promo Minyak Goreng",
    "brand": "Alfamart",
    "image_url": "https://...",
    "normal_price": 69900,
    "promo_price": 12700,
    "unit_size": 1,
    "unit_type": "pcs",
    "store_name": "Alfamart",
    "store_address": "Sumber promo online",
    "category_name": "Minyak",
    "start_date": "2026-06-22",
    "end_date": "2026-06-30",
    "terms": "Promo dari sumber publik",
    "source_url": "https://..."
  }
}
```

Credential yang dibutuhkan untuk node HTTP Request RPC:

```text
HTTP Custom Auth atau credential custom yang menyimpan dua header:
apikey: {SUPABASE_SERVICE_ROLE_KEY}
Authorization: Bearer {SUPABASE_SERVICE_ROLE_KEY}
```

Tambahkan header non-secret ini di node HTTP Request:

```text
Content-Type: application/json
Accept: application/json
```

Catatan: credential `supabaseApi` bawaan n8n cocok untuk node Supabase row CRUD, tetapi tidak diterima oleh HTTP Request node untuk memanggil RPC. Untuk RPC, buat credential HTTP/custom auth khusus yang menyimpan kedua header secret di atas, atau gunakan Supabase node CRUD dengan alur store/category/promo yang lebih panjang.
