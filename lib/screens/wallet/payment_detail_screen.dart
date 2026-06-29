import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/dashboard_experience_provider.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';

class PaymentDetailScreen extends StatefulWidget {
  const PaymentDetailScreen({
    super.key,
    required this.transaction,
  });

  final PaymentTransaction transaction;

  @override
  State<PaymentDetailScreen> createState() => _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends State<PaymentDetailScreen>
    with WidgetsBindingObserver {
  var _isCheckingStatus = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final reference = widget.transaction.paymentReference;
    if (state != AppLifecycleState.resumed ||
        reference == null ||
        reference.trim().isEmpty) {
      return;
    }
    unawaited(_checkStatusInternal(showPendingMessage: false));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkStatus() async {
    await _checkStatusInternal(showPendingMessage: true);
  }

  Future<void> _checkStatusInternal({required bool showPendingMessage}) async {
    final reference = widget.transaction.paymentReference;
    if (reference == null || reference.trim().isEmpty) return;

    setState(() => _isCheckingStatus = true);
    try {
      final provider = context.read<DashboardExperienceProvider>();
      final status =
          await provider.syncMidtransTransactionByReference(reference);
      if (!mounted) return;
      final message = switch (status) {
        PaymentStatus.approved =>
          'Pembayaran sudah dikonfirmasi Midtrans dan transaksi berhasil.',
        PaymentStatus.rejected => 'Pembayaran ditandai gagal atau ditolak.',
        PaymentStatus.pending ||
        null =>
          'Status pembayaran masih menunggu konfirmasi Midtrans.',
      };
      if (!showPendingMessage &&
          (status == PaymentStatus.pending || status == null)) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() => _isCheckingStatus = false);
      }
    }
  }

  Future<void> _openPaymentLink() async {
    final paymentUrl = widget.transaction.paymentUrl;
    if (paymentUrl == null || paymentUrl.trim().isEmpty) return;
    final uri = Uri.tryParse(paymentUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _copyPaymentLink() async {
    final paymentUrl = widget.transaction.paymentUrl;
    if (paymentUrl == null || paymentUrl.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: paymentUrl));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link pembayaran disalin.')),
    );
  }

  Future<void> _openQrisSimulator() async {
    const simulatorUrl = 'https://simulator.sandbox.midtrans.com/v2/qris/index';
    await launchUrl(
      Uri.parse(simulatorUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final experience = context.watch<DashboardExperienceProvider>();
    final transaction = experience.paymentTransactions.firstWhere(
      (item) => item.id == widget.transaction.id,
      orElse: () => widget.transaction,
    );

    final statusColor = switch (transaction.status) {
      PaymentStatus.pending => const Color(0xFFF59E0B),
      PaymentStatus.approved => const Color(0xFF059669),
      PaymentStatus.rejected => const Color(0xFFDC2626),
    };

    final statusIcon = switch (transaction.status) {
      PaymentStatus.pending => Icons.hourglass_top_rounded,
      PaymentStatus.approved => Icons.verified_rounded,
      PaymentStatus.rejected => Icons.cancel_rounded,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pembayaran'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: statusColor.withValues(alpha: 0.24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(statusIcon, color: statusColor),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.itemName,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${transaction.type.label} - ${transaction.benefitLabel}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: const Color(0xFF475569)),
                          ),
                        ],
                      ),
                    ),
                    _DetailStatusBadge(
                      label: transaction.statusLabel,
                      color: statusColor,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _buildStatusDescription(transaction),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF334155),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _DetailSection(
            title: 'Ringkasan',
            children: [
              _DetailRow(
                label: 'Total',
                value: CurrencyFormatter.format(transaction.price),
              ),
              _DetailRow(label: 'Metode', value: transaction.paymentMethod),
              _DetailRow(label: 'Bukti', value: transaction.proofFileName),
              _DetailRow(
                label: 'Tanggal',
                value: DateFormatter.dateTime(transaction.createdAt),
              ),
              if (transaction.verifiedAt != null)
                _DetailRow(
                  label: 'Verifikasi',
                  value: DateFormatter.dateTime(transaction.verifiedAt!),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _DetailSection(
            title: 'Referensi',
            children: [
              _DetailRow(label: 'Transaction ID', value: transaction.id),
              if (transaction.paymentReference != null)
                _DetailRow(
                    label: 'Order / Ref', value: transaction.paymentReference!),
              if (transaction.paymentUrl != null)
                _DetailRow(
                    label: 'Link Pembayaran', value: transaction.paymentUrl!),
              _DetailRow(label: 'User', value: transaction.userName),
              _DetailRow(label: 'Email', value: transaction.userEmail),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (transaction.paymentUrl != null)
                FilledButton.tonalIcon(
                  onPressed: _openPaymentLink,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Buka Halaman Bayar'),
                ),
              if (transaction.paymentUrl != null)
                OutlinedButton.icon(
                  onPressed: _copyPaymentLink,
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Salin Link'),
                ),
              if (transaction.paymentMethod.toLowerCase().contains('qris'))
                OutlinedButton.icon(
                  onPressed: _openQrisSimulator,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Buka Simulator QRIS'),
                ),
              if (transaction.paymentReference != null)
                FilledButton.icon(
                  onPressed: _isCheckingStatus ? null : _checkStatus,
                  icon: _isCheckingStatus
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync_rounded),
                  label: const Text('Cek Status Sekarang'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _buildStatusDescription(PaymentTransaction transaction) {
    switch (transaction.status) {
      case PaymentStatus.pending:
        if (transaction.isMidtransPayment) {
          return 'Pembayaran sudah dibuat dan sedang menunggu konfirmasi otomatis dari Midtrans. Jika status di Midtrans sudah berhasil, gunakan tombol cek status untuk menyinkronkan hasil terbaru.';
        }
        return 'Transaksi masih menunggu verifikasi manual dari admin.';
      case PaymentStatus.approved:
        return 'Pembayaran sudah berhasil. Coin atau premium dari transaksi ini sudah diaktifkan di akun kamu.';
      case PaymentStatus.rejected:
        return 'Pembayaran ditandai gagal atau ditolak. Kamu bisa membuat transaksi baru jika ingin mencoba lagi.';
    }
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailStatusBadge extends StatelessWidget {
  const _DetailStatusBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}
