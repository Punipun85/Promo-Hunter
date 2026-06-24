class MidtransConfig {
  const MidtransConfig._();

  static const defaultSandboxInvoiceProxyUrl =
      'https://punpunroro.app.n8n.cloud/webhook/promohunter-midtrans-invoice';

  static const _invoiceProxyUrlOverride = String.fromEnvironment(
    'MIDTRANS_INVOICE_PROXY_URL',
  );

  static String get invoiceProxyUrl {
    if (_invoiceProxyUrlOverride.trim().isNotEmpty) {
      return _invoiceProxyUrlOverride;
    }
    return defaultSandboxInvoiceProxyUrl;
  }

  static const isSandbox = bool.fromEnvironment(
    'MIDTRANS_SANDBOX',
    defaultValue: true,
  );

  static bool get isConfigured => invoiceProxyUrl.trim().isNotEmpty;
}
