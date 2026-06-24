# Activepieces Midtrans Migration - PromoHunter

Dokumen ini menyiapkan perpindahan proxy pembayaran PromoHunter dari n8n ke
Activepieces.

Target project Activepieces yang disebut user:

```text
https://cloud.activepieces.com/projects/OuAakrmNAAhdhzeVQ7cHZ/automations
```

## Tujuan

PromoHunter membutuhkan backend automation yang bisa:

1. menerima request invoice dari Flutter
2. membuat transaksi Midtrans Snap atau QRIS direct
3. mengembalikan `invoice_url` atau `simulator_url` ke Flutter
4. menerima notification Midtrans
5. menulis status pembayaran ke Supabase table `midtrans_payment_statuses`

## Kontrak Flutter yang Sudah Aktif

Flutter saat ini mengirim `POST` JSON ke `MIDTRANS_INVOICE_PROXY_URL`.

Contoh payload:

```json
{
  "source": "promohunter_flutter",
  "environment": "sandbox",
  "transaction_id": "PH-123456",
  "order_id": "PH-123456",
  "item_name": "Topup Coin 20.000",
  "amount": 20000,
  "gross_amount": 20000,
  "currency": "IDR",
  "transaction_type": "coin_topup",
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

Flutter menerima salah satu field berikut untuk URL pembayaran:

```text
invoice_url
payment_url
redirect_url
invoiceUrl
paymentUrl
url
simulator_url
simulatorUrl
```

Untuk QRIS direct sandbox, Flutter juga membaca:

```text
qr_code_url
qrCodeUrl
```

## Response yang Harus Diberikan Activepieces

### Snap / e-wallet / VA / transfer bank

```json
{
  "success": true,
  "invoice_id": "PH-123456",
  "order_id": "PH-123456",
  "invoice_url": "https://app.sandbox.midtrans.com/snap/v4/redirection/xxx",
  "redirect_url": "https://app.sandbox.midtrans.com/snap/v4/redirection/xxx",
  "token": "xxx",
  "payment_mode": "snap"
}
```

### QRIS direct sandbox

```json
{
  "success": true,
  "invoice_id": "PH-123456",
  "order_id": "PH-123456",
  "invoice_url": "https://simulator.sandbox.midtrans.com/v2/qris/index",
  "simulator_url": "https://simulator.sandbox.midtrans.com/v2/qris/index",
  "qr_code_url": "https://merchants-app.sbx.midtrans.com/.../qr-code",
  "payment_mode": "direct_qris"
}
```

## Flow yang Perlu Dibuat di Activepieces

### Flow 1: `promohunter-midtrans-invoice`

Trigger:

- Webhook `POST`

Langkah inti:

1. Parse body request dari Flutter.
2. Simpan `order_id`, `environment`, `preferred_payment_method`,
   `enabled_payments`, `payment_type`, `qris.acquirer`.
3. Jika `environment == sandbox` dan `preferred_payment_method == qris` dan
   `payment_type == qris`, panggil Midtrans QRIS direct:

```text
POST https://api.sandbox.midtrans.com/v2/charge
Authorization: Basic <base64(ServerKey:)>
Content-Type: application/json
```

Payload:

```json
{
  "payment_type": "qris",
  "transaction_details": {
    "order_id": "PH-123456",
    "gross_amount": 20000
  },
  "customer_details": {
    "first_name": "Nama User",
    "email": "user@email.com"
  },
  "item_details": [
    {
      "id": "PH-123456",
      "name": "Topup Coin 20.000",
      "price": 20000,
      "quantity": 1
    }
  ],
  "qris": {
    "acquirer": "gopay"
  }
}
```

4. Jika bukan QRIS direct, panggil Midtrans Snap:

```text
POST https://app.sandbox.midtrans.com/snap/v1/transactions
Authorization: Basic <base64(ServerKey:)>
Content-Type: application/json
```

Payload:

```json
{
  "enabled_payments": ["gopay", "shopeepay"],
  "transaction_details": {
    "order_id": "PH-123456",
    "gross_amount": 20000
  },
  "customer_details": {
    "first_name": "Nama User",
    "email": "user@email.com"
  },
  "item_details": [
    {
      "id": "PH-123456",
      "name": "Topup Coin 20.000",
      "price": 20000,
      "quantity": 1
    }
  ],
  "callbacks": {
    "finish": "http://localhost:55913/payment-result?order_id=PH-123456&result=success"
  }
}
```

5. Kembalikan JSON response ke Flutter mengikuti kontrak di atas.

### Flow 2: `promohunter-midtrans-notification`

Trigger:

- Webhook `POST`

Langkah inti:

1. Terima payload notification Midtrans.
2. Ambil `order_id`, `transaction_status`, `fraud_status`, `payment_type`,
   `gross_amount`, `transaction_id`, `settlement_time`.
3. Tentukan `paid = true` jika:
   - `transaction_status == settlement`, atau
   - `transaction_status == capture` dan `fraud_status == accept`
4. Upsert ke Supabase table `midtrans_payment_statuses`.

Contoh row:

```json
{
  "order_id": "PH-123456",
  "transaction_status": "settlement",
  "payment_type": "qris",
  "gross_amount": "20000.00",
  "transaction_id": "xxx",
  "paid": true,
  "raw_response": { "...": "..." }
}
```

## Secret yang Dibutuhkan di Activepieces

Tambahkan sebagai secret/project variable:

```text
MIDTRANS_SERVER_KEY_SANDBOX
SUPABASE_URL
SUPABASE_SERVICE_ROLE_KEY
```

Opsional untuk production nanti:

```text
MIDTRANS_SERVER_KEY_PRODUCTION
```

## Endpoint yang Perlu Diganti di Flutter

Begitu webhook Activepieces sudah jadi, jalankan Flutter dengan:

```powershell
flutter run `
  --dart-define=MIDTRANS_INVOICE_PROXY_URL=https://<activepieces-webhook-url> `
  --dart-define=MIDTRANS_SANDBOX=true
```

## Catatan Penting

- Flutter saat ini sudah backend-agnostic. Ia tidak wajib memakai n8n.
- Yang penting Activepieces mengembalikan field URL sesuai kontrak.
- Untuk status berhasil, Flutter membaca Supabase table
  `midtrans_payment_statuses`, jadi flow notification harus tetap ada.

## Langkah Manual di Dashboard Activepieces

1. Buat automation invoice webhook.
2. Buat automation notification webhook.
3. Salin webhook production URL invoice.
4. Tempel URL itu ke `MIDTRANS_INVOICE_PROXY_URL`.
5. Set Midtrans Payment Notification URL ke webhook notification Activepieces.
6. Uji satu pembayaran sandbox QRIS dan satu pembayaran VA.
