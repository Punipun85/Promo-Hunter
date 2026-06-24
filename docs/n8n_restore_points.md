# n8n Restore Points

Dokumen ini mencatat titik aman workflow n8n PromoHunter sebelum eksperimen direct insert.

## Restore Point 2026-06-22

- Workflow ID: `h6DLxaqBoAFdzOx9`
- Workflow name: `AI Promo Scraper OpenAI Source + OpenAI Extract`
- Active version ID: `6dd10f1a-cc6a-4bae-bfd1-802af38a2a03`
- Mode aman: n8n mencari promo lalu mengembalikan data ke Flutter.
- Node akhir aktif: `Build PromoHunter Response`
- Response marker:

```json
{
  "direct_insert": false,
  "inserted_to_supabase": false
}
```

## Restore Point 2026-06-22 Source Routing Fix

- Workflow ID: `h6DLxaqBoAFdzOx9`
- Workflow name: `AI Promo Scraper OpenAI Source + OpenAI Extract`
- Active version ID: `37f04705-3096-490d-9e43-2ab99f7c3b79`
- Mode aman: n8n memakai daftar sumber tetap dan mengembalikan data ke Flutter.
- Perbaikan: node `Select Safe Promo Source` membaca `search_query`, `search_queries`, `target_sources`, `preferred_source`, dan `store_name`.
- Verifikasi:

```text
Alfamart -> Suara Alfamart Promo
Indomaret -> Disway Indomaret Promo
Super Indo -> Suara Super Indo Promo
```

## Restore Point 2026-06-22 Storage Upload Attempt

- Workflow ID: `h6DLxaqBoAFdzOx9`
- Workflow name: `AI Promo Scraper OpenAI Source + OpenAI Extract`
- Active version ID: `b98c3e33-cf74-42b7-8ede-00a7364ab7f1`
- Mode aman: n8n download gambar promo, mencoba upload ke Supabase Storage, lalu tetap mengembalikan data ke Flutter.
- Fallback: jika upload storage gagal, response tetap `200 OK` dan `promotions[0].image_url` memakai URL gambar sumber.
- Status test terakhir: upload gagal karena `SUPABASE_SERVICE_ROLE_KEY` di n8n tidak berisi JWT Supabase valid (`Invalid Compact JWS`).

## Restore Point 2026-06-22 Storage Upload Success

- Workflow ID: `h6DLxaqBoAFdzOx9`
- Workflow name: `AI Promo Scraper OpenAI Source + OpenAI Extract`
- Active version ID: `93b14e63-a1c2-484f-b0c9-4de6d9bca844`
- Mode aman: n8n download gambar promo, upload ke Supabase Storage bucket `promo-images`, lalu mengembalikan data ke Flutter.
- Variables aktif: `SupabaseURL`, `Supabase_Service_Role_Key`, `Supabase_Storage_Bucket`.
- Verifikasi:

```text
image_uploaded_to_storage: true
image_upload_status: 200
image_uploaded_count: 1
image_failed_count: 0
Content-Type: image/jpeg
```

## Restore Point 2026-06-22 Import Source Router

- Workflow ID: `h6DLxaqBoAFdzOx9`
- Workflow name: `AI Promo Scraper OpenAI Source + OpenAI Extract`
- Active version ID: `36e7f0ad-4098-4428-80a8-6990b1e4a9e8`
- Perubahan: webhook sekarang melewati node `Route Import Source`.
- `import_source: web_scrape` tetap masuk ke jalur scraping web dan upload gambar Supabase Storage.
- `import_source: notion` masuk ke node `Build Notion Setup Response`.
- Tujuan: request Notion tidak diam-diam mengambil data web scraping jika variable Notion belum siap.
- Verifikasi Notion belum configured:

```text
notion_configured: false
inserted_count: 0
message: Import Notion belum bisa dijalankan. Tambahkan variable Notion_API_Token dan Notion_Database_ID di n8n, lalu aktifkan cabang query Notion.
```

- Verifikasi web scraping tetap jalan:

```text
image_uploaded_to_storage: true
image_upload_status: 200
image_uploaded_count: 1
source_name: Suara Alfamart Promo
```

## Restore Point 2026-06-22 Notion Query Branch

- Workflow ID: `h6DLxaqBoAFdzOx9`
- Workflow name: `AI Promo Scraper OpenAI Source + OpenAI Extract`
- Active version ID: `c67d8bd6-06a6-441d-89fb-283f3b463ed7`
- Perubahan: cabang `import_source: notion` sekarang menjalankan node `Query Notion Ready Promos` dan `Normalize Notion Promo Rows`.
- Variable Notion yang dibaca: `NotionAPI` dan `DatabaseNotion`.
- `DatabaseNotion` boleh berupa URL database Notion penuh atau database ID.
- Status test terakhir: Notion API merespons, tetapi database belum di-share ke integration `Samuel`.
- Error terakhir:

```text
Could not find database with ID: 387f86ed-37af-805e-b8bf-f6f096b71273.
Make sure the relevant pages and databases are shared with your integration "Samuel".
```

- Tindakan berikutnya: buka database Notion, share/invite integration `Samuel`, lalu test ulang tombol `Notion`.

## Cara Restore Manual

Jika direct insert bermasalah:

1. Buka workflow n8n `h6DLxaqBoAFdzOx9`.
2. Pastikan alur terakhir adalah:

```text
Fetch AI Discovered Promo HTML -> Build PromoHunter Response
```

3. Node `Build PromoHunter Response` harus mengembalikan `direct_insert: false`.
4. Jika ada node direct insert tambahan, disable node tersebut atau putuskan koneksinya.
5. Publish workflow.
6. Test webhook:

```text
POST https://punpunroro.app.n8n.cloud/webhook/promohunter-import-promos
```

Response aman harus `200 OK` dan berisi array `promotions`.
