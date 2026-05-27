# PromoHunter

Project Flutter untuk aplikasi agregator promo supermarket/minimarket berdasarkan PRD, SRS, dan SDD yang sudah ditentukan.

## Status

Project ini sudah memiliki fondasi MVP yang bisa dijalankan:

- struktur folder modular
- theme dan routing dasar
- model, provider, dan service layer
- Supabase auth dan inisialisasi app
- fallback data lokal untuk mode demo
- halaman home, promo list/detail, favorit, reminder, shopping list, kalkulator, toko, admin, dan profil
- schema SQL Supabase untuk setup backend

## Catatan penting

- `Supabase.initialize(...)` sudah aktif di `lib/main.dart`.
- Service memakai Supabase jika tersedia, lalu fallback ke cache/data lokal bila backend belum siap.
- `favorites`, `reminders`, dan `shopping_lists` sudah disiapkan untuk sinkron per-user.
- Local notification masih berupa stub service dan perlu dituntaskan untuk notifikasi perangkat sungguhan.

## Setup Supabase

1. Jalankan schema awal di [sql/001_initial_schema.sql](/C:/Users/Lenovo/.vscode/coding/project/Promo%20Hunter/sql/001_initial_schema.sql).
2. Jalankan policy dasar di [sql/002_rls_policies.sql](/C:/Users/Lenovo/.vscode/coding/project/Promo%20Hunter/sql/002_rls_policies.sql).
3. Pastikan `lib/config/supabase_config.dart` berisi project URL API dan anon key yang benar.
4. Buat minimal data awal:
   - `stores`
   - `categories`
   - `promos`
5. Register user baru dari aplikasi agar row `profiles` ikut terbentuk.

## Verifikasi terakhir

- `flutter analyze` lolos
- `flutter test` lolos
- `flutter build web` berhasil

## Langkah berikutnya

1. Tuntaskan `NotificationService` dengan `flutter_local_notifications`.
2. Hubungkan CRUD admin promo/store/category langsung ke data Supabase penuh.
3. Tambahkan seed data demo untuk presentasi UAS.
