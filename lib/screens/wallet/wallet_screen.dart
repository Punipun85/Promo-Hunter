import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/dashboard_experience_provider.dart';
import '../../utils/currency_formatter.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final experience = context.watch<DashboardExperienceProvider>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Topup & Langganan'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.monetization_on_outlined), text: 'Coin'),
              Tab(icon: Icon(Icons.workspace_premium_outlined), text: 'Premium'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _CoinTab(experience: experience),
            _PremiumTab(experience: experience),
          ],
        ),
      ),
    );
  }
}

class _CoinTab extends StatelessWidget {
  const _CoinTab({required this.experience});

  final DashboardExperienceProvider experience;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _BalanceHeader(
          title: '${experience.coinBalance} Coin',
          subtitle:
              'Gunakan coin untuk membuka promo early access. Setiap unlock butuh ${DashboardExperienceProvider.unlockCost} coin.',
          icon: Icons.monetization_on_outlined,
        ),
        const SizedBox(height: 18),
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
      ],
    );
  }
}

class _PremiumTab extends StatelessWidget {
  const _PremiumTab({required this.experience});

  final DashboardExperienceProvider experience;

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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0A8),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badge!,
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: const Color(0xFF7C5A00),
                                    ),
                          ),
                        ),
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
                  FilledButton.tonalIcon(
                    onPressed: onTap == null
                        ? null
                        : () async {
                    await onTap!();
                  },
                    icon: Icon(onTap == null
                        ? Icons.check_circle_outline
                        : Icons.shopping_bag_outlined),
                    label: Text(onTap == null ? 'Sudah Aktif' : actionLabel),
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
