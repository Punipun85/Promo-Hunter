# Android Release And SHA-1 Setup

Dokumen ini untuk project PromoHunter Android yang saat ini memakai:

- Package name: `com.punpun.promohunter`
- Sandbox payment flow: Midtrans sandbox via Activepieces + Supabase notification

## 1. Status Sekarang

Saat ini project sudah punya wiring release keystore, tetapi akan fallback ke debug signing kalau file `android/key.properties` belum diisi.

Artinya:

- `flutter run` dan `flutter run --release` masih bisa dipakai untuk tes lokal
- payment sandbox tetap bisa diuji
- tapi ini belum siap untuk upload final ke Play Store sampai release keystore milikmu dipasang

## 2. Package Name Android

Package name Android yang aktif sekarang:

```text
com.punpun.promohunter
```

Sudah dipakai di:

- `android/app/build.gradle.kts`
- `android/app/src/main/kotlin/com/punpun/promohunter/MainActivity.kt`

Kalau nanti package name ini diubah lagi, maka:

- API key Google Maps Android restriction juga harus ikut diubah
- SHA-1 restriction juga harus dibuat ulang untuk package baru

## 3. SHA-1 Untuk Google Maps API

Untuk Android apps restriction di Google Cloud, kamu butuh:

- `Package name`: `com.punpun.promohunter`
- `SHA-1 certificate fingerprint`

### A. SHA-1 Debug

Pakai ini untuk:

- `flutter run`
- build debug
- pengujian lokal

Jalankan:

```powershell
keytool -list -v -alias androiddebugkey -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android -keypass android
```

Lalu cari baris:

```text
SHA1: XX:XX:XX:XX:...
```

Itu yang dimasukkan ke Google Cloud.

### B. SHA-1 Release

Pakai ini untuk APK/AAB release milikmu sendiri.

Kalau nanti kamu punya release keystore sendiri, jalankan:

```powershell
keytool -list -v -alias YOUR_ALIAS -keystore "C:\path\to\your-release-keystore.jks"
```

Contoh:

```powershell
keytool -list -v -alias promohunter -keystore "C:\keys\promohunter-release.jks"
```

### C. SHA-1 Play Store

Kalau nanti upload ke Google Play dan memakai Play App Signing:

1. buka Play Console
2. masuk ke `App integrity`
3. lihat `App signing key certificate`
4. ambil `SHA-1`

Itu berbeda dari debug SHA-1 dan bisa berbeda juga dari upload key milikmu.

## 4. Cara Isi Google Cloud API Restriction

Di Google Cloud Console:

1. buka `APIs & Services`
2. buka `Credentials`
3. pilih API key untuk Google Maps
4. pada `Application restrictions`, pilih `Android apps`
5. tambahkan:

```text
Package name: com.punpun.promohunter
SHA-1: <isi fingerprint yang sesuai>
```

Biasanya sebaiknya ada minimal 2 entri:

1. `com.punpun.promohunter` + SHA-1 debug
2. `com.punpun.promohunter` + SHA-1 release / Play signing

## 4A. Cara Memasang API Key Google Maps Di Project Ini

Project ini membaca API key Android Google Maps dari `android/local.properties`, jadi key tidak perlu ditulis langsung ke git.

Tambahkan baris ini ke file:

`android/local.properties`

```properties
MAPS_API_KEY=AIzaSyxxxxxxxxxxxxxxxxxxxx
```

Lalu jalankan ulang app:

```powershell
flutter pub get
flutter run
```

Implementasi yang sudah aktif di project:

- Android manifest membaca key dari placeholder `MAPS_API_KEY`
- halaman detail toko menampilkan preview Google Maps jika data `latitude` dan `longitude` tersedia
- tombol `Buka Maps` tetap membuka aplikasi Google Maps / browser eksternal

File yang sudah tersambung:

- `android/app/build.gradle.kts`
- `android/app/src/main/AndroidManifest.xml`
- `lib/screens/store/store_detail_screen.dart`

## 4B. Cara Menyiapkan Release Keystore Di Project Ini

Project ini sekarang membaca release keystore dari:

```text
android/key.properties
```

Template sudah disediakan di:

```text
android/key.properties.example
```

### Langkah 1. Buat file key.properties

Copy template:

```powershell
Copy-Item "C:\Users\Lenovo\.vscode\coding\project\Promo Hunter\android\key.properties.example" "C:\Users\Lenovo\.vscode\coding\project\Promo Hunter\android\key.properties"
```

Lalu isi nilainya:

```properties
storePassword=PASSWORD_KEYSTORE_KAMU
keyPassword=PASSWORD_ALIAS_KAMU
keyAlias=promohunter
storeFile=../keys/promohunter-release.jks
```

`android/key.properties` sudah di-ignore dari git, jadi aman untuk secret lokal.

### Langkah 2. Buat file keystore

Contoh command:

```powershell
keytool -genkeypair -v -keystore "C:\Users\Lenovo\.vscode\coding\project\Promo Hunter\keys\promohunter-release.jks" -keyalg RSA -keysize 2048 -validity 10000 -alias promohunter
```

Kalau folder `keys` belum ada, buat dulu:

```powershell
New-Item -ItemType Directory -Force "C:\Users\Lenovo\.vscode\coding\project\Promo Hunter\keys"
```

### Langkah 3. Build release

Sesudah `key.properties` dan `.jks` siap:

```powershell
cd "C:\Users\Lenovo\.vscode\coding\project\Promo Hunter"
flutter build apk --release
```

atau:

```powershell
flutter build appbundle --release
```

Kalau `android/key.properties` belum ada atau belum lengkap, Gradle akan otomatis fallback ke debug signing untuk sementara.

## 5. Jika keytool Tidak Ditemukan

Kalau command `keytool` gagal, berarti Java/JDK belum masuk `PATH`.

Pilihan termudah:

1. buka Android Studio terminal
2. jalankan `.\gradlew signingReport` dari folder `android`

Command:

```powershell
cd "C:\Users\Lenovo\.vscode\coding\project\Promo Hunter\android"
.\gradlew signingReport
```

Lalu cari output:

```text
Variant: debug
SHA1: ...
```

## 6. Persiapan Release Yang Masih Kurang

Sebelum rilis production, yang masih perlu dilakukan:

1. ganti signing `release` dari debug key ke release keystore sendiri
2. simpan keystore di lokasi aman
3. backup `.jks`, `keyAlias`, `storePassword`, dan `keyPassword`
4. pisahkan API key debug dan production bila perlu
5. pastikan payment masih sandbox sampai benar-benar siap production
6. kalau nanti pindah ke Midtrans production, ubah endpoint dan secret production secara terpisah

## 7. Catatan Payment Sandbox

Saat ini project masih default ke sandbox:

- invoice proxy: Activepieces sandbox flow
- notification: Supabase Edge Function
- deeplink result Android: `promohunter://payment-result`

Jadi untuk testing Android:

1. jalankan ulang app setelah perubahan manifest
2. buat transaksi baru
3. selesaikan payment sandbox
4. pastikan callback kembali ke app, bukan ke `localhost`
