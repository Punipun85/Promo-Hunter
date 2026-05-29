# PRD Aplikasi Flutter: PromoHunter

## 1. Nama Produk

**PromoHunter**

## 2. Deskripsi Singkat

PromoHunter adalah aplikasi mobile berbasis Flutter yang berfungsi sebagai **aggregator informasi diskon, katalog promo, dan kupon belanja supermarket/minimarket terdekat**. Aplikasi ini membantu pengguna menemukan promo kebutuhan pokok harian, membandingkan harga produk antar toko, serta mendapatkan pengingat sebelum masa berlaku promo atau kupon berakhir.

Project ini cocok untuk UAS karena memiliki fitur listing data, filter, notifikasi, kalkulator harga, dan integrasi API/scraping sederhana.

---

## 3. Tujuan Produk

Tujuan utama PromoHunter adalah:

1. Membantu pengguna menemukan promo supermarket/minimarket dengan cepat.
2. Menampilkan katalog diskon produk kebutuhan pokok harian.
3. Memberikan pengingat masa berlaku promo atau kupon.
4. Membantu pengguna membandingkan harga produk per satuan, seperti per gram, ml, liter, atau pcs.
5. Membantu pengguna menghemat pengeluaran belanja bulanan.
6. Menjadi aplikasi utilitas belanja harian yang mudah digunakan.

---

## 4. Target Pengguna

### 4.1 Ibu Rumah Tangga

Pengguna yang sering mencari promo kebutuhan pokok untuk belanja mingguan atau bulanan.

### 4.2 Mahasiswa

Pengguna yang ingin belanja hemat dan membandingkan harga produk dengan budget terbatas.

### 4.3 Pekerja Kantoran

Pengguna yang ingin mengetahui promo supermarket terdekat tanpa harus membuka banyak aplikasi atau katalog.

### 4.4 Masyarakat Umum

Pengguna yang aktif mencari diskon, kupon, dan promo produk harian.

---

## 5. Masalah yang Ingin Diselesaikan

Saat ini, informasi promo sering tersebar di banyak tempat seperti Instagram, website supermarket, aplikasi marketplace, atau katalog digital. Pengguna harus membuka banyak sumber untuk membandingkan promo.

PromoHunter menyelesaikan masalah tersebut dengan mengumpulkan informasi promo dalam satu aplikasi, menampilkan masa berlaku promo, dan membantu pengguna menghitung harga produk paling murah berdasarkan satuan.

---

## 6. Ruang Lingkup Fitur

### 6.1 Listing Katalog Promo

Aplikasi menampilkan daftar katalog promo dari berbagai minimarket dan supermarket.

Contoh sumber toko:

- Indomaret
- Alfamart
- Super Indo
- Hypermart
- Transmart
- Lotte Mart
- Farmers Market

Data yang ditampilkan:

- Nama produk
- Gambar produk
- Harga normal
- Harga promo
- Persentase diskon
- Nama toko
- Lokasi toko
- Tanggal mulai promo
- Tanggal akhir promo
- Kategori produk

Contoh kategori:

- Beras
- Minyak goreng
- Susu
- Makanan ringan
- Minuman
- Sabun
- Deterjen
- Produk bayi
- Produk rumah tangga

### 6.2 Detail Promo Produk

Pengguna dapat membuka detail promo untuk melihat informasi lengkap produk.

Isi halaman detail:

- Gambar produk
- Nama produk
- Brand
- Harga normal
- Harga setelah diskon
- Jumlah diskon
- Masa berlaku promo
- Nama toko penyedia promo
- Syarat dan ketentuan
- Tombol simpan promo
- Tombol lihat lokasi toko
- Tombol bagikan promo

### 6.3 Filter dan Pencarian Promo

Pengguna dapat mencari promo berdasarkan kata kunci.

Fitur filter:

- Filter berdasarkan toko
- Filter berdasarkan kategori
- Filter berdasarkan diskon terbesar
- Filter berdasarkan harga termurah
- Filter berdasarkan promo yang hampir berakhir
- Filter berdasarkan lokasi terdekat
- Filter berdasarkan produk favorit

Contoh pencarian:

- `minyak goreng`
- `beras`
- `susu`
- `deterjen`
- `promo Indomaret`
- `diskon Alfamart`

### 6.4 Pengingat Masa Berlaku Promo

Aplikasi memberikan notifikasi sebelum promo atau kupon berakhir.

Contoh pengingat:

- Promo berakhir hari ini
- Promo berakhir besok
- Kupon diskon akan kedaluwarsa dalam 3 jam
- Promo minyak goreng di Alfamart segera berakhir

Fitur ini menggunakan package:

```yaml
flutter_local_notifications
```

Alur fitur:

1. Pengguna membuka detail promo.
2. Pengguna menekan tombol “Ingatkan Saya”.
3. Sistem menyimpan promo ke daftar pengingat.
4. Aplikasi mengirim notifikasi sebelum masa berlaku berakhir.

### 6.5 Simpan Promo Favorit

Pengguna dapat menyimpan promo yang menarik.

Fitur:

- Tambah ke favorit
- Hapus dari favorit
- Lihat daftar promo tersimpan
- Urutkan promo favorit berdasarkan tanggal kedaluwarsa
- Tandai promo yang sudah digunakan

### 6.6 Kalkulator Perbandingan Harga per Satuan

Fitur ini digunakan untuk membandingkan harga produk berdasarkan satuan unit.

Contoh kasus:

Produk A:

- Minyak goreng 1 liter
- Harga Rp16.000

Produk B:

- Minyak goreng 2 liter
- Harga Rp30.000

Aplikasi menghitung harga per liter:

- Produk A = Rp16.000/liter
- Produk B = Rp15.000/liter

Hasil: Produk B lebih murah.

Satuan yang didukung:

- Gram
- Kilogram
- Mililiter
- Liter
- Pcs
- Sachet
- Pack

Input kalkulator:

- Nama produk
- Harga produk
- Ukuran produk
- Satuan
- Nama toko

Output:

- Harga per satuan
- Produk termurah
- Selisih harga
- Rekomendasi pilihan hemat

### 6.7 Lokasi Toko Terdekat

Aplikasi menampilkan daftar toko terdekat yang memiliki promo.

Data toko:

- Nama toko
- Alamat
- Jarak dari pengguna
- Jam buka
- Daftar promo aktif
- Tombol buka rute di Google Maps

Package yang dapat digunakan:

```yaml
url_launcher
```

Untuk versi MVP, cukup gunakan tombol buka Google Maps berdasarkan link lokasi toko.

### 6.8 Data Scraping / Import Promo

Karena project ini bertema **Data Scraping Flow**, data promo bisa didapat dari beberapa cara.

Untuk UAS, lebih aman menggunakan salah satu dari opsi berikut:

#### Opsi 1: Data Manual dari Database

Admin memasukkan data promo secara manual ke Supabase.

Cocok untuk project UAS karena lebih mudah dan stabil.

#### Opsi 2: Import dari JSON

Data promo disimpan dalam file JSON, lalu aplikasi membaca data tersebut.

Cocok untuk demo offline.

#### Opsi 3: Scraping Sederhana

Backend mengambil data dari sumber katalog promo yang tersedia secara publik.

Catatan: scraping harus memperhatikan izin website, struktur halaman, dan aturan penggunaan data.

---

## 7. Role Pengguna

| Role | Hak Akses |
| --- | --- |
| Guest | Melihat promo dan mencari katalog |
| User | Simpan favorit, buat pengingat, gunakan kalkulator |
| Admin | Tambah, edit, hapus promo, kelola toko dan kategori |

---

## 8. Halaman Aplikasi Flutter

### 8.1 Splash Screen

Menampilkan logo PromoHunter dan tagline.

Contoh tagline:

**“Cari promo. Bandingkan harga. Belanja lebih hemat.”**

### 8.2 Onboarding Page

Berisi 3 slide:

1. Temukan promo supermarket terdekat.
2. Simpan promo favorit dan dapatkan pengingat.
3. Bandingkan harga per satuan agar belanja lebih hemat.

### 8.3 Home Page

Isi halaman:

- Search bar promo
- Banner promo hari ini
- Kategori produk
- Promo populer
- Promo hampir berakhir
- Toko terdekat
- Bottom navigation

### 8.4 Promo List Page

Menampilkan daftar promo dalam bentuk card.

Isi card:

- Gambar produk
- Nama produk
- Harga normal
- Harga promo
- Badge diskon
- Nama toko
- Tanggal promo berakhir
- Tombol favorit

### 8.5 Promo Detail Page

Menampilkan informasi lengkap promo.

Isi halaman:

- Gambar produk
- Nama produk
- Brand
- Harga normal
- Harga promo
- Persentase diskon
- Nama toko
- Masa berlaku
- Syarat dan ketentuan
- Tombol simpan favorit
- Tombol buat pengingat
- Tombol buka lokasi toko

### 8.6 Favorite Promo Page

Menampilkan daftar promo yang disimpan pengguna.

Fitur:

- Lihat promo favorit
- Hapus promo favorit
- Tandai promo sudah digunakan
- Urutkan berdasarkan masa berlaku

### 8.7 Price Calculator Page

Halaman kalkulator perbandingan harga.

Input produk pertama:

- Nama produk
- Harga
- Ukuran
- Satuan

Input produk kedua:

- Nama produk
- Harga
- Ukuran
- Satuan

Output:

- Harga per satuan produk pertama
- Harga per satuan produk kedua
- Produk yang lebih hemat
- Selisih harga

### 8.8 Store Page

Menampilkan daftar supermarket dan minimarket.

Data yang ditampilkan:

- Nama toko
- Alamat toko
- Jarak toko
- Jumlah promo aktif
- Tombol lihat promo
- Tombol buka rute

### 8.9 Notification Reminder Page

Menampilkan daftar promo yang memiliki pengingat.

Isi:

- Nama produk
- Nama toko
- Tanggal promo berakhir
- Status pengingat
- Tombol hapus pengingat

### 8.10 Admin Dashboard

Khusus admin.

Fitur:

- Tambah promo
- Edit promo
- Hapus promo
- Kelola toko
- Kelola kategori
- Upload gambar produk
- Update masa berlaku promo

---

## 9. Struktur Database Supabase

### 9.1 Tabel `profiles`

```sql
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  email text not null,
  role text not null default 'user' check (role in ('user', 'admin')),
  created_at timestamp default now()
);
```

### 9.2 Tabel `stores`

```sql
create table stores (
  id bigint generated by default as identity primary key,
  name text not null,
  address text,
  city text,
  latitude double precision,
  longitude double precision,
  google_maps_url text,
  opening_hours text,
  created_at timestamp default now()
);
```

### 9.3 Tabel `categories`

```sql
create table categories (
  id bigint generated by default as identity primary key,
  name text not null,
  icon text,
  created_at timestamp default now()
);
```

### 9.4 Tabel `promos`

```sql
create table promos (
  id bigint generated by default as identity primary key,
  store_id bigint references stores(id) on delete cascade,
  category_id bigint references categories(id) on delete set null,
  product_name text not null,
  brand text,
  image_url text,
  normal_price numeric not null,
  promo_price numeric not null,
  unit_size numeric,
  unit_type text,
  discount_percent numeric,
  start_date date,
  end_date date,
  terms text,
  source_url text,
  is_active boolean default true,
  created_at timestamp default now()
);
```

### 9.5 Tabel `favorites`

```sql
create table favorites (
  id bigint generated by default as identity primary key,
  user_id uuid references profiles(id) on delete cascade,
  promo_id bigint references promos(id) on delete cascade,
  created_at timestamp default now(),
  unique(user_id, promo_id)
);
```

### 9.6 Tabel `reminders`

```sql
create table reminders (
  id bigint generated by default as identity primary key,
  user_id uuid references profiles(id) on delete cascade,
  promo_id bigint references promos(id) on delete cascade,
  reminder_time timestamp not null,
  is_notified boolean default false,
  created_at timestamp default now()
);
```

### 9.7 Tabel `price_comparisons`

```sql
create table price_comparisons (
  id bigint generated by default as identity primary key,
  user_id uuid references profiles(id) on delete cascade,
  product_a_name text not null,
  product_a_price numeric not null,
  product_a_size numeric not null,
  product_a_unit text not null,
  product_b_name text not null,
  product_b_price numeric not null,
  product_b_size numeric not null,
  product_b_unit text not null,
  cheaper_product text,
  created_at timestamp default now()
);
```

---

## 10. Rekomendasi Package Flutter

```yaml
dependencies:
  flutter:
    sdk: flutter

  supabase_flutter: ^2.0.0
  provider: ^6.0.0
  dio: ^5.0.0
  cached_network_image: ^3.3.0
  flutter_local_notifications: ^17.0.0
  url_launcher: ^6.2.0
  intl: ^0.19.0
```

| Package | Fungsi |
| --- | --- |
| `supabase_flutter` | Auth, database, dan storage |
| `provider` | State management |
| `dio` | Ambil data dari API/backend |
| `cached_network_image` | Menampilkan gambar produk lebih cepat |
| `flutter_local_notifications` | Notifikasi masa berlaku promo |
| `url_launcher` | Membuka Google Maps atau link katalog |
| `intl` | Format rupiah dan tanggal |

---

## 11. Alur Utama Aplikasi

### 11.1 Alur User Melihat Promo

1. User membuka aplikasi.
2. User masuk ke halaman home.
3. User mencari produk atau memilih kategori.
4. Aplikasi menampilkan daftar promo.
5. User membuka detail promo.
6. User dapat menyimpan promo atau membuka lokasi toko.

### 11.2 Alur User Membuat Pengingat

1. User membuka detail promo.
2. User menekan tombol “Ingatkan Saya”.
3. User memilih waktu pengingat.
4. Data disimpan ke tabel `reminders`.
5. Sistem mengirim notifikasi sebelum promo berakhir.

### 11.3 Alur User Membandingkan Harga

1. User membuka halaman kalkulator.
2. User memasukkan data produk A.
3. User memasukkan data produk B.
4. Sistem menghitung harga per satuan.
5. Sistem menampilkan produk yang lebih murah.

Rumus:

```text
harga_per_satuan = harga_produk / ukuran_produk
```

Contoh:

```text
Rp30.000 / 2 liter = Rp15.000 per liter
```

### 11.4 Alur Admin Mengelola Promo

1. Admin login.
2. Admin masuk ke dashboard.
3. Admin menambah data toko.
4. Admin menambah data kategori.
5. Admin menambah promo baru.
6. Admin mengatur tanggal mulai dan akhir promo.
7. Promo tampil di halaman user.

---

## 12. UI/UX Requirements

### Warna Utama

- Hijau: promo, hemat, fresh
- Biru: kepercayaan dan informasi
- Kuning/oranye: diskon dan highlight
- Putih: background utama

### Gaya Tampilan

- Modern
- Simple
- Informatif
- Banyak menggunakan card
- Badge diskon terlihat jelas
- Harga promo harus lebih menonjol daripada harga normal
- Tanggal berakhir promo harus mudah terlihat

### Komponen UI

- Search bar
- Category chips
- Promo card
- Discount badge
- Price tag
- Countdown promo
- Favorite button
- Reminder button
- Bottom navigation bar

---

## 13. MVP / Fitur Minimal

Untuk versi awal project UAS, fitur minimal yang harus dibuat:

1. Login dan register.
2. Home page.
3. Listing katalog promo.
4. Detail promo.
5. Filter berdasarkan kategori.
6. Simpan promo favorit.
7. Pengingat masa berlaku promo.
8. Kalkulator harga per satuan.
9. Daftar toko.
10. Admin tambah/edit/hapus promo sederhana.

---

## 14. Fitur Tambahan Setelah MVP

Fitur lanjutan:

1. Scraping otomatis dari website katalog.
2. Integrasi lokasi GPS pengguna.
3. Rekomendasi promo berdasarkan produk favorit.
4. Push notification dari server.
5. Barcode scanner produk.
6. Perbandingan harga lebih dari 2 produk.
7. Riwayat belanja hemat.
8. Share promo ke WhatsApp.
9. Dark mode.
10. Export daftar belanja.

---

## 15. Acceptance Criteria

Aplikasi dianggap selesai apabila:

1. User dapat melihat daftar promo.
2. User dapat mencari promo berdasarkan nama produk.
3. User dapat memfilter promo berdasarkan kategori.
4. User dapat membuka detail promo.
5. User dapat menyimpan promo ke favorit.
6. User dapat membuat pengingat promo.
7. Notifikasi lokal dapat muncul sebelum promo berakhir.
8. User dapat membandingkan harga produk per satuan.
9. Admin dapat menambah, mengedit, dan menghapus promo.
10. Data promo tersimpan di Supabase.

---

## 16. Prompt untuk Codex / AI Coding

```text
Buatkan aplikasi Flutter bernama PromoHunter.

PromoHunter adalah aplikasi aggregator info diskon dan katalog promosi supermarket/minimarket terdekat. Aplikasi ini membantu pengguna menemukan promo kebutuhan pokok harian, menyimpan promo favorit, mendapatkan pengingat sebelum promo berakhir, dan membandingkan harga produk per satuan unit.

Gunakan Supabase sebagai backend untuk authentication, database, dan storage.

Gunakan package:
- supabase_flutter
- provider
- dio
- cached_network_image
- flutter_local_notifications
- url_launcher
- intl

Fitur aplikasi:
1. Splash screen.
2. Onboarding page.
3. Login dan register menggunakan Supabase Auth.
4. Role user: user dan admin.
5. Home page dengan search bar, banner promo, kategori produk, promo populer, dan promo hampir berakhir.
6. Promo list page untuk menampilkan katalog promo dari supermarket/minimarket.
7. Promo detail page berisi gambar produk, nama produk, brand, harga normal, harga promo, diskon, nama toko, masa berlaku, syarat dan ketentuan.
8. Favorite page untuk menyimpan promo favorit.
9. Reminder page untuk menampilkan promo yang diberi pengingat.
10. Local notification untuk mengingatkan user sebelum promo berakhir.
11. Price calculator page untuk membandingkan harga produk per satuan seperti gram, kilogram, ml, liter, pcs, dan pack.
12. Store page untuk menampilkan daftar toko, alamat, promo aktif, dan tombol buka lokasi Google Maps menggunakan url_launcher.
13. Admin dashboard untuk tambah, edit, hapus promo, toko, dan kategori.
14. Gunakan cached_network_image untuk gambar produk.
15. Gunakan provider untuk state management.
16. Gunakan Supabase query untuk CRUD tabel profiles, stores, categories, promos, favorites, reminders, dan price_comparisons.

Struktur folder:
lib/
- main.dart
- app.dart
- config/
- models/
- services/
- providers/
- screens/
- widgets/
- utils/

Desain UI:
- Modern, clean, dan cocok untuk aplikasi belanja hemat.
- Warna utama hijau, biru, putih, dan aksen kuning/oranye.
- Gunakan card rounded, badge diskon, progress/countdown promo, bottom navigation bar, dan tombol CTA yang jelas.

Buat kode Flutter lengkap, modular, clean, dan mudah dikembangkan.
```

---

## 17. Prompt untuk Membuat UI di Stitch / AI Design

```text
Buat desain aplikasi mobile Flutter bernama PromoHunter.

PromoHunter adalah aplikasi aggregator info diskon dan katalog promosi supermarket/minimarket terdekat. Tujuannya membantu pengguna menemukan promo kebutuhan pokok harian, menyimpan promo favorit, mendapatkan pengingat sebelum promo berakhir, dan membandingkan harga produk per satuan.

Warna utama:
- Hijau untuk kesan hemat dan fresh
- Biru untuk informasi dan kepercayaan
- Putih untuk background bersih
- Kuning/oranye untuk badge promo dan diskon

Buat halaman:
1. Splash screen dengan logo PromoHunter.
2. Onboarding 3 halaman.
3. Login page.
4. Register page.
5. Home page dengan search bar, banner promo hari ini, kategori produk, promo populer, promo hampir berakhir, dan toko terdekat.
6. Promo list page dengan card produk, gambar, harga normal dicoret, harga promo, badge diskon, nama toko, dan tanggal promo berakhir.
7. Promo detail page dengan gambar produk besar, harga promo, harga normal, masa berlaku, toko, syarat ketentuan, tombol favorit, tombol ingatkan saya, dan tombol buka lokasi toko.
8. Favorite promo page.
9. Reminder page.
10. Price calculator page untuk membandingkan harga produk per gram/ml/liter/pcs.
11. Store page berisi daftar supermarket/minimarket dan tombol lihat promo.
12. Admin dashboard sederhana untuk kelola promo.

Gunakan style modern, clean, rounded card, bottom navigation, discount badge, search bar, category chips, dan CTA button yang jelas.
```
