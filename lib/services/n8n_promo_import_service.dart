import 'dart:convert';

import 'package:dio/dio.dart';

import '../config/n8n_config.dart';
import '../models/promo_model.dart';
import '../widgets/promo_image.dart';

class N8nPromoImportService {
  N8nPromoImportService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<PromoImportResult> importPromos() async {
    Response<dynamic>? response;
    final failures = <String>[];

    for (final webhookUrl in N8nConfig.promoImportWebhookUrls) {
      try {
        response = await _dio.post<dynamic>(
          webhookUrl,
          data: _buildImportRequest(),
          options: Options(
            contentType: Headers.jsonContentType,
            responseType: ResponseType.json,
            sendTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(minutes: 5),
            headers: const {
              'Accept': 'application/json',
            },
          ),
        );
        break;
      } on DioException catch (error) {
        failures.add('${_shortWebhookUrl(webhookUrl)}: ${_friendlyDioMessage(error)}');
        if (error.response?.statusCode != 404) {
          continue;
        }
      }
    }

    if (response == null) {
      throw N8nPromoImportException(
        'Webhook n8n belum bisa dihubungi. Detail: ${failures.join(' | ')}',
      );
    }

    final directInsertCount = _findInt(response.data, const [
      'inserted_count',
      'inserted',
      'created_count',
      'promo_count',
    ]);
    final isDirectInsert = _findBool(response.data, const [
          'direct_insert',
          'inserted_to_supabase',
          'supabase_inserted',
        ]) ??
        _findString(response.data, const ['mode', 'sync_mode'])
                ?.toLowerCase()
                .contains('direct') ==
            true ||
        directInsertCount != null;
    final promos = _extractPromotionMaps(response.data)
        .map(_mapToPromo)
        .whereType<PromoModel>()
        .toList();

    return PromoImportResult(
      importedPromos: promos,
      rawCount: promos.length,
      sourceName: _findString(response.data, const ['source_name']) ??
          'n8n Promo Scraper',
      insertedCount: directInsertCount ?? 0,
      isDirectSupabaseInsert: isDirectInsert,
    );
  }

  String _shortWebhookUrl(String url) {
    return url.contains('/webhook-test/')
        ? 'Test URL'
        : url.contains('/webhook/')
            ? 'Production URL'
            : url;
  }

  Map<String, dynamic> _buildImportRequest() {
    final now = DateTime.now();
    final monthLabel = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    return {
      'source': 'promohunter_admin',
      'requested_at': now.toIso8601String(),
      'mode': 'multi_source_web_scrape_with_supabase_insert',
      'sync_strategy': 'n8n_download_images_upload_storage_insert_supabase',
      'locale': 'id_ID',
      'country': 'Indonesia',
      'supabase_target': const {
        'storage_bucket': 'promo-images',
        'tables': {
          'stores': 'stores',
          'categories': 'categories',
          'promos': 'promos',
        },
        'image_upload': {
          'enabled': true,
          'folder': 'n8n-promos',
          'save_public_url_to': 'promos.image_url',
          'fallback_image_url':
              'https://images.unsplash.com/photo-1607083206968-13611e3d76db?w=1200',
        },
      },
      'limits': const {
        'max_total_promos': 40,
        'max_promos_per_source': 5,
        'max_pages_per_source': 2,
        'prefer_response_under_seconds': 120,
      },
      'period': {
        'month': monthLabel,
        'include_current_month': true,
        'include_active_promos_only': true,
      },
      'target_sources': const [
        'Indomaret',
        'Alfamart',
        'Super Indo',
        'Hypermart',
        'Transmart',
        'Lotte Mart',
        'Farmers Market',
        'Ranch Market',
        'Grand Lucky',
        'Hero Supermarket',
        'Klik Indomaret',
        'Alfagift',
      ],
      'search_queries': [
        'promo supermarket Indonesia $monthLabel',
        'promo minimarket Indonesia $monthLabel',
        'katalog promo Indomaret $monthLabel',
        'katalog promo Alfamart $monthLabel',
        'promo Super Indo $monthLabel',
        'promo Hypermart $monthLabel',
        'promo Transmart $monthLabel',
        'promo Lotte Mart $monthLabel',
        'promo Farmers Market $monthLabel',
      ],
      'output_contract': {
        'format': 'json',
        'preferred_mode': 'direct_supabase_insert',
        'root_key': 'promotions',
        'response_summary_fields': const [
          'direct_insert',
          'inserted_count',
          'skipped_count',
          'failed_count',
          'message',
        ],
        'required_fields': const [
          'product_name',
          'normal_price',
          'promo_price',
          'store_name',
          'category',
          'start_date',
          'end_date',
          'source_url',
        ],
        'optional_fields': const [
          'brand',
          'image_url',
          'unit_size',
          'unit_type',
          'terms',
          'store_address',
          'city',
        ],
        'rules': const [
          'Ambil promo publik dari banyak sumber, bukan satu website saja.',
          'Prioritaskan promo supermarket dan minimarket Indonesia.',
          'Batasi hasil sesuai limits agar webhook cepat mengirim response.',
          'Download image_url produk di n8n lalu upload ke Supabase Storage bucket promo-images.',
          'Simpan public URL dari Supabase Storage ke kolom promos.image_url.',
          'Insert atau upsert stores dan categories sebelum insert promos.',
          'Gunakan Supabase service role hanya di n8n, jangan pernah kirim service role ke Flutter.',
          'Set direct_insert true jika n8n sudah menulis data ke Supabase.',
          'Jika scraping lambat, insert hasil parsial yang valid lebih dulu.',
          'Jangan buat data palsu; kosongkan field opsional jika tidak tersedia.',
          'Normalisasi harga menjadi angka rupiah tanpa simbol.',
          'Gunakan tanggal ISO yyyy-MM-dd jika tersedia.',
          'Jangan masukkan promo expired.',
          'Deduplicate berdasarkan product_name, store_name, end_date, source_url.',
        ],
      },
    };
  }

  String _friendlyDioMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'n8n belum mengirim response. Workflow kemungkinan masih scraping terlalu lama atau belum memakai Respond to Webhook.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 404) {
          return 'Webhook n8n tidak ditemukan. Pastikan workflow aktif dan URL production webhook benar.';
        }
        return 'n8n mengembalikan error HTTP ${statusCode ?? '-'}.'; 
      case DioExceptionType.connectionError:
        return 'Tidak bisa terhubung ke n8n. Cek internet atau status n8n cloud.';
      case DioExceptionType.cancel:
        return 'Sync n8n dibatalkan.';
      case DioExceptionType.badCertificate:
        return 'Koneksi ke n8n ditolak karena sertifikat SSL bermasalah.';
      case DioExceptionType.unknown:
        return 'Gagal memanggil n8n: ${error.message ?? 'error tidak diketahui'}.';
    }
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
    final storeName = _firstString(map, const [
          'store_name',
          'store',
          'merchant',
          'source_name',
          'retailer',
        ]) ??
        _hostFromUrl(sourceUrl) ??
        'n8n Promo Source';

    return PromoModel(
      id: 0,
      productName: title.trim(),
      brand: _firstString(map, const ['brand']) ?? storeName,
      imageUrl: _validImageUrl(_firstString(map, const ['image_url', 'image'])),
      normalPrice: safeNormalPrice.toDouble(),
      promoPrice: safePromoPrice.toDouble(),
      unitSize: _firstNumber(map, const ['unit_size', 'size']) ?? 1,
      unitType: _firstString(map, const ['unit_type', 'unit']) ?? 'pcs',
      storeName: storeName,
      storeAddress: _firstString(
            map,
            const ['store_address', 'address', 'location'],
          ) ??
          'Sumber promo dari n8n',
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

  int? _findInt(dynamic payload, List<String> keys) {
    final text = _findString(payload, keys);
    if (text != null) return int.tryParse(text);
    if (payload is Map) {
      final map = _stringKeyedMap(payload);
      for (final key in keys) {
        final value = map[key];
        if (value is num) return value.toInt();
      }
      for (final value in map.values) {
        final found = _findInt(value, keys);
        if (found != null) return found;
      }
    }
    if (payload is List) {
      for (final value in payload) {
        final found = _findInt(value, keys);
        if (found != null) return found;
      }
    }
    return null;
  }

  bool? _findBool(dynamic payload, List<String> keys) {
    if (payload is Map) {
      final map = _stringKeyedMap(payload);
      for (final key in keys) {
        final value = map[key];
        if (value is bool) return value;
        if (value is String) return value.toLowerCase() == 'true';
      }
      for (final value in map.values) {
        final found = _findBool(value, keys);
        if (found != null) return found;
      }
    }
    if (payload is List) {
      for (final value in payload) {
        final found = _findBool(value, keys);
        if (found != null) return found;
      }
    }
    return null;
  }

  String? _hostFromUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri?.host.replaceFirst('www.', '');
  }

  String _validImageUrl(String? value) {
    final uri = Uri.tryParse(value?.trim() ?? '');
    if (uri == null || !uri.hasScheme) return PromoImage.fallbackImageUrl;
    return value!.trim();
  }
}

class PromoImportResult {
  const PromoImportResult({
    required this.importedPromos,
    required this.rawCount,
    required this.sourceName,
    this.insertedCount = 0,
    this.isDirectSupabaseInsert = false,
  });

  final List<PromoModel> importedPromos;
  final int rawCount;
  final String sourceName;
  final int insertedCount;
  final bool isDirectSupabaseInsert;
}

class N8nPromoImportException implements Exception {
  const N8nPromoImportException(this.message);

  final String message;

  @override
  String toString() => message;
}
