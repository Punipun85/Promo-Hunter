create table if not exists midtrans_payment_statuses (
  order_id text primary key,
  transaction_id text,
  transaction_status text,
  fraud_status text,
  payment_type text,
  gross_amount numeric,
  status_code text,
  status_message text,
  signature_verified boolean,
  paid boolean not null default false,
  failed boolean not null default false,
  raw_notification jsonb,
  created_at timestamp default now(),
  updated_at timestamp default now()
);

alter table midtrans_payment_statuses enable row level security;

drop policy if exists "midtrans_payment_statuses_public_read" on midtrans_payment_statuses;
create policy "midtrans_payment_statuses_public_read"
on midtrans_payment_statuses
for select
to anon, authenticated
using (true);

