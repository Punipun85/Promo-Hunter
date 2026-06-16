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
- Sync n8n dapat diarahkan untuk upload gambar promo ke Supabase Storage; lihat [docs/n8n_image_storage_sync.md](/C:/Users/Lenovo/.vscode/coding/project/Promo%20Hunter/docs/n8n_image_storage_sync.md).

## Setup Supabase

1. Jalankan schema awal di [sql/001_initial_schema.sql](/C:/Users/Lenovo/.vscode/coding/project/Promo%20Hunter/sql/001_initial_schema.sql).
2. Jalankan policy dasar di [sql/002_rls_policies.sql](/C:/Users/Lenovo/.vscode/coding/project/Promo%20Hunter/sql/002_rls_policies.sql).
3. Jalankan trigger sinkron profil di [sql/006_profiles_sync.sql](/C:/Users/Lenovo/.vscode/coding/project/Promo%20Hunter/sql/006_profiles_sync.sql) agar user Auth otomatis punya row `profiles`.
4. Jalankan policy admin di [sql/007_admin_content_policies.sql](/C:/Users/Lenovo/.vscode/coding/project/Promo%20Hunter/sql/007_admin_content_policies.sql) agar akun `role = 'admin'` bisa insert/update/delete `stores`, `categories`, dan `promos`.
5. Jalankan seed tambahan toko di [sql/008_seed_more_stores.sql](/C:/Users/Lenovo/.vscode/coding/project/Promo%20Hunter/sql/008_seed_more_stores.sql) agar halaman toko berisi lebih banyak chain supermarket/minimarket.
6. Pastikan `lib/config/supabase_config.dart` berisi project URL API dan anon key yang benar.
7. Buat minimal data awal:
   - `stores`
   - `categories`
   - `promos`
8. Register user baru dari aplikasi agar row `profiles` ikut terbentuk.
9. Untuk membuat admin manual, ubah role di Supabase SQL Editor:

```sql
update profiles
set role = 'admin'
where email = 'email-admin-kamu@example.com';
```

Jika tombol Sync n8n menampilkan `new row violates row-level security policy`, jalankan ulang [sql/007_admin_content_policies.sql](/C:/Users/Lenovo/.vscode/coding/project/Promo%20Hunter/sql/007_admin_content_policies.sql) dan pastikan akun yang sedang login memiliki `profiles.role = 'admin'`.

## Verifikasi terakhir

- `flutter analyze` lolos
- `flutter test` lolos
- `flutter build web` berhasil

## Langkah berikutnya

1. Tuntaskan `NotificationService` dengan `flutter_local_notifications`.
2. Hubungkan CRUD admin promo/store/category langsung ke data Supabase penuh.
3. Tambahkan seed data demo untuk presentasi UAS.
