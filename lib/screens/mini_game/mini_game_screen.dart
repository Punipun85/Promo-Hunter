import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../providers/dashboard_experience_provider.dart';

class MiniGameScreen extends StatelessWidget {
  const MiniGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final experience = context.watch<DashboardExperienceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini Games'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.wallet),
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: 'Buka wallet',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Main gratis, kumpulkan reward',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pilih game harian untuk mendapatkan coin atau voucher tanpa harus langganan premium.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.86),
                      ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _StatusChip(
                      label: '${experience.coinBalance} coin',
                      icon: Icons.monetization_on_outlined,
                    ),
                    _StatusChip(
                      label: experience.canSpinDaily
                          ? 'Spin tersedia'
                          : 'Spin sudah diklaim',
                      icon: Icons.casino_outlined,
                    ),
                    _StatusChip(
                      label:
                          'Coin Rush ${experience.miniGameRemainingAttempts}/3',
                      icon: Icons.style_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _GameCard(
            title: 'Daily Spin',
            subtitle:
                'Putar sekali sehari untuk hadiah coin atau voucher langsung ke wallet.',
            icon: Icons.casino_outlined,
            badge: experience.canSpinDaily ? 'Gratis hari ini' : 'Sudah spin',
            accentColor: const Color(0xFFF59E0B),
            onTap: () => Navigator.pushNamed(context, AppRoutes.dailySpin),
          ),
          const SizedBox(height: 14),
          _GameCard(
            title: 'Coin Rush',
            subtitle:
                'Game kartu 5 ronde. Temukan kartu coin dan kumpulkan skor terbaik.',
            icon: Icons.style_outlined,
            badge: '${experience.miniGameRemainingAttempts} kesempatan',
            accentColor: const Color(0xFF0F9D58),
            onTap: () => Navigator.pushNamed(context, AppRoutes.coinRush),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.wallet),
            icon: const Icon(Icons.confirmation_number_outlined),
            label: const Text('Lihat coin dan voucher'),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badge,
    required this.accentColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String badge;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: accentColor),
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
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0A8),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badge,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: const Color(0xFF7C5A00),
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(subtitle),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
        ],
      ),
    );
  }
}
