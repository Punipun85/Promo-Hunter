import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.8';

const corsHeaders = {
  'Content-Type': 'application/json',
};

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: corsHeaders,
  });
}

async function sha512Hex(input: string): Promise<string> {
  const bytes = new TextEncoder().encode(input);
  const digest = await crypto.subtle.digest('SHA-512', bytes);
  return Array.from(new Uint8Array(digest))
      .map((byte) => byte.toString(16).padStart(2, '0'))
      .join('');
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (request.method !== 'POST') {
    return jsonResponse(
      {
        success: false,
        message: 'Method not allowed. Use POST.',
      },
      405,
    );
  }

  let payload: Record<string, unknown>;
  try {
    payload = await request.json();
  } catch (_) {
    return jsonResponse(
      {
        success: false,
        message: 'Invalid JSON body.',
      },
      400,
    );
  }

  const orderId = String(payload.order_id ?? '').trim();
  if (!orderId) {
    return jsonResponse(
      {
        success: false,
        message: 'order_id not found in Midtrans notification.',
      },
      400,
    );
  }

  const transactionStatus = String(payload.transaction_status ?? '').toLowerCase();
  const fraudStatus = String(payload.fraud_status ?? '').toLowerCase();
  const statusCode = String(payload.status_code ?? '');
  const grossAmount = String(payload.gross_amount ?? '');
  const transactionId = payload.transaction_id == null
    ? null
    : String(payload.transaction_id);
  const paymentType = payload.payment_type == null
    ? null
    : String(payload.payment_type);
  const statusMessage = payload.status_message == null
    ? null
    : String(payload.status_message);

  const paid = ['settlement', 'capture'].includes(transactionStatus) &&
    (!fraudStatus || fraudStatus === 'accept');
  const failed = ['deny', 'cancel', 'expire', 'failure'].includes(transactionStatus);

  const serverKey = Deno.env.get('MIDTRANS_SERVER_KEY')?.trim() ?? '';
  let signatureVerified: boolean | null = null;
  if (serverKey && payload.signature_key) {
    const expected = await sha512Hex(orderId + statusCode + grossAmount + serverKey);
    signatureVerified = expected === String(payload.signature_key);
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')?.trim();
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')?.trim();
  if (!supabaseUrl || !serviceRoleKey) {
    return jsonResponse(
      {
        success: false,
        message: 'Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY environment variables.',
      },
      500,
    );
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });

  const row = {
    order_id: orderId,
    transaction_id: transactionId,
    transaction_status: transactionStatus || null,
    fraud_status: fraudStatus || null,
    payment_type: paymentType,
    gross_amount: Number(payload.gross_amount ?? 0),
    status_code: statusCode || null,
    status_message: statusMessage,
    signature_verified: signatureVerified,
    paid,
    failed,
    raw_notification: payload,
    updated_at: new Date().toISOString(),
  };

  const { error } = await supabase
    .from('midtrans_payment_statuses')
    .upsert(row, { onConflict: 'order_id' });

  if (error) {
    return jsonResponse(
      {
        success: false,
        message: 'Failed to upsert midtrans payment status.',
        error: error.message,
        order_id: orderId,
      },
      500,
    );
  }

  return jsonResponse({
    success: true,
    order_id: orderId,
    transaction_status: transactionStatus || null,
    paid,
    failed,
    signature_verified: signatureVerified,
  });
});
