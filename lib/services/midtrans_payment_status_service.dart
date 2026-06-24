import 'supabase_service.dart';

class MidtransPaymentStatusService {
  MidtransPaymentStatusService([SupabaseService? supabaseService])
      : _supabaseService = supabaseService ?? const SupabaseService();

  final SupabaseService _supabaseService;

  Future<MidtransPaymentStatus?> getStatus(String orderId) async {
    final client = _supabaseService.clientOrNull;
    final normalized = orderId.trim();
    if (client == null || normalized.isEmpty) return null;

    try {
      final response = await client
          .from('midtrans_payment_statuses')
          .select()
          .eq('order_id', normalized)
          .maybeSingle();
      if (response == null) return null;
      return MidtransPaymentStatus.fromMap(response);
    } catch (_) {
      return null;
    }
  }
}

class MidtransPaymentStatus {
  const MidtransPaymentStatus({
    required this.orderId,
    required this.paid,
    required this.failed,
    this.transactionStatus,
    this.fraudStatus,
    this.paymentType,
    this.signatureVerified,
  });

  final String orderId;
  final bool paid;
  final bool failed;
  final String? transactionStatus;
  final String? fraudStatus;
  final String? paymentType;
  final bool? signatureVerified;

  factory MidtransPaymentStatus.fromMap(Map<String, dynamic> map) {
    return MidtransPaymentStatus(
      orderId: map['order_id'] as String? ?? '',
      paid: map['paid'] as bool? ?? false,
      failed: map['failed'] as bool? ?? false,
      transactionStatus: map['transaction_status'] as String?,
      fraudStatus: map['fraud_status'] as String?,
      paymentType: map['payment_type'] as String?,
      signatureVerified: map['signature_verified'] as bool?,
    );
  }
}
