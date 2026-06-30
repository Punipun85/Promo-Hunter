import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/store_model.dart';

class MapsLauncher {
  const MapsLauncher._();

  static Uri storeUri(StoreModel store) {
    final configuredUri = Uri.tryParse(store.googleMapsUrl);
    if (configuredUri != null &&
        configuredUri.hasScheme &&
        store.googleMapsUrl.trim().isNotEmpty &&
        !configuredUri.host.toLowerCase().contains('google.')) {
      return configuredUri;
    }

    if (store.latitude != null && store.longitude != null) {
      final lat = store.latitude!;
      final lon = store.longitude!;
      return Uri.https(
        'www.openstreetmap.org',
        '/',
        {
          'mlat': lat.toString(),
          'mlon': lon.toString(),
        },
      ).replace(fragment: 'map=17/$lat/$lon');
    }

    final query = [
      store.name,
      store.address,
      store.city,
    ].where((value) => value.trim().isNotEmpty).join(' ');

    return Uri.https(
      'www.openstreetmap.org',
      '/search',
      {
        'query': query.isEmpty ? store.name : query,
      },
    );
  }

  static Uri searchUri({
    required String name,
    String? address,
    String? city,
  }) {
    final query = [
      name,
      address ?? '',
      city ?? '',
    ].where((value) => value.trim().isNotEmpty).join(' ');
    return Uri.https(
      'www.openstreetmap.org',
      '/search',
      {'query': query.isEmpty ? name : query},
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
        const SnackBar(content: Text('Gagal membuka peta.')),
      );
    }
  }

  static Future<void> openStoreSearch(
    BuildContext context, {
    required String name,
    String? address,
    String? city,
  }) async {
    final launched = await launchUrl(
      searchUri(name: name, address: address, city: city),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka peta.')),
      );
    }
  }
}
