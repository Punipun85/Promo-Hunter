import 'package:dio/dio.dart';

import '../config/midtrans_config.dart';

class MidtransInvoiceService {
  MidtransInvoiceService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<MidtransInvoiceResult> createInvoice({
    required String transactionId,
    required String itemName,
    required int amount,
    required String customerName,
    required String customerEmail,
    required String transactionType,
    String? preferredPaymentMethod,
    List<String>? enabledPayments,
    String? paymentType,
    Map<String, dynamic>? paymentPayload,
  }) async {
    if (!MidtransConfig.isConfigured) {
      throw const MidtransInvoiceException(
        'MIDTRANS_INVOICE_PROXY_URL belum diatur. Gunakan n8n/Supabase Edge Function sebagai proxy aman.',
      );
    }

    try {
      final payload = <String, dynamic>{
        'source': 'promohunter_flutter',
        'environment': MidtransConfig.isSandbox ? 'sandbox' : 'production',
        'transaction_id': transactionId,
        'order_id': transactionId,
        'item_name': itemName,
        'amount': amount,
        'gross_amount': amount,
        'currency': 'IDR',
        'transaction_type': transactionType,
        'customer': {
          'name': customerName,
          'email': customerEmail,
        },
      };
      if (preferredPaymentMethod != null &&
          preferredPaymentMethod.trim().isNotEmpty) {
        payload['preferred_payment_method'] = preferredPaymentMethod.trim();
      }
      if (enabledPayments != null && enabledPayments.isNotEmpty) {
        payload['enabled_payments'] = enabledPayments;
      }
      if (paymentType != null && paymentType.trim().isNotEmpty) {
        payload['payment_type'] = paymentType.trim();
      }
      if (paymentPayload != null) {
        payload.addAll(paymentPayload);
      }

      final response = await _dio.post<dynamic>(
        MidtransConfig.invoiceProxyUrl,
        data: payload,
        options: Options(
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
          sendTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 45),
          headers: const {
            'Accept': 'application/json',
          },
        ),
      );

      final data = response.data;
      final invoiceUrl = _findString(data, const [
        'invoice_url',
        'payment_url',
        'redirect_url',
        'invoiceUrl',
        'paymentUrl',
        'url',
      ]);
      final simulatorUrl = _findString(data, const [
        'simulator_url',
        'simulatorUrl',
      ]);
      final qrCodeUrl = _findString(data, const [
        'qr_code_url',
        'qrCodeUrl',
      ]);
      final invoiceId = _findString(data, const [
            'invoice_id',
            'payment_id',
            'id',
            'order_id',
            'transaction_id',
            'token',
          ]) ??
          transactionId;

      final resolvedInvoiceUrl = invoiceUrl ?? simulatorUrl;
      if (resolvedInvoiceUrl == null || resolvedInvoiceUrl.isEmpty) {
        throw const MidtransInvoiceException(
          'Proxy Midtrans merespons, tetapi tidak mengirim invoice_url/payment_url maupun simulator_url.',
        );
      }

      return MidtransInvoiceResult(
        invoiceId: invoiceId,
        invoiceUrl: resolvedInvoiceUrl,
        qrCodeUrl: qrCodeUrl,
        simulatorUrl: simulatorUrl,
        raw: data,
      );
    } on DioException catch (error) {
      throw MidtransInvoiceException(_friendlyDioMessage(error));
    }
  }

  String _friendlyDioMessage(DioException error) {
    final statusCode = error.response?.statusCode;
    final serverMessage = _findString(error.response?.data, const [
      'message',
      'error',
      'status_message',
    ]);
    if (serverMessage != null && serverMessage.isNotEmpty) {
      return 'Gagal membuat invoice Midtrans: $serverMessage';
    }
    if (statusCode != null) {
      return 'Gagal membuat invoice Midtrans. Status proxy: $statusCode.';
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Proxy Midtrans terlalu lama merespons. Coba lagi sebentar.';
    }
    return 'Gagal menghubungi proxy Midtrans. Pastikan URL webhook aktif.';
  }

  String? _findString(dynamic value, List<String> keys) {
    if (value is Map) {
      for (final key in keys) {
        final direct = value[key];
        if (direct is String && direct.trim().isNotEmpty) {
          return direct.trim();
        }
        if (direct is num) return direct.toString();
      }
      for (final entry in value.values) {
        final nested = _findString(entry, keys);
        if (nested != null) return nested;
      }
    }
    if (value is List) {
      for (final item in value) {
        final nested = _findString(item, keys);
        if (nested != null) return nested;
      }
    }
    return null;
  }
}

class MidtransInvoiceResult {
  const MidtransInvoiceResult({
    required this.invoiceId,
    required this.invoiceUrl,
    this.qrCodeUrl,
    this.simulatorUrl,
    required this.raw,
  });

  final String invoiceId;
  final String invoiceUrl;
  final String? qrCodeUrl;
  final String? simulatorUrl;
  final dynamic raw;
}

class MidtransInvoiceException implements Exception {
  const MidtransInvoiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
