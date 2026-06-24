# Midtrans Sandbox Setup - PromoHunter

PromoHunter memakai pola aman:

```text
Flutter App -> n8n/Supabase Edge Function proxy -> Midtrans Sandbox
```

Jangan simpan `server key` Midtrans di Flutter. `server key` hanya boleh berada di backend/proxy seperti n8n atau Supabase Edge Function.

Catatan: Midtrans Snap mengharuskan request pembuatan token/redirect payment dilakukan dari backend merchant dengan `Server Key`. Response sukses Snap biasanya berisi `token` dan `redirect_url`, jadi proxy boleh mengembalikan `redirect_url` itu sebagai `invoice_url` ke Flutter.

## 1. Variable Flutter

PromoHunter sekarang otomatis memakai webhook sandbox berikut jika `MIDTRANS_INVOICE_PROXY_URL` tidak diisi:

```text
https://punpunroro.app.n8n.cloud/webhook/promohunter-midtrans-invoice
```

Jadi untuk demo sandbox cukup jalankan:

```powershell
flutter run
```

Jika ingin override URL webhook, jalankan aplikasi dengan `dart-define` berikut:

```powershell
flutter run `
  --dart-define=MIDTRANS_INVOICE_PROXY_URL=https://punpunroro.app.n8n.cloud/webhook/promohunter-midtrans-invoice `
  --dart-define=MIDTRANS_SANDBOX=true
```

Jika URL proxy belum diisi, tombol Midtrans Sandbox tetap muncul tetapi nonaktif. User masih bisa memakai simulasi pembayaran manual.

## 2. Variable n8n

Buat credential di n8n untuk workflow utama berikut:

```text
Workflow: AI Promo Scraper OpenAI Source + OpenAI Extract
Workflow ID: h6DLxaqBoAFdzOx9
Editor URL: https://punpunroro.app.n8n.cloud/workflow/h6DLxaqBoAFdzOx9
Production URL: https://punpunroro.app.n8n.cloud/webhook/promohunter-midtrans-invoice
Test URL: https://punpunroro.app.n8n.cloud/webhook-test/promohunter-midtrans-invoice
```

Pada branch Midtrans, buka node `Create Midtrans Snap Transaction`, lalu isi credential HTTP Basic Auth:

```text
User: <Midtrans Sandbox Server Key>
Password: kosongkan
```

Midtrans memakai Basic Auth dengan format `ServerKey:`. Karena itu Server Key dimasukkan sebagai username dan password dikosongkan.

Opsional jika memakai Supabase untuk auto-update transaksi:

```text
SUPABASE_URL=<project url>
SUPABASE_SERVICE_ROLE_KEY=<service role key>
```

Untuk auto-approve setelah Midtrans Sandbox mengirim status pembayaran, jalankan
SQL migration:

```text
sql/010_midtrans_payment_statuses.sql
```

Lalu di Midtrans Sandbox Dashboard, set Payment Notification URL ke:

```text
https://punpunroro.app.n8n.cloud/webhook/promohunter-midtrans-notification
```

Workflow n8n akan menerima notification Midtrans, menulis status ke tabel
`midtrans_payment_statuses`, lalu Flutter akan membaca status itu dan otomatis
approve transaksi ketika status Midtrans adalah `settlement` atau `capture`.

Opsional untuk validasi signature notification di n8n, tambahkan variable:

```text
Midtrans_Server_Key=<Midtrans Sandbox Server Key>
```

## 3. Kontrak Request dari Flutter ke Proxy

Flutter akan mengirim JSON seperti ini:

```json
{
  "source": "promohunter_flutter",
  "environment": "sandbox",
  "transaction_id": "PH-123456",
  "order_id": "PH-123456",
  "item_name": "Premium Bulanan",
  "amount": 25000,
  "gross_amount": 25000,
  "currency": "IDR",
  "transaction_type": "subscription",
  "preferred_payment_method": "qris",
  "enabled_payments": ["gopay"],
  "payment_type": "qris",
  "qris": {
    "acquirer": "gopay"
  },
  "customer": {
    "name": "Nama User",
    "email": "user@email.com"
  }
}
```

Flutter sekarang mengirim preferensi berbeda tergantung metode yang dipilih:

- `QRIS` -> di sandbox memakai mode QRIS langsung, response akan berisi `qr_code_url` dan app membuka simulator QRIS Midtrans
- `E-Wallet` -> `enabled_payments: ["gopay", "shopeepay", "dana", "ovo"]`
- `Virtual Account` -> `enabled_payments: ["bca_va", "bni_va", "bri_va", "permata_va", "echannel"]`
- `Transfer Bank` -> preferensi `bank_transfer` tanpa memaksa satu bank tertentu

Untuk Snap Redirect, teruskan `enabled_payments` itu ke request
`/snap/v1/transactions` supaya halaman Midtrans langsung memprioritaskan flow
sesuai pilihan user. Untuk Core API QRIS langsung, gunakan `payment_type:
"qris"` dan `qris.acquirer: "gopay"`.

## 4. Kontrak Response dari Proxy ke Flutter

Proxy harus mengembalikan salah satu bentuk field URL berikut:

```json
{
  "invoice_id": "PH-123456",
  "invoice_url": "https://app.sandbox.midtrans.com/..."
}
```

Flutter juga bisa membaca variasi field:

```text
invoice_url, payment_url, redirect_url, invoiceUrl, paymentUrl, url
```

Untuk ID/reference:

```text
invoice_id, payment_id, id, order_id, transaction_id, token
```

## 5. Flow MVP

1. User pilih topup coin atau langganan premium.
2. User pilih salah satu metode lalu klik `Buat Invoice Sandbox`.
3. Flutter meminta invoice ke proxy.
4. Flutter membuka halaman pembayaran Midtrans Sandbox.
5. Midtrans langsung memprioritaskan flow sesuai metode yang dipilih user.
   Untuk QRIS sandbox, PromoHunter meminta QRIS langsung lalu memakai
   `qr_code_url` + simulator Midtrans. Untuk e-wallet dan VA, Snap akan masuk
   ke flow metode tersebut atau daftar turunannya.
   User selesaikan flow itu di halaman Midtrans, tidak perlu upload bukti
   manual.
6. Transaksi tercatat sebagai `Menunggu Verifikasi`.
7. Jika Midtrans mengirim notification `settlement` atau `capture`, Flutter
   otomatis mengubah transaksi menjadi `Berhasil`, benefit user langsung aktif,
   dan halaman admin melihat pembayaran sudah selesai.

## 6. Tutorial QRIS Sandbox

Untuk QRIS di sandbox, jangan berharap harus membayar dengan saldo asli. Yang
terjadi adalah Midtrans mensimulasikan pembayaran lewat web.

Langkah yang disarankan:

1. Di app pilih metode `QRIS`.
2. Klik `Buat Invoice Sandbox`.
3. Browser akan membuka halaman Snap Midtrans Sandbox.
4. Jika Snap menampilkan flow QRIS/web simulator, selesaikan langsung di sana.
5. Jika Midtrans menampilkan URL gambar QRIS terpisah, buka simulator resmi:
   [QRIS Sandbox Simulator](https://simulator.sandbox.midtrans.com/v2/qris/index)
6. Tempel URL gambar QRIS ke simulator, lalu klik `Scan QR`.
7. Selesaikan flow simulator sampai status sukses.
8. Midtrans akan mengirim notification ke n8n, lalu app otomatis mengaktifkan
   coin atau premium.

Referensi resmi Midtrans:

- [Testing Payment on Sandbox](https://docs.midtrans.com/docs/testing-payment-on-sandbox)
- [Testing BI-SNAP QRIS Sandbox](https://docs.midtrans.com/reference/testing-bi-snap-on-sandbox-environment)
- [GoPay & QRIS](https://docs.midtrans.com/reference/gopay)

## 7. Upgrade Setelah MVP

Untuk versi production, ganti local polling menjadi Supabase Realtime atau FCM
agar admin di device lain menerima push notification real-time ketika pembayaran
berubah menjadi `settlement` atau `capture`.
