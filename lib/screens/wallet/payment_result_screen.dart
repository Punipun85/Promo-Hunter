import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../providers/dashboard_experience_provider.dart';

class PaymentResultScreen extends StatefulWidget {
  const PaymentResultScreen({
    super.key,
    required this.orderId,
    required this.result,
  });

  final String orderId;
  final String result;

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen> {
  PaymentStatus? _resolvedStatus;
  bool _isLoading = true;
  bool _hasRedirected = false;

  @override
  void initState() {
    super.initState();
    _resolveStatus();
  }

  Future<void> _resolveStatus() async {
    final experience = context.read<DashboardExperienceProvider>();
    final status = await experience.waitForMidtransResultByReference(
      widget.orderId,
    );
    if (!mounted) return;
    setState(() {
      _resolvedStatus = status;
      _isLoading = false;
    });
    _redirectIfNeeded(status);
  }

  void _redirectIfNeeded(PaymentStatus? status) {
    if (!mounted || _hasRedirected) return;
    if (status != PaymentStatus.approved) return;

    _hasRedirected = true;
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.wallet,
        (route) => route.settings.name == AppRoutes.home,
      );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Pembayaran berhasil. Saldo coin atau premium sudah aktif.',
            ),
          ),
        );
    });
  }

  @override
  Widget build(BuildContext context) {
    final experience = context.watch<DashboardExperienceProvider>();
    final normalizedResult = widget.result.toLowerCase();
    final effectiveStatus = _resolvedStatus;
    final matchingTransaction = experience.paymentTransactions.cast<PaymentTransaction?>().firstWhere(
          (item) => item?.paymentReference == widget.orderId,
          orElse: () => null,
        );

    final isSuccess = effectiveStatus == PaymentStatus.approved ||
        (effectiveStatus == null && normalizedResult == 'success');
    final isFailed = effectiveStatus == PaymentStatus.rejected ||
        normalizedResult == 'failure' ||
        normalizedResult == 'error';

    final icon = _isLoading
        ? Icons.sync_rounded
        : isSuccess
            ? Icons.check_circle_rounded
            : isFailed
                ? Icons.cancel_rounded
                : Icons.hourglass_top_rounded;
    final color = _isLoading
        ? const Color(0xFF2563EB)
        : isSuccess
            ? const Color(0xFF059669)
            : isFailed
                ? const Color(0xFFDC2626)
                : const Color(0xFFF59E0B);
    final title = _isLoading
        ? 'Mengecek status pembayaran'
        : isSuccess
            ? 'Pembayaran berhasil'
            : isFailed
                ? 'Pembayaran gagal'
                : 'Pembayaran masih diproses';
    final message = _isLoading
        ? 'PromoHunter sedang menunggu konfirmasi Midtrans Sandbox untuk order ${widget.orderId}.'
        : isSuccess
            ? 'Midtrans sudah mengonfirmasi pembayaran. Kamu akan kembali otomatis ke halaman topup dan saldo atau premium langsung aktif.'
            : isFailed
                ? 'Pembayaran tidak berhasil diselesaikan. Kamu bisa kembali ke halaman topup untuk mencoba lagi.'
                : 'Halaman ini sudah kembali dari Midtrans, tetapi status akhir belum masuk. Coba kembali ke halaman topup dan tunggu sebentar.';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Status Pembayaran'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: _isLoading
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: CircularProgressIndicator(
                            color: color,
                            strokeWidth: 3,
                          ),
                        )
                      : Icon(icon, size: 48, color: color),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF475569),
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Order ID: ${widget.orderId}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                ),
                if (matchingTransaction != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    '${matchingTransaction.itemName} • ${matchingTransaction.type.label}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF475569),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
                const SizedBox(height: 24),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    if (matchingTransaction != null)
                      FilledButton.tonalIcon(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.paymentDetail,
                          arguments: matchingTransaction,
                        ),
                        icon: const Icon(Icons.receipt_long_rounded),
                        label: const Text('Lihat Detail Pembayaran'),
                      ),
                    if (!isSuccess)
                      FilledButton.icon(
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.wallet,
                          (route) => route.settings.name == AppRoutes.home,
                        ),
                        icon: const Icon(Icons.account_balance_wallet_outlined),
                        label: const Text('Kembali ke Topup'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
