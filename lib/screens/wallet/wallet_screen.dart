import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_experience_provider.dart';
import '../../utils/date_formatter.dart';
import '../../utils/currency_formatter.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final experience = context.watch<DashboardExperienceProvider>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Topup & Langganan'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.monetization_on_outlined), text: 'Coin'),
              Tab(
                  icon: Icon(Icons.workspace_premium_outlined),
                  text: 'Premium'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _CoinTab(
              experience: experience,
              isLoggedIn: auth.isLoggedIn,
            ),
            _PremiumTab(
              experience: experience,
              isLoggedIn: auth.isLoggedIn,
            ),
          ],
        ),
      ),
    );
  }
}

class _CoinTab extends StatelessWidget {
  const _CoinTab({
    required this.experience,
    required this.isLoggedIn,
  });

  final DashboardExperienceProvider experience;
  final bool isLoggedIn;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _BalanceHeader(
          title: '${experience.coinBalance} Coin',
          subtitle:
              'Gunakan coin untuk membuka promo early access, main mini game, atau tukar voucher.',
          icon: Icons.monetization_on_outlined,
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.miniGame),
          icon: const Icon(Icons.sports_esports_outlined),
          label: const Text('Main Mini Game'),
        ),
        const SizedBox(height: 16),
        ...DashboardExperienceProvider.coinPackages.map(
          (package) => _PackageCard(
            title: package.name,
            badge: package.isRecommended ? 'Rekomendasi' : null,
            value: '${package.coins} coin',
            price: CurrencyFormatter.format(package.price),
            description: package.description,
            icon: Icons.toll_outlined,
            actionLabel: 'Topup',
            onTap: () async {
              if (!isLoggedIn) {
                await _showGuestRequiredDialog(context);
                return;
              }
              final paid = await _showTransactionDialog(
                context,
                title: 'Konfirmasi Topup Coin',
                itemName: package.name,
                value: '${package.coins} coin',
                price: package.price,
                description:
                    'Coin akan masuk ke saldo akun setelah transaksi demo ini dikonfirmasi.',
              );
              if (paid != true) return;
              await experience.topUpCoins(package);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${package.coins} coin berhasil ditambahkan.',
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        const _SectionTitle(
          title: 'Tukar Voucher',
          subtitle:
              'Ubah coin hasil top up atau mini game menjadi voucher yang bisa dipakai lagi.',
        ),
        const SizedBox(height: 12),
        ...DashboardExperienceProvider.voucherCatalog.map(
          (voucher) {
            final canRedeem = experience.coinBalance >= voucher.coinCost;
            return _PackageCard(
              title: voucher.title,
              badge: 'Voucher',
              value: '${voucher.coinCost} coin',
              price: voucher.benefitLabel,
              description: voucher.description,
              icon: voucher.icon,
              actionLabel: 'Tukar',
              onTap: canRedeem
                  ? () async {
                      final redemption =
                          await experience.redeemVoucher(voucher.id);
                      if (!context.mounted || redemption == null) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Voucher ${redemption.title} didapatkan. Kode: ${redemption.code}',
                          ),
                        ),
                      );
                    }
                  : null,
            );
          },
        ),
        if (experience.redeemedVouchers.isNotEmpty) ...[
          const SizedBox(height: 6),
          const _SectionTitle(
            title: 'Voucher Kamu',
            subtitle: 'Voucher yang sudah ditukar akan tersimpan di sini.',
          ),
          const SizedBox(height: 12),
          ...experience.redeemedVouchers.map(
            (voucher) => _RedeemedVoucherCard(voucher: voucher),
          ),
        ],
      ],
    );
  }
}

class _PremiumTab extends StatelessWidget {
  const _PremiumTab({
    required this.experience,
    required this.isLoggedIn,
  });

  final DashboardExperienceProvider experience;
  final bool isLoggedIn;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _BalanceHeader(
          title: experience.isPremium ? 'Premium Aktif' : 'Premium Belum Aktif',
          subtitle:
              'Paket mulai Rp9.000. Premium membuka semua info promo baru tanpa delay dan tanpa coin.',
          icon: Icons.workspace_premium_outlined,
        ),
        const SizedBox(height: 18),
        ...DashboardExperienceProvider.subscriptionPlans.map(
          (plan) => _PackageCard(
            title: plan.name,
            badge: plan.isRecommended ? 'Paling hemat' : null,
            value: plan.durationLabel,
            price: CurrencyFormatter.format(plan.price),
            description: plan.description,
            icon: Icons.verified_outlined,
            actionLabel: 'Langganan',
            onTap: experience.isPremium
                ? null
                : () async {
                    if (!isLoggedIn) {
                      await _showGuestRequiredDialog(context);
                      return;
                    }
                    final paid = await _showTransactionDialog(
                      context,
                      title: 'Konfirmasi Langganan',
                      itemName: plan.name,
                      value: plan.durationLabel,
                      price: plan.price,
                      description:
                          'Premium akan aktif setelah transaksi demo ini dikonfirmasi.',
                    );
                    if (paid != true) return;
                    await experience.subscribeToPlan(plan);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${plan.name} berhasil diaktifkan.'),
                      ),
                    );
                  },
          ),
        ),
      ],
    );
  }
}

Future<void> _showGuestRequiredDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titlePadding: const EdgeInsets.fromLTRB(24, 18, 14, 0),
        title: Row(
          children: [
            const Expanded(child: Text('Anda belum mendaftar akun')),
            IconButton(
              tooltip: 'Tutup',
              onPressed: () => Navigator.pop(dialogContext),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        content: const Text(
          'Topup coin dan langganan premium hanya bisa dilakukan setelah kamu login atau membuat akun PromoHunter.',
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
        actions: [
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    Navigator.pushNamed(context, AppRoutes.login);
                  },
                  child: const Text('Login'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    Navigator.pushNamed(context, AppRoutes.register);
                  },
                  child: const Text('Daftar'),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}

Future<bool?> _showTransactionDialog(
  BuildContext context, {
  required String title,
  required String itemName,
  required String value,
  required int price,
  required String description,
}) {
  const paymentMethod = 'E-Wallet PromoPay';
  final invoiceCode =
      'PH-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titlePadding: const EdgeInsets.fromLTRB(24, 18, 14, 0),
        title: Row(
          children: [
            Expanded(child: Text(title)),
            IconButton(
              tooltip: 'Tutup',
              onPressed: () => Navigator.pop(dialogContext, false),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF4FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TransactionRow(label: 'Invoice', value: invoiceCode),
                  const SizedBox(height: 8),
                  _TransactionRow(label: 'Paket', value: itemName),
                  const SizedBox(height: 8),
                  _TransactionRow(label: 'Benefit', value: value),
                  const SizedBox(height: 8),
                  const _TransactionRow(
                    label: 'Metode',
                    value: paymentMethod,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(description),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Bayar',
                  style: Theme.of(dialogContext).textTheme.titleSmall,
                ),
                Text(
                  CurrencyFormatter.format(price),
                  style: Theme.of(dialogContext).textTheme.titleMedium?.copyWith(
                        color: Theme.of(dialogContext).colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Bayar Sekarang'),
            ),
          ),
        ],
      );
    },
  );
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
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
    );
  }
}

class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.86),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.title,
    required this.value,
    required this.price,
    required this.description,
    required this.icon,
    required this.actionLabel,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String value;
  final String price;
  final String description;
  final IconData icon;
  final String actionLabel;
  final Future<void> Function()? onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF4FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.secondary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (badge != null) _PackageBadge(label: badge!),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(description),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        value,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      Text(price),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: onTap == null
                        ? null
                        : () async {
                            await onTap!();
                          },
                    child: Text(onTap == null ? 'Sudah Aktif' : actionLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageBadge extends StatelessWidget {
  const _PackageBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0A8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFF7C5A00),
            ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(subtitle),
      ],
    );
  }
}

class _RedeemedVoucherCard extends StatelessWidget {
  const _RedeemedVoucherCard({required this.voucher});

  final RedeemedVoucher voucher;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF4FF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.confirmation_num_outlined,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        title: Text(voucher.title),
        subtitle: Text(
          '${voucher.benefitLabel}\nKode ${voucher.code}\nDitukar ${DateFormatter.dateTime(voucher.redeemedAt)}',
        ),
        isThreeLine: true,
      ),
    );
  }
}
