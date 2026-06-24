const fs = require('fs');
const path = require('path');

const sourcePath =
  process.argv[2] ||
  'C:/Users/Lenovo/Downloads/AI Promo Scraper OpenAI Source + OpenAI Extract.json';
const outDir =
  process.argv[3] ||
  'C:/Users/Lenovo/.vscode/coding/project/Promo Hunter/migration/activepieces';

function readJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

function ensureDir(dirPath) {
  fs.mkdirSync(dirPath, { recursive: true });
}

function writeJson(filePath, value) {
  fs.writeFileSync(filePath, `${JSON.stringify(value, null, 2)}\n`, 'utf8');
}

function assertHasNode(data, name) {
  const node = data.nodes.find((item) => item.name === name);
  if (!node) {
    throw new Error(`Node "${name}" tidak ditemukan di export n8n.`);
  }
  return node;
}

function buildInvoiceCode() {
  return `import axios from 'axios';

export const code = async (inputs) => {
  const body = inputs.body ?? {};
  const amount = Number(body.gross_amount ?? body.amount);
  if (!body.order_id && !body.transaction_id) {
    throw new Error('order_id atau transaction_id wajib diisi');
  }
  if (!body.item_name) {
    throw new Error('item_name wajib diisi');
  }
  if (!Number.isFinite(amount) || amount <= 0) {
    throw new Error('gross_amount harus angka lebih dari 0');
  }

  const MIDTRANS_SERVER_KEY_SANDBOX = '<MIDTRANS_SERVER_KEY_SANDBOX>';
  const MIDTRANS_SERVER_KEY_PRODUCTION = '<MIDTRANS_SERVER_KEY_PRODUCTION_OPTIONAL>';
  const SIMULATOR_URL = 'https://simulator.sandbox.midtrans.com/v2/qris/index';

  const customer = body.customer ?? {};
  const orderId = String(body.order_id ?? body.transaction_id);
  const itemName = String(body.item_name);
  const transactionType = String(body.transaction_type ?? 'promohunter_payment');
  const customerName = customer.name || body.customer_name || 'User PromoHunter';
  const customerEmail = customer.email || body.customer_email || 'customer@promohunter.local';
  const environment = String(body.environment ?? 'sandbox').toLowerCase();
  const preferredPaymentMethod = String(body.preferred_payment_method ?? '').toLowerCase();
  const requestedEnabledPayments = Array.isArray(body.enabled_payments)
    ? body.enabled_payments.map((item) => String(item).trim()).filter(Boolean)
    : [];
  const enabledPayments = requestedEnabledPayments.length > 0
    ? requestedEnabledPayments
    : preferredPaymentMethod === 'qris'
      ? ['gopay']
      : ['gopay', 'shopeepay', 'bca_va', 'bni_va', 'bri_va', 'permata_va'];
  const callbacks = body.callbacks && typeof body.callbacks === 'object' ? body.callbacks : null;
  const paymentType = String(body.payment_type ?? '').toLowerCase();
  const qrisConfig = body.qris && typeof body.qris === 'object' ? body.qris : { acquirer: 'gopay' };
  const useDirectQrisSimulator =
    environment === 'sandbox' &&
    preferredPaymentMethod === 'qris' &&
    paymentType === 'qris';

  const serverKey = environment === 'production'
    ? MIDTRANS_SERVER_KEY_PRODUCTION
    : MIDTRANS_SERVER_KEY_SANDBOX;

  if (!serverKey || serverKey.startsWith('<')) {
    throw new Error('Isi MIDTRANS_SERVER_KEY di code step Activepieces sebelum publish flow.');
  }

  let midtransEndpoint;
  let midtransPayload;
  let midtransMode;

  if (useDirectQrisSimulator) {
    midtransEndpoint = environment === 'production'
      ? 'https://api.midtrans.com/v2/charge'
      : 'https://api.sandbox.midtrans.com/v2/charge';
    midtransMode = 'direct_qris';
    midtransPayload = {
      payment_type: 'qris',
      transaction_details: {
        order_id: orderId,
        gross_amount: amount,
      },
      customer_details: {
        first_name: customerName,
        email: customerEmail,
      },
      item_details: [{
        id: transactionType,
        price: amount,
        quantity: 1,
        name: itemName,
      }],
      qris: qrisConfig,
    };
  } else {
    const hasCreditCard = enabledPayments.includes('credit_card');
    const hasGopay = enabledPayments.includes('gopay');
    midtransEndpoint = environment === 'production'
      ? 'https://app.midtrans.com/snap/v1/transactions'
      : 'https://app.sandbox.midtrans.com/snap/v1/transactions';
    midtransMode = 'snap';
    midtransPayload = {
      transaction_details: {
        order_id: orderId,
        gross_amount: amount,
      },
      enabled_payments: enabledPayments,
      customer_details: {
        first_name: customerName,
        email: customerEmail,
      },
      item_details: [{
        id: transactionType,
        price: amount,
        quantity: 1,
        name: itemName,
      }],
    };

    if (callbacks) {
      midtransPayload.callbacks = callbacks;
    }

    if (hasCreditCard) {
      midtransPayload.credit_card = { secure: true };
    }

    if (hasGopay) {
      midtransPayload.gopay = { enable_callback: false };
    }
  }

  const response = await axios.post(midtransEndpoint, midtransPayload, {
    timeout: 45000,
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      Authorization: 'Basic ' + Buffer.from(\`\${serverKey}:\`).toString('base64'),
    },
  });

  const source = response.data ?? {};
  const actions = Array.isArray(source.actions) ? source.actions : [];
  const qrAction =
    actions.find((action) => String(action?.name || '').toLowerCase().includes('generate-qr-code-v2')) ||
    actions.find((action) => String(action?.name || '').toLowerCase().includes('generate-qr-code'));
  const qrCodeUrl = qrAction?.url || source.qr_code_url || null;
  const isDirectQris = midtransMode === 'direct_qris';

  return {
    success: true,
    invoice_id: orderId,
    order_id: orderId,
    snap_token: source.token || null,
    invoice_url: isDirectQris ? SIMULATOR_URL : (source.redirect_url || null),
    token: source.token || null,
    redirect_url: source.redirect_url || null,
    qr_code_url: qrCodeUrl,
    simulator_url: isDirectQris ? SIMULATOR_URL : null,
    payment_mode: midtransMode,
    message: isDirectQris ? 'Midtrans sandbox QRIS simulator created' : 'Midtrans sandbox invoice created',
    raw_midtrans_response: source,
  };
};`;
}

function buildNotificationNormalizeCode() {
  return `import crypto from 'node:crypto';

export const code = async (inputs) => {
  const body = inputs.body ?? {};
  const orderId = String(body.order_id ?? '').trim();
  if (!orderId) {
    throw new Error('order_id not found in Midtrans notification');
  }

  const statusCode = String(body.status_code ?? '');
  const grossAmount = String(body.gross_amount ?? '');
  const MIDTRANS_SERVER_KEY_SANDBOX = '<MIDTRANS_SERVER_KEY_SANDBOX>';
  const MIDTRANS_SERVER_KEY_PRODUCTION = '<MIDTRANS_SERVER_KEY_PRODUCTION_OPTIONAL>';
  const environment = String(body.environment ?? 'sandbox').toLowerCase();
  const serverKey = environment === 'production'
    ? MIDTRANS_SERVER_KEY_PRODUCTION
    : MIDTRANS_SERVER_KEY_SANDBOX;

  let signatureVerified = null;
  if (serverKey && !serverKey.startsWith('<') && body.signature_key) {
    const digest = crypto
      .createHash('sha512')
      .update(orderId + statusCode + grossAmount + serverKey)
      .digest('hex');
    signatureVerified = digest === String(body.signature_key);
  }

  const transactionStatus = String(body.transaction_status ?? '').toLowerCase();
  const fraudStatus = String(body.fraud_status ?? '').toLowerCase();
  const paid =
    ['settlement', 'capture'].includes(transactionStatus) &&
    (!fraudStatus || fraudStatus === 'accept');
  const failed = ['deny', 'cancel', 'expire', 'failure'].includes(transactionStatus);

  return {
    order_id: orderId,
    transaction_id: body.transaction_id ?? null,
    transaction_status: transactionStatus || null,
    fraud_status: fraudStatus || null,
    payment_type: body.payment_type ?? null,
    gross_amount: Number(body.gross_amount ?? 0),
    status_code: statusCode || null,
    status_message: body.status_message ?? null,
    signature_verified: signatureVerified,
    paid,
    failed,
    raw_notification: body,
    updated_at: new Date().toISOString(),
  };
};`;
}

function buildNotificationUpsertCode() {
  return `import axios from 'axios';

export const code = async (inputs) => {
  const payload = inputs.normalized;
  const SUPABASE_URL = '<SUPABASE_URL>';
  const SUPABASE_SERVICE_ROLE_KEY = '<SUPABASE_SERVICE_ROLE_KEY>';

  if (!SUPABASE_URL || SUPABASE_URL.startsWith('<')) {
    throw new Error('Isi SUPABASE_URL di code step Activepieces sebelum publish flow.');
  }
  if (!SUPABASE_SERVICE_ROLE_KEY || SUPABASE_SERVICE_ROLE_KEY.startsWith('<')) {
    throw new Error('Isi SUPABASE_SERVICE_ROLE_KEY di code step Activepieces sebelum publish flow.');
  }

  const url =
    SUPABASE_URL.replace(/\\/$/, '') +
    '/rest/v1/midtrans_payment_statuses?on_conflict=order_id';

  await axios.post(url, payload, {
    timeout: 20000,
    headers: {
      apikey: SUPABASE_SERVICE_ROLE_KEY,
      Authorization: 'Bearer ' + SUPABASE_SERVICE_ROLE_KEY,
      'Content-Type': 'application/json',
      Prefer: 'resolution=merge-duplicates,return=representation',
    },
  });

  return {
    success: true,
    order_id: payload.order_id,
    paid: payload.paid,
    signature_verified: payload.signature_verified,
  };
};`;
}

function createWebhookTrigger(nextAction) {
  return {
    name: 'trigger',
    valid: true,
    displayName: 'Catch Webhook',
    type: 'PIECE_TRIGGER',
    settings: {
      pieceName: '@activepieces/piece-webhook',
      pieceVersion: '0.1.32',
      pieceType: 'OFFICIAL',
      packageType: 'REGISTRY',
      triggerName: 'catch_webhook',
      input: {
        authType: 'none',
      },
      inputUiInfo: {
        customizedInputs: {},
      },
    },
    nextAction,
  };
}

function createCodeStep({ name, displayName, input, code, packageJson = '{}' , nextAction = undefined }) {
  const step = {
    name,
    type: 'CODE',
    valid: true,
    settings: {
      input,
      sourceCode: {
        code,
        packageJson,
      },
      inputUiInfo: {
        customizedInputs: {},
      },
      errorHandlingOptions: {
        retryOnFailure: { value: false },
        continueOnFailure: { value: false },
      },
    },
    displayName,
  };
  if (nextAction) {
    step.nextAction = nextAction;
  }
  return step;
}

function createFlowJson({ name, displayName, nextAction }) {
  const now = String(Date.now());
  return {
    created: now,
    updated: now,
    name,
    description: 'Generated from n8n Midtrans branch for PromoHunter',
    tags: ['promohunter', 'midtrans', 'generated-from-n8n'],
    pieces: ['@activepieces/piece-webhook'],
    template: {
      displayName,
      trigger: createWebhookTrigger(nextAction),
      valid: true,
      schemaVersion: '1',
    },
    blogUrl: '',
  };
}

function main() {
  const data = readJson(sourcePath);
  assertHasNode(data, 'Midtrans Invoice Webhook');
  assertHasNode(data, 'Build Midtrans Payload');
  assertHasNode(data, 'Create Midtrans Snap Transaction');
  assertHasNode(data, 'Build Midtrans Invoice Response');
  assertHasNode(data, 'Midtrans Notification Webhook');
  assertHasNode(data, 'Normalize Midtrans Notification');
  assertHasNode(data, 'Upsert Midtrans Payment Status');

  ensureDir(outDir);

  const invoiceFlow = createFlowJson({
    name: 'promohunter-midtrans-invoice',
    displayName: 'promohunter-midtrans-invoice',
    nextAction: createCodeStep({
      name: 'step_1',
      displayName: 'Create Midtrans Invoice',
      input: {
        body: "{{trigger['body']}}",
      },
      code: buildInvoiceCode(),
      packageJson: JSON.stringify({ dependencies: { axios: '^1.7.9' } }, null, 2),
    }),
  });

  const notificationFlow = createFlowJson({
    name: 'promohunter-midtrans-notification',
    displayName: 'promohunter-midtrans-notification',
    nextAction: createCodeStep({
      name: 'step_1',
      displayName: 'Normalize Midtrans Notification',
      input: {
        body: "{{trigger['body']}}",
      },
      code: buildNotificationNormalizeCode(),
      packageJson: '{}',
      nextAction: createCodeStep({
        name: 'step_2',
        displayName: 'Upsert Midtrans Payment Status',
        input: {
          normalized: '{{step_1}}',
        },
        code: buildNotificationUpsertCode(),
        packageJson: JSON.stringify({ dependencies: { axios: '^1.7.9' } }, null, 2),
      }),
    }),
  });

  writeJson(path.join(outDir, 'promohunter-midtrans-invoice.activepieces.json'), invoiceFlow);
  writeJson(path.join(outDir, 'promohunter-midtrans-notification.activepieces.json'), notificationFlow);

  console.log(`Generated Activepieces flows in ${outDir}`);
}

main();
