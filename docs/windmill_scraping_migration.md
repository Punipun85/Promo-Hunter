  # Windmill Scraping Migration

Dokumen ini memetakan flow scraping PromoHunter yang sebelumnya berjalan di n8n
ke arsitektur Windmill yang lebih cocok untuk job script, HTTP scraping, dan
upsert data ke Supabase.

Dokumen ini fokus pada jalur scraping/import promo. Payment tidak dibahas di
sini karena sudah dipisahkan ke:

- Activepieces untuk pembuatan invoice Midtrans
- Supabase Edge Function untuk Midtrans notification

## Tujuan

Target migrasi scraping adalah:

1. mengganti webhook scraping n8n dengan flow Windmill
2. mempertahankan kontrak request/response yang dipakai Flutter admin
3. memecah flow besar menjadi script kecil yang mudah dites
4. menjaga jalur upload gambar ke Supabase Storage
5. menjaga jalur import Notion sebagai cabang terpisah

## Sumber Workflow Lama

Workflow lama berasal dari export n8n:

```text
C:/Users/Lenovo/Downloads/AI Promo Scraper OpenAI Source + OpenAI Extract.json
```

Cabang yang benar-benar aktif saat ini bukan jalur OpenAI penuh, melainkan:

- webhook import PromoHunter
- router `import_source`
- pemilihan source aman berbasis daftar URL tetap
- fetch HTML
- ekstraksi promo sederhana dari HTML
- download gambar
- upload gambar ke Supabase Storage
- response kembali ke Flutter

Jalur OpenAI source discovery dan AI extraction ada di workflow lama, tetapi
beberapa node penting dalam jalur itu nonaktif. Karena itu migrasi awal ke
Windmill sebaiknya meniru jalur aman yang aktif sekarang, lalu OpenAI bisa
ditambahkan belakangan sebagai enhancement.

## Kontrak Input dari Flutter Admin

Webhook scraping saat ini menerima `POST` JSON dari Flutter admin ke path:

```text
promohunter-import-promos
```

Contoh payload umum:

```json
{
  "mode": "multi_source_web_scrape_with_supabase_insert",
  "import_source": "web_scrape",
  "preferred_source": "alfamart",
  "target_sources": ["alfamart"],
  "store_name": "Alfamart",
  "search_query": "promo minyak goreng alfamart juni 2026",
  "period": {
    "month": "2026-06"
  },
  "supabase_target": {
    "storage_bucket": "promo-images"
  }
}
```

Cabang Notion memakai:

```json
{
  "import_source": "notion"
}
```

## Kontrak Output yang Perlu Dipertahankan

Response sukses scraping web saat ini pada dasarnya berbentuk:

```json
{
  "direct_insert": false,
  "inserted_to_supabase": false,
  "source_name": "Suara Alfamart Promo",
  "message": "Promo berhasil diekstrak dan dikembalikan ke Flutter.",
  "promotions": [
    {
      "product_name": "Promo Minyak Goreng",
      "brand": "Alfamart",
      "image_url": "https://...",
      "original_image_url": "https://...",
      "normal_price": 39000,
      "promo_price": 32900,
      "unit_size": 1,
      "unit_type": "pcs",
      "store_name": "Alfamart",
      "store_address": "Sumber promo online",
      "category_name": "Minyak",
      "start_date": "2026-06-01",
      "end_date": "2026-06-30",
      "terms": "Promo dari sumber publik",
      "source_url": "https://..."
    }
  ]
}
```

Kalau upload gambar ke Storage berhasil, `image_url` harus menjadi public URL
Supabase Storage, bukan URL eksternal website sumber.

## Ringkasan Node n8n yang Aktif

### Jalur web scrape

1. `PromoHunter Import Webhook`
2. `Route Import Source`
3. `Select Safe Promo Source`
4. `Prepare Source URL`
5. `Fetch AI Discovered Promo HTML`
6. `Build PromoHunter Response`
7. `Prepare Promo Image Upload`
8. `Download Promo Image`
9. `Upload Promo Image to Supabase`
10. `Finalize PromoHunter Storage Response`

### Jalur Notion

1. `PromoHunter Import Webhook`
2. `Route Import Source`
3. `Query Notion Ready Promos`
4. `Normalize Notion Promo Rows`

### Jalur yang ada tetapi belum jadi prioritas migrasi

- `OpenAI Discover Promo Source`
- `Parse OpenAI Source URL`
- `Extract Current Month Promos`
- direct insert RPC path yang masih nonaktif

## Peta n8n ke Windmill

| n8n | Fungsi | Windmill yang disarankan |
| --- | --- | --- |
| `PromoHunter Import Webhook` | entry request admin | Flow trigger HTTP `flows/promohunter_import` |
| `Route Import Source` | pilih cabang `notion` vs `web_scrape` | script router `scripts/promos/route_import_source` |
| `Select Safe Promo Source` | pilih source URL tetap | script `scripts/promos/select_safe_source` |
| `Prepare Source URL` | normalisasi metadata source | digabung ke output `select_safe_source` |
| `Fetch AI Discovered Promo HTML` | ambil HTML halaman sumber | script `scripts/promos/fetch_html` |
| `Build PromoHunter Response` | ekstraksi promo sederhana dari HTML | script `scripts/promos/extract_promo_from_html` |
| `Prepare Promo Image Upload` | siapkan URL/path storage | script `scripts/promos/prepare_image_upload` |
| `Download Promo Image` | download binary image | script `scripts/promos/download_image` |
| `Upload Promo Image to Supabase` | upload ke bucket | script `scripts/promos/upload_image_to_supabase` |
| `Finalize PromoHunter Storage Response` | response akhir ke Flutter | script `scripts/promos/finalize_scrape_response` |
| `Query Notion Ready Promos` | query database Notion | script `scripts/notion/query_ready_promos` |
| `Normalize Notion Promo Rows` | map row Notion ke promo internal | script `scripts/notion/normalize_promo_rows` |

## Arsitektur Windmill yang Disarankan

### Flow utama

#### `flows/promohunter_import`

Flow HTTP ini menjadi pengganti webhook n8n. Input dan respons tetap kompatibel
dengan Flutter admin.

Alur:

1. baca body request
2. route berdasarkan `import_source`
3. jika `notion`
   - jalankan query Notion
   - normalisasi row
   - kembalikan hasil
4. jika `web_scrape` atau default
   - pilih source aman
   - fetch HTML
   - ekstrak promo
   - siapkan upload gambar
   - download gambar
   - upload ke Supabase
   - finalisasi response

### Script web scraping

#### `scripts/promos/route_import_source`

Input:

```json
{
  "body": {
    "import_source": "web_scrape"
  }
}
```

Output:

```json
{
  "import_source": "web_scrape",
  "is_notion": false
}
```

#### `scripts/promos/select_safe_source`

Tugas:

- meniru logika `Select Safe Promo Source`
- membaca `preferred_source`, `store_name`, `target_sources`, `search_query`
- memilih satu URL sumber dari daftar aman tetap

Output minimum:

```json
{
  "source_url": "https://...",
  "source_name": "Suara Alfamart Promo",
  "discovery_reason": "Matched preferred_source",
  "search_query_used": "promo minyak goreng alfamart juni 2026",
  "target_period_text": "2026-06"
}
```

Daftar source awal yang perlu dipindah apa adanya:

- Alfamart
- Indomaret
- Super Indo
- Hero

#### `scripts/promos/fetch_html`

Tugas:

- GET HTML dari `source_url`
- pakai `User-Agent` dan `Accept` browser-like
- ikuti redirect sampai 5 hop
- timeout 15 detik
- kembalikan HTML raw

Output:

```json
{
  "source_url": "https://...",
  "source_name": "Suara Alfamart Promo",
  "html": "<html>...</html>"
}
```

#### `scripts/promos/extract_promo_from_html`

Tugas:

- meniru logika `Build PromoHunter Response`
- ekstrak title/meta/image
- infer store dan category
- regex harga `Rp`
- buat satu promo default dari halaman

Output:

```json
{
  "direct_insert": false,
  "inserted_to_supabase": false,
  "source_name": "Suara Alfamart Promo",
  "message": "Promo berhasil diekstrak dari HTML.",
  "promotions": [
    {
      "product_name": "Promo Minyak Goreng",
      "brand": "Alfamart",
      "image_url": "https://source/image.jpg",
      "original_image_url": "https://source/image.jpg",
      "normal_price": 39000,
      "promo_price": 32900,
      "unit_size": 1,
      "unit_type": "pcs",
      "store_name": "Alfamart",
      "store_address": "Sumber promo online",
      "category_name": "Minyak",
      "start_date": "2026-06-01",
      "end_date": "2026-06-30",
      "terms": "Promo dari sumber publik",
      "source_url": "https://..."
    }
  ]
}
```

#### `scripts/promos/prepare_image_upload`

Tugas:

- tentukan `image_source_url`
- buat slug source dan product
- tentukan bucket/path/extension
- buat public URL target Supabase Storage

Output tambahan:

```json
{
  "image_source_url": "https://source/image.jpg",
  "storage_bucket": "promo-images",
  "storage_path": "n8n-promos/source-product-123.jpg",
  "storage_public_url": "https://.../storage/v1/object/public/promo-images/n8n-promos/source-product-123.jpg"
}
```

#### `scripts/promos/download_image`

Tugas:

- download binary image
- validasi content type diawali `image/`
- fallback ke image default jika perlu

Output:

- metadata mime type
- bytes atau temp file path

#### `scripts/promos/upload_image_to_supabase`

Tugas:

- upload binary ke Storage bucket `promo-images`
- pakai service role key
- set `x-upsert: true`

Environment yang dipakai:

```text
SUPABASE_URL
SUPABASE_SERVICE_ROLE_KEY
SUPABASE_STORAGE_BUCKET=promo-images
```

#### `scripts/promos/finalize_scrape_response`

Tugas:

- kalau upload berhasil, ganti `promo.image_url` ke public URL storage
- kalau gagal, pertahankan fallback/source image
- kembalikan response final yang masih kompatibel dengan Flutter

### Script Notion

#### `scripts/notion/query_ready_promos`

Tugas:

- query Notion database
- filter `Status == Ready`
- page size awal 10

Environment:

```text
NOTION_API_TOKEN
NOTION_DATABASE_ID
```

#### `scripts/notion/normalize_promo_rows`

Tugas:

- map row Notion ke format promo internal
- meniru `Normalize Notion Promo Rows`
- hasil akhirnya sejalan dengan payload promo Supabase/Flutter

Output:

```json
{
  "direct_insert": false,
  "inserted_to_supabase": false,
  "imported_from_notion": true,
  "source_name": "PromoHunter Notion Import",
  "promotions": [
    {
      "product_name": "Minyak Goreng Bimoli 2L",
      "brand": "Bimoli",
      "image_url": "https://...",
      "normal_price": 39000,
      "promo_price": 32900,
      "store_name": "Alfamart",
      "category_name": "Minyak",
      "end_date": "2026-06-30"
    }
  ]
}
```

## Struktur Folder Windmill yang Disarankan

```text
flows/
  promohunter_import

scripts/
  promos/
    route_import_source
    select_safe_source
    fetch_html
    extract_promo_from_html
    prepare_image_upload
    download_image
    upload_image_to_supabase
    finalize_scrape_response
  notion/
    query_ready_promos
    normalize_promo_rows
```

## Environment dan Secrets

Windmill sebaiknya menyimpan ini sebagai variables/secrets:

```text
SUPABASE_URL=https://ujltafrzoeeklcudihgm.supabase.co
SUPABASE_SERVICE_ROLE_KEY=...
SUPABASE_STORAGE_BUCKET=promo-images
NOTION_API_TOKEN=...
NOTION_DATABASE_ID=...
OPENAI_API_KEY=...        # hanya jika jalur OpenAI diaktifkan lagi
```

## Urutan Migrasi yang Disarankan

### Fase 1 - webhook dan web scrape aman

Bangun dulu:

1. `flows/promohunter_import`
2. `scripts/promos/route_import_source`
3. `scripts/promos/select_safe_source`
4. `scripts/promos/fetch_html`
5. `scripts/promos/extract_promo_from_html`

Target fase ini:

- Flutter admin sudah bisa memicu scraping lagi
- response promo kembali muncul
- belum perlu upload image ke Storage

### Fase 2 - upload gambar ke Supabase Storage

Bangun:

1. `prepare_image_upload`
2. `download_image`
3. `upload_image_to_supabase`
4. `finalize_scrape_response`

Target fase ini:

- `promos.image_url` menjadi URL public Supabase Storage
- tidak bergantung pada URL eksternal sumber

### Fase 3 - jalur Notion

Bangun:

1. `query_ready_promos`
2. `normalize_promo_rows`

Target fase ini:

- tombol import Notion tetap punya padanan di backend baru

### Fase 4 - enhancement opsional

Setelah stabil, baru pertimbangkan:

- source discovery berbasis OpenAI
- extraction berbasis LLM dari HTML
- direct insert ke Supabase via RPC
- multi-item extraction per halaman
- scheduler berkala di Windmill

## Hal yang Sengaja Tidak Dipindah Dulu

Untuk migrasi awal, jangan dulu memindahkan:

- node OpenAI yang saat ini nonaktif
- jalur direct insert RPC yang belum menjadi jalur utama
- eksperimen source discovery generatif

Alasannya:

- migrasi jadi jauh lebih cepat
- risiko lebih kecil
- kita meniru perilaku aktif saat ini dulu
- enhancement AI bisa ditambahkan setelah flow stabil

## Definisi Selesai Tahap Mapping

Tahap mapping dianggap selesai bila:

1. setiap node aktif n8n sudah punya padanan Windmill
2. kontrak input/output untuk Flutter terdokumentasi
3. daftar secret/env untuk Windmill sudah jelas
4. urutan migrasi per fase sudah jelas

Dengan dokumen ini, langkah berikutnya bukan lagi diskusi abstrak, tetapi
membangun script Windmill satu per satu sesuai peta di atas.
