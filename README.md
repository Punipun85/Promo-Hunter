# PromoHunter

Scaffold project Flutter untuk aplikasi agregator promo supermarket/minimarket berdasarkan PRD, SRS, dan SDD yang sudah ditentukan.

## Status

Project ini berisi fondasi arsitektur aplikasi:

- struktur folder modular
- theme dan routing dasar
- model, provider, dan service layer
- sample data lokal untuk demo awal
- halaman utama, daftar promo, detail, favorit, reminder, kalkulator, toko, admin, dan profil
- schema SQL Supabase untuk setup backend

## Catatan penting

- Workspace ini belum memiliki tool `flutter`, jadi scaffold dibuat manual dan belum bisa dijalankan/diverifikasi dari CLI saat ini.
- `Supabase.initialize(...)` belum diaktifkan agar project tetap bisa dibuka tanpa kredensial.
- Service masih menggunakan mock/in-memory data untuk mempercepat development MVP.

## Setup berikutnya

1. Install Flutter SDK dan tambahkan ke PATH.
2. Jalankan `flutter pub get`.
3. Lengkapi URL dan anon key di `lib/config/supabase_config.dart`.
4. Aktifkan inisialisasi Supabase di `lib/main.dart`.
5. Jalankan schema SQL di Supabase.
6. Ganti mock service dengan query Supabase bertahap.

## Struktur

Lihat folder `lib/` dan file [sql/001_initial_schema.sql](/C:/Users/Lenovo/.vscode/coding/project/Promo%20Hunter/sql/001_initial_schema.sql).

