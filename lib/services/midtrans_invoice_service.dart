import 'package:dio/dio.dart';

import '../config/midtrans_config.dart';

class MidtransInvoiceService {
  MidtransInvoiceService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  static const _maxProxyAttempts = 3;

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
        'MIDTRANS_INVOICE_PROXY_URL belum diatur. Gunakan Activepieces atau backend invoice lain sebagai proxy aman.',
      );
    }

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

    DioException? lastDioError;

    for (var attempt = 1; attempt <= _maxProxyAttempts; attempt += 1) {
      try {
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
          final proxyMessage = _findString(data, const [
            'message',
            'error',
            'status_message',
          ]);
          if (proxyMessage != null && proxyMessage.isNotEmpty) {
            if (proxyMessage.toLowerCase() == 'error in workflow') {
              throw const MidtransInvoiceException(
                'Workflow proxy Midtrans sedang gagal sebelum invoice dibuat. Cek status automation backend seperti Activepieces.',
              );
            }
            throw MidtransInvoiceException(
              'Proxy Midtrans gagal membuat invoice: $proxyMessage',
            );
          }
          throw const MidtransInvoiceException(
            'Proxy Midtrans merespons, tetapi tidak mengirim URL pembayaran. Cek workflow invoice backend karena invoice kemungkinan gagal dibuat.',
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
        lastDioError = error;
        if (!_shouldRetryProxyError(error) || attempt == _maxProxyAttempts) {
          break;
        }
        await Future<void>.delayed(Duration(seconds: attempt));
      }
    }

    if (lastDioError != null) {
      throw MidtransInvoiceException(_friendlyDioMessage(lastDioError));
    }

    throw const MidtransInvoiceException(
      'Gagal membuat invoice Midtrans karena proxy tidak merespons seperti yang diharapkan.',
    );
  }

  String _friendlyDioMessage(DioException error) {
    final statusCode = error.response?.statusCode;
    final serverMessage = _findString(error.response?.data, const [
      'message',
      'error',
      'status_message',
    ]);
    if (serverMessage != null && serverMessage.isNotEmpty) {
      if (serverMessage.toLowerCase() == 'error in workflow') {
        return 'Workflow proxy Midtrans sedang gagal sebelum invoice dibuat. Cek status automation backend seperti Activepieces.';
      }
      return 'Gagal membuat invoice Midtrans: $serverMessage';
    }
    if (statusCode != null) {
      if (statusCode == 408) {
        return 'Proxy invoice Midtrans timeout di sisi backend. Biasanya webhook Activepieces sedang lambat atau cold start. Coba lagi beberapa detik lagi.';
      }
      if (statusCode >= 500) {
        return 'Proxy invoice Midtrans sedang bermasalah di backend (status $statusCode). Coba lagi sebentar.';
      }
      return 'Gagal membuat invoice Midtrans. Status proxy: $statusCode.';
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Proxy Midtrans terlalu lama merespons. Coba lagi sebentar.';
    }
    return 'Gagal menghubungi proxy Midtrans. Pastikan URL webhook aktif.';
  }

  bool _shouldRetryProxyError(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode == null) {
      return error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError;
    }
    return statusCode == 408 ||
        statusCode == 429 ||
        statusCode == 500 ||
        statusCode == 502 ||
        statusCode == 503 ||
        statusCode == 504;
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
