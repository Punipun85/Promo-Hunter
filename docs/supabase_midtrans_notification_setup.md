# Supabase Edge Function - Midtrans Notification

Gunakan ini jika Payment Notification URL Midtrans gagal diarahkan ke
Activepieces karena error TLS handshake.

## Fungsi

Edge Function berikut menerima webhook Midtrans, memverifikasi signature
(opsional jika `MIDTRANS_SERVER_KEY` diisi), lalu melakukan `upsert` ke tabel:

```text
midtrans_payment_statuses
```

File function:

```text
supabase/functions/midtrans-notification/index.ts
```

## Prasyarat

1. Tabel status Midtrans sudah dibuat:

```text
sql/010_midtrans_payment_statuses.sql
```

2. Supabase CLI sudah login dan project sudah linked.

Project ref saat ini:

```text
ujltafrzoeeklcudihgm
```

## Secret yang Dibutuhkan

Set secret function:

```powershell
supabase secrets set MIDTRANS_SERVER_KEY=ISI_SERVER_KEY_SANDBOX_KAMU
```

`SUPABASE_URL` dan `SUPABASE_SERVICE_ROLE_KEY` biasanya sudah tersedia di
runtime Edge Function. Jika environment kamu membutuhkannya secara manual,
set juga:

```powershell
supabase secrets set SUPABASE_URL=https://ujltafrzoeeklcudihgm.supabase.co
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=ISI_SERVICE_ROLE_KEY_KAMU
```

## Deploy

Karena Midtrans akan memanggil endpoint ini tanpa JWT user, deploy dengan
`--no-verify-jwt`.

```powershell
supabase functions deploy midtrans-notification --no-verify-jwt
```

## URL yang Dipasang di Midtrans

Set `Payment Notification URL` Midtrans Sandbox menjadi:

```text
https://ujltafrzoeeklcudihgm.functions.supabase.co/midtrans-notification
```

## Test Lokal Cepat

```powershell
$body = @{
  order_id = 'PH-LOCAL-TEST-001'
  transaction_id = 'local-test-001'
  transaction_status = 'settlement'
  fraud_status = 'accept'
  payment_type = 'qris'
  gross_amount = '3000.00'
  status_code = '200'
  status_message = 'OK'
} | ConvertTo-Json

Invoke-RestMethod `
  -Uri 'https://ujltafrzoeeklcudihgm.functions.supabase.co/midtrans-notification' `
  -Method Post `
  -ContentType 'application/json' `
  -Body $body
```

Response sukses minimal:

```json
{
  "success": true,
  "order_id": "PH-LOCAL-TEST-001",
  "transaction_status": "settlement",
  "paid": true,
  "failed": false,
  "signature_verified": null
}
```

## Setelah Deploy

1. Update `Payment Notification URL` Midtrans.
2. Buat transaksi sandbox baru.
3. Pastikan row dengan `order_id` transaksi itu muncul di
   `midtrans_payment_statuses`.
4. Buka kembali wallet/topup agar Flutter melakukan sync dan auto-approve.
