# Play Store Release Checklist

Checklist ini khusus untuk project PromoHunter Android dengan kondisi saat ini:

- package name: `com.punpun.promohunter`
- payment: masih `sandbox`
- Google Maps: API key Android sudah didukung lewat `android/local.properties`
- release signing: sudah ada wiring, tetapi belum aktif sampai `android/key.properties` dan `.jks` dibuat

## 1. Release Signing

- [ ] Buat folder keystore:

```powershell
New-Item -ItemType Directory -Force "C:\Users\Lenovo\.vscode\coding\project\Promo Hunter\keys"
```

- [ ] Generate release keystore:

```powershell
keytool -genkeypair -v -keystore "C:\Users\Lenovo\.vscode\coding\project\Promo Hunter\keys\promohunter-release.jks" -keyalg RSA -keysize 2048 -validity 10000 -alias promohunter
```

- [ ] Copy template key properties:

```powershell
Copy-Item "C:\Users\Lenovo\.vscode\coding\project\Promo Hunter\android\key.properties.example" "C:\Users\Lenovo\.vscode\coding\project\Promo Hunter\android\key.properties"
```

- [ ] Isi `android/key.properties` dengan password dan alias yang benar
- [ ] Simpan backup `.jks`, `storePassword`, `keyPassword`, dan `keyAlias`

## 2. Google Maps Android Key

- [ ] Pastikan `android/local.properties` punya:

```properties
MAPS_API_KEY=AIzaSyxxxxxxxxxxxxxxxxxxxx
```

- [ ] Ambil SHA-1 debug untuk testing lokal
- [ ] Ambil SHA-1 release atau Play App Signing untuk production
- [ ] Di Google Cloud, batasi API key untuk Android app:
  - package name `com.punpun.promohunter`
  - SHA-1 yang sesuai

## 3. Payment Sandbox Validation

Sebelum pindah ke production, pastikan semua alur sandbox ini lulus:

- [ ] QRIS sukses dan callback kembali ke app
- [ ] E-wallet sukses
- [ ] Virtual Account sukses
- [ ] Transfer Bank sukses
- [ ] Payment result screen muncul dari deep link Android
- [ ] Row status masuk ke `midtrans_payment_statuses`
- [ ] Coin / premium otomatis aktif setelah settlement

## 4. Store & Location Quality

- [ ] Toko-toko penting sudah punya `latitude` dan `longitude`
- [ ] `Gunakan lokasi saya` berhasil membaca lokasi user
- [ ] Promo otomatis menyesuaikan toko aktif terdekat
- [ ] Preview Google Maps muncul di detail toko
- [ ] Tombol `Buka Google Maps` bekerja

## 5. Build Release

- [ ] Jalankan:

```powershell
flutter clean
flutter pub get
flutter build appbundle --release
```

- [ ] Pastikan build berhasil tanpa fallback error
- [ ] Tes AAB/APK release di device Android nyata

## 6. Play Console Prep

- [ ] Siapkan ikon, deskripsi, screenshot, dan privacy policy
- [ ] Aktifkan Play App Signing
- [ ] Ambil SHA-1 dari `App integrity`
- [ ] Tambahkan SHA-1 Play ke Google Cloud API restriction
- [ ] Upload AAB ke internal testing dulu

## 7. Sebelum Production Payment

Saat ini project masih sandbox. Sebelum live:

- [ ] Siapkan endpoint invoice production Midtrans
- [ ] Siapkan notification URL production
- [ ] Pisahkan secret sandbox vs production
- [ ] Tes payment production dengan akun merchant production

## 8. Status Saat Ini

Yang masih belum selesai saat checklist ini dibuat:

- [ ] `android/key.properties` belum ada
- [ ] `keys/promohunter-release.jks` belum ada
- [ ] release signing masih fallback ke debug
- [ ] payment masih sandbox, belum production

