import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/store_model.dart';

class MapsLauncher {
  const MapsLauncher._();

  static Uri storeUri(StoreModel store) {
    final configuredUri = Uri.tryParse(store.googleMapsUrl);
    if (configuredUri != null &&
        configuredUri.hasScheme &&
        store.googleMapsUrl.trim().isNotEmpty) {
      return configuredUri;
    }

    final query = [
      store.name,
      store.address,
      store.city,
    ].where((value) => value.trim().isNotEmpty).join(' ');

    return Uri.https(
      'www.google.com',
      '/maps/search/',
      {
        'api': '1',
        'query': query.isEmpty ? store.name : query,
      },
    );
  }

  static Future<void> openStore(
    BuildContext context,
    StoreModel store,
  ) async {
    final launched = await launchUrl(
      storeUri(store),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka Google Maps.')),
      );
    }
  }
}
