# Notion Promo Import

Dokumen ini menjelaskan jalur import promo dari Notion ke PromoHunter lewat n8n.

## Status Saat Ini

- Flutter sudah punya tombol `Notion` di halaman admin `Kelola Promo`.
- Flutter mengirim request ke n8n dengan `import_source: notion`.
- n8n sudah punya router import source:
  - `web_scrape` masuk ke scraping web yang sudah berjalan.
  - `notion` masuk ke response setup Notion.
- Jika variable Notion belum ada, n8n mengembalikan pesan aman dan tidak membuat promo palsu.

## Variable n8n yang Dibutuhkan

Tambahkan di n8n `Variables`:

```text
NotionAPI=secret_xxx
DatabaseNotion=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

`DatabaseNotion` boleh berisi database ID mentah atau URL database Notion penuh. Workflow n8n akan mencoba mengekstrak ID database secara otomatis.

Variable Supabase yang tetap dipakai:

```text
SupabaseURL=https://ujltafrzoeeklcudihgm.supabase.co
Supabase_Service_Role_Key=service_role_key_supabase
Supabase_Storage_Bucket=promo-images
```

Jangan simpan token Notion atau service role Supabase di Flutter.

## Struktur Database Notion yang Disamakan dengan Supabase

Buat satu database Notion bernama `PromoHunter Promos`.

Database ini sengaja dibuat mirip format payload Supabase/RPC `upsert_promo_from_n8n`, bukan memakai `store_id` dan `category_id` langsung. Alasannya: di Notion admin lebih mudah mengisi nama toko dan nama kategori, lalu n8n/Supabase otomatis membuat atau mencari `stores.id` dan `categories.id`.

Kolom wajib:

```text
Product Name      Title
Promo Price       Number
Normal Price      Number
Store Name        Select atau Text
Category Name     Select atau Text
End Date          Date
Status            Select
```

Kolom tambahan yang disarankan:

```text
Brand             Text
Image             Files & media atau URL
Store Address     Text
City              Text
Google Maps URL   URL
Opening Hours     Text
Unit Size         Number
Unit Type         Select
Start Date        Date
Terms             Text
Source URL        URL
Is Active         Checkbox
```

Mapping Notion ke Supabase:

| Notion | Supabase / Payload |
| --- | --- |
| `Product Name` | `promos.product_name` |
| `Brand` | `promos.brand` |
| `Image` | `promos.image_url` setelah gambar diupload ke Storage |
| `Normal Price` | `promos.normal_price` |
| `Promo Price` | `promos.promo_price` |
| `Unit Size` | `promos.unit_size` |
| `Unit Type` | `promos.unit_type` |
| `Start Date` | `promos.start_date` |
| `End Date` | `promos.end_date` |
| `Terms` | `promos.terms` |
| `Source URL` | `promos.source_url` |
| `Is Active` | `promos.is_active` |
| `Store Name` | dicari/dibuat ke `stores.name`, lalu dipakai sebagai `promos.store_id` |
| `Store Address` | `stores.address` jika toko baru dibuat |
| `City` | `stores.city` jika toko baru dibuat |
| `Google Maps URL` | `stores.google_maps_url` jika toko baru dibuat |
| `Opening Hours` | `stores.opening_hours` jika toko baru dibuat |
| `Category Name` | dicari/dibuat ke `categories.name`, lalu dipakai sebagai `promos.category_id` |

Aturan default jika kolom kosong:

```text
Brand           -> sama dengan Store Name
Store Address   -> Sumber promo online
Category Name   -> Promo Online
Unit Size       -> 1
Unit Type       -> pcs
Start Date      -> tanggal hari ini
Terms           -> Diimpor dari Notion via n8n.
Is Active       -> true
```

Nilai `Status` yang disarankan:

```text
Draft
Ready
Synced
Error
```

n8n hanya boleh mengambil row dengan `Status = Ready`.

## Contoh Row Notion

```text
Product Name: Minyak Goreng Bimoli 2L
Brand: Bimoli
Store Name: Alfamart
Store Address: Alfamart Merdeka
Category Name: Minyak
Normal Price: 39000
Promo Price: 32900
Unit Size: 2
Unit Type: liter
Start Date: 2026-06-22
End Date: 2026-06-30
Terms: Berlaku selama persediaan masih ada.
Source URL: https://alfagift.id
Image: upload file atau URL gambar produk
Status: Ready
```

## Alur Import yang Diinginkan

```text
Admin isi promo di Notion
        |
        v
Status diubah menjadi Ready
        |
        v
Admin tekan tombol Notion di PromoHunter
        |
        v
n8n query Notion database
        |
        v
n8n download gambar dari kolom Image
        |
        v
n8n upload gambar ke Supabase Storage bucket promo-images
        |
        v
n8n insert/upsert stores, categories, promos
        |
        v
n8n update Status Notion menjadi Synced
```

## Kontrak Response n8n ke Flutter

Jika import berhasil direct ke Supabase:

```json
{
  "direct_insert": true,
  "inserted_to_supabase": true,
  "imported_from_notion": true,
  "inserted_count": 3,
  "source_name": "PromoHunter Notion Import",
  "message": "3 promo dari Notion berhasil disimpan ke Supabase."
}
```

Jika Notion belum siap:

```json
{
  "direct_insert": false,
  "inserted_to_supabase": false,
  "imported_from_notion": false,
  "notion_configured": false,
  "inserted_count": 0,
  "message": "Import Notion belum bisa dijalankan. Tambahkan variable Notion_API_Token dan Notion_Database_ID di n8n, lalu aktifkan cabang query Notion."
}
```

## Catatan Implementasi Lanjutan

Cabang Notion n8n berikutnya perlu menambahkan:

1. HTTP Request ke Notion database query.
2. Code node untuk normalisasi field Notion ke format PromoHunter.
3. HTTP Request untuk download gambar.
4. HTTP Request untuk upload gambar ke Supabase Storage.
5. RPC atau Supabase insert/upsert ke tabel `stores`, `categories`, dan `promos`.
6. HTTP Request update page Notion menjadi `Synced` atau `Error`.

Untuk MVP, jalur web scraping tetap aktif sebagai fallback stabil.

## Jika Muncul Error `Could not find database`

Artinya token Notion sudah terbaca, tetapi database belum dibagikan ke integration.

Solusinya:

1. Buka database Notion `PromoHunter Promos`.
2. Klik `Share` atau menu `...`.
3. Pilih `Invite` atau `Connections`.
4. Tambahkan integration yang dipakai token n8n. Pada test terakhir namanya `Samuel`.
5. Pastikan integration punya akses membaca database.
6. Jalankan ulang tombol `Notion` di halaman admin PromoHunter.
