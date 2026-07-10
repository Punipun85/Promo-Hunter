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
      if (_isOpenStreetMapSearch(configuredUri)) {
        return searchUri(name: store.name);
      }
      return configuredUri;
    }

    if (!_isGenericStoreLocation(store) &&
        store.latitude != null &&
        store.longitude != null) {
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

    return searchUri(name: store.name);
  }

  static Uri searchUri({
    required String name,
    String? address,
    String? city,
  }) {
    final query = _cleanStoreSearchName(name);
    return Uri.https(
      'www.openstreetmap.org',
      '/search',
      {'query': query.isEmpty ? name.trim() : query},
    );
  }

  static bool _isGenericStoreLocation(StoreModel store) {
    final address = store.address.trim().toLowerCase();
    final mapsUrl = store.googleMapsUrl.trim().toLowerCase();
    return address.contains('terdekat') ||
        address.startsWith('gerai ') ||
        address.startsWith('layanan online') ||
        mapsUrl.contains('/search?query=');
  }

  static bool _isOpenStreetMapSearch(Uri uri) {
    final host = uri.host.toLowerCase();
    return host.contains('openstreetmap.org') && uri.path == '/search';
  }

  static String _cleanStoreSearchName(String value) {
    var query = value.trim();
    final lower = query.toLowerCase();
    const chainNames = <String>[
      'klik indomaret',
      'indomaret',
      'alfagift',
      'alfamart',
      'super indo',
      'hypermart',
      'transmart',
      'lotte mart',
      'farmers market',
      'ranch market',
      'grand lucky',
      'hero supermarket',
      'shopee',
      'tokopedia',
      'lazada',
      'blibli',
    ];
    for (final chain in chainNames) {
      if (lower.contains(chain)) {
        return _titleCase(chain);
      }
    }
    query = query
        .replaceAll(RegExp(r'\b(terdekat|nearby)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bgerai\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return query;
  }

  static String _titleCase(String value) {
    return value
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
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
