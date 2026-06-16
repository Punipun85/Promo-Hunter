class N8nConfig {
  const N8nConfig._();

  static const promoImportWebhookTestUrl =
      'https://punpunroro.app.n8n.cloud/webhook-test/promohunter-import-promos';

  static const promoImportWebhookProductionUrl =
      'https://punpunroro.app.n8n.cloud/webhook/promohunter-import-promos';

  static const promoImportWebhookUrls = [
    promoImportWebhookTestUrl,
    promoImportWebhookProductionUrl,
  ];
}
