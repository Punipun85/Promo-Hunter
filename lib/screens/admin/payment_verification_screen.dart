import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/dashboard_experience_provider.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/empty_state.dart';

class PaymentVerificationScreen extends StatelessWidget {
  const PaymentVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final experience = context.watch<DashboardExperienceProvider>();

    if (!auth.isAdmin) {
      return const Scaffold(
        body: EmptyState(
          title: 'Akses ditolak',
          subtitle: 'Verifikasi pembayaran hanya bisa dilakukan admin.',
          icon: Icons.lock_outline,
        ),
      );
    }

    final transactions = [...experience.paymentTransactions]..sort((a, b) {
        final statusCompare = a.status.index.compareTo(b.status.index);
        if (statusCompare != 0) return statusCompare;
        return b.createdAt.compareTo(a.createdAt);
      });
    final pendingCount = experience.pendingPaymentTransactions.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Verifikasi Pembayaran')),
      body: transactions.isEmpty
          ? const EmptyState(
              title: 'Belum ada transaksi',
              subtitle:
                  'Transaksi topup coin dan premium akan muncul setelah user mengirim bukti pembayaran.',
              icon: Icons.receipt_long_outlined,
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF4FF),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.fact_check_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          pendingCount == 0
                              ? 'Tidak ada pembayaran yang menunggu verifikasi.'
                              : '$pendingCount pembayaran menunggu keputusan admin.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...transactions.map(
                  (transaction) => _AdminPaymentCard(
                    transaction: transaction,
                    onApprove: () async {
                      await experience
                          .approvePaymentTransaction(transaction.id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${transaction.itemName} disetujui.',
                          ),
                        ),
                      );
                    },
                    onReject: () async {
                      await experience.rejectPaymentTransaction(transaction.id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${transaction.itemName} ditolak.',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _AdminPaymentCard extends StatelessWidget {
  const _AdminPaymentCard({
    required this.transaction,
    required this.onApprove,
    required this.onReject,
  });

  final PaymentTransaction transaction;
  final Future<void> Function() onApprove;
  final Future<void> Function() onReject;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (transaction.status) {
      PaymentStatus.pending => const Color(0xFFF59E0B),
      PaymentStatus.approved => const Color(0xFF059669),
      PaymentStatus.rejected => const Color(0xFFDC2626),
    };
    final canVerify = transaction.status == PaymentStatus.pending;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    transaction.itemName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _AdminStatusBadge(
                  label: transaction.status.label,
                  color: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${transaction.type.label} - ${transaction.benefitLabel}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
            ),
            const SizedBox(height: 14),
            _InfoRow(label: 'User', value: transaction.userName),
            _InfoRow(label: 'Email', value: transaction.userEmail),
            _InfoRow(
              label: 'Total',
              value: CurrencyFormatter.format(transaction.price),
            ),
            _InfoRow(label: 'Metode', value: transaction.paymentMethod),
            _InfoRow(label: 'Bukti', value: transaction.proofFileName),
            if (transaction.paymentReference != null)
              _InfoRow(label: 'Ref', value: transaction.paymentReference!),
            if (transaction.paymentUrl != null)
              _InfoRow(label: 'Link', value: transaction.paymentUrl!),
            _InfoRow(
              label: 'Dibuat',
              value: DateFormatter.dateTime(transaction.createdAt),
            ),
            if (transaction.verifiedAt != null)
              _InfoRow(
                label: 'Diproses',
                value: DateFormatter.dateTime(transaction.verifiedAt!),
              ),
            if (canVerify) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Tolak'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
            ),
          ),
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

class _AdminStatusBadge extends StatelessWidget {
  const _AdminStatusBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
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
