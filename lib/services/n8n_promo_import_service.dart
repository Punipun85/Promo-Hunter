import 'dart:convert';

import 'package:dio/dio.dart';

import '../config/n8n_config.dart';
import '../models/promo_model.dart';

class N8nPromoImportService {
  N8nPromoImportService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<PromoImportResult> importPromos() async {
    final response = await _dio.post<dynamic>(
      N8nConfig.promoImportWebhookUrl,
      data: jsonEncode({
        'source': 'promohunter_admin',
        'requested_at': DateTime.now().toIso8601String(),
      }),
      options: Options(
        contentType: Headers.textPlainContentType,
        sendTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(minutes: 3),
      ),
    );

    final promos = _extractPromotionMaps(response.data)
        .map(_mapToPromo)
        .whereType<PromoModel>()
        .toList();

    return PromoImportResult(
      importedPromos: promos,
      rawCount: promos.length,
      sourceName: _findString(response.data, const ['source_name']) ??
          'n8n Promo Scraper',
    );
  }

  List<Map<String, dynamic>> _extractPromotionMaps(dynamic payload) {
    final found = <Map<String, dynamic>>[];

    void visit(dynamic value) {
      if (value == null) return;

      if (value is String) {
        final decoded = _tryDecodeJson(value);
        if (decoded != null && decoded != value) visit(decoded);
        return;
      }

      if (value is List) {
        final allMaps = value.every((item) => item is Map);
        if (allMaps) {
          found.addAll(value.cast<Map>().map(_stringKeyedMap));
          return;
        }
        for (final item in value) {
          visit(item);
        }
        return;
      }

      if (value is Map) {
        final map = _stringKeyedMap(value);
        final promotions = map['promotions'];
        if (promotions != null) {
          visit(promotions);
        }
        for (final entry in map.entries) {
          if (entry.key != 'promotions') visit(entry.value);
        }
      }
    }

    visit(payload);
    return found;
  }

  PromoModel? _mapToPromo(Map<String, dynamic> map) {
    final title = _firstString(map, const [
      'product_name',
      'title',
      'name',
      'promo_title',
    ]);
    if (title == null || title.trim().isEmpty) return null;

    final promoPrice = _firstNumber(map, const [
      'promo_price',
      'sale_price',
      'discounted_price',
      'price',
    ]);
    final normalPrice = _firstNumber(map, const [
      'normal_price',
      'original_price',
      'regular_price',
      'before_price',
    ]);

    final safePromoPrice = promoPrice ?? normalPrice ?? 0;
    final safeNormalPrice = normalPrice != null && normalPrice >= safePromoPrice
        ? normalPrice
        : safePromoPrice;
    if (safePromoPrice <= 0 || safeNormalPrice <= 0) return null;

    final now = DateTime.now();
    final startDate = _firstDate(map, const ['start_date']) ?? now;
    final endDate = _firstDate(map, const ['end_date']) ??
        now.add(const Duration(days: 14));
    final sourceUrl = _firstString(map, const ['source_url', 'url']) ?? '';
    final sourceName = _firstString(map, const ['source_name', 'merchant']) ??
        _hostFromUrl(sourceUrl) ??
        'n8n Promo Source';

    return PromoModel(
      id: 0,
      productName: title.trim(),
      brand: _firstString(map, const ['brand']) ?? sourceName,
      imageUrl: _firstString(map, const ['image_url', 'image']) ??
          'https://images.unsplash.com/photo-1607083206968-13611e3d76db?w=1200',
      normalPrice: safeNormalPrice.toDouble(),
      promoPrice: safePromoPrice.toDouble(),
      unitSize: _firstNumber(map, const ['unit_size', 'size']) ?? 1,
      unitType: _firstString(map, const ['unit_type', 'unit']) ?? 'pcs',
      storeName: sourceName,
      storeAddress: 'Sumber promo dari n8n',
      categoryName: _firstString(map, const ['category', 'category_name']) ??
          'Promo Online',
      startDate: startDate,
      endDate: endDate,
      terms: _firstString(map, const [
            'terms',
            'promo_period',
            'evidence_text',
            'description',
          ]) ??
          'Diimpor otomatis dari workflow n8n.',
      sourceUrl: sourceUrl,
    );
  }

  dynamic _tryDecodeJson(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return value;
    try {
      return jsonDecode(trimmed);
    } catch (_) {
      final start = trimmed.indexOf('[');
      final end = trimmed.lastIndexOf(']');
      if (start >= 0 && end > start) {
        try {
          return jsonDecode(trimmed.substring(start, end + 1));
        } catch (_) {}
      }
    }
    return value;
  }

  Map<String, dynamic> _stringKeyedMap(Map value) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  String? _firstString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return null;
  }

  double? _firstNumber(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      final parsed = _parseNumber(value);
      if (parsed != null) return parsed;
    }
    return null;
  }

  double? _parseNumber(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final text = value.toString();
    final match = RegExp(r'\d[\d.,]*').firstMatch(text);
    if (match == null) return null;

    var digits = match.group(0) ?? '';
    final commaCount = ','.allMatches(digits).length;
    final dotCount = '.'.allMatches(digits).length;
    if (commaCount > 1 || dotCount > 1) {
      digits = digits.replaceAll(RegExp(r'[,.]'), '');
    } else if (commaCount == 1 && dotCount == 0) {
      final parts = digits.split(',');
      digits = parts.last.length == 3
          ? digits.replaceAll(',', '')
          : digits.replaceAll(',', '.');
    } else if (dotCount == 1 && commaCount == 0) {
      final parts = digits.split('.');
      digits = parts.last.length == 3 ? digits.replaceAll('.', '') : digits;
    } else if (commaCount == 1 && dotCount == 1) {
      final lastComma = digits.lastIndexOf(',');
      final lastDot = digits.lastIndexOf('.');
      if (lastComma > lastDot) {
        digits = digits.replaceAll('.', '').replaceAll(',', '.');
      } else {
        digits = digits.replaceAll(',', '');
      }
    }

    return double.tryParse(digits);
  }

  DateTime? _firstDate(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final parsed = DateTime.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return null;
  }

  String? _findString(dynamic payload, List<String> keys) {
    if (payload is Map) {
      final map = _stringKeyedMap(payload);
      final direct = _firstString(map, keys);
      if (direct != null) return direct;
      for (final value in map.values) {
        final found = _findString(value, keys);
        if (found != null) return found;
      }
    }
    if (payload is List) {
      for (final value in payload) {
        final found = _findString(value, keys);
        if (found != null) return found;
      }
    }
    return null;
  }

  String? _hostFromUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri?.host.replaceFirst('www.', '');
  }
}

class PromoImportResult {
  const PromoImportResult({
    required this.importedPromos,
    required this.rawCount,
    required this.sourceName,
  });

  final List<PromoModel> importedPromos;
  final int rawCount;
  final String sourceName;
}
