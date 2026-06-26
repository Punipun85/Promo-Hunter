class N8nConfig {
  const N8nConfig._();

  static const legacyPromoImportWebhookTestUrl =
      'https://punpunroro.app.n8n.cloud/webhook-test/promohunter-import-promos';

  static const legacyPromoImportWebhookProductionUrl =
      'https://punpunroro.app.n8n.cloud/webhook/promohunter-import-promos';

  static const isLegacyN8nEnabled = false;

  static const promoImportWebhookTestUrl =
      'https://eonr7obmd70bcx2.m.pipedream.net';

  static const promoImportWebhookProductionUrl =
      'https://eonr7obmd70bcx2.m.pipedream.net';

  static const promoImportWebhookUrls = [
    promoImportWebhookTestUrl,
    promoImportWebhookProductionUrl,
  ];
}
