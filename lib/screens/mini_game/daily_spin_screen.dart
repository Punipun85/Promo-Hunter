import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../providers/dashboard_experience_provider.dart';
import '../../utils/date_formatter.dart';

class DailySpinScreen extends StatefulWidget {
  const DailySpinScreen({super.key});

  @override
  State<DailySpinScreen> createState() => _DailySpinScreenState();
}

class _DailySpinScreenState extends State<DailySpinScreen> {
  final Random _random = Random();

  bool _isSpinning = false;
  int _highlightedIndex = 0;
  DailySpinResult? _lastResult;

  Future<void> _spin() async {
    final experience = context.read<DashboardExperienceProvider>();
    if (!experience.canSpinDaily) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daily Spin hari ini sudah dipakai.')),
      );
      return;
    }

    final finalIndex =
        _random.nextInt(DashboardExperienceProvider.dailySpinRewards.length);
    setState(() {
      _isSpinning = true;
      _lastResult = null;
    });

    for (var i = 0; i < 18 + finalIndex; i++) {
      await Future<void>.delayed(Duration(milliseconds: 55 + (i * 4)));
      if (!mounted) return;
      setState(() {
        _highlightedIndex =
            (_highlightedIndex + 1) %
                DashboardExperienceProvider.dailySpinRewards.length;
      });
    }

    final result = await experience.spinDailyReward(forcedIndex: finalIndex);
    if (!mounted) return;
    setState(() {
      _highlightedIndex = finalIndex;
      _isSpinning = false;
      _lastResult = result;
    });

    final reward = result.reward;
    final message = result.isAlreadyClaimed
        ? 'Daily Spin hari ini sudah diklaim.'
        : reward?.isVoucher == true
            ? 'Voucher ${result.redeemedVoucher?.title ?? reward?.title} masuk ke wallet.'
            : 'Kamu mendapatkan ${result.coinsEarned} coin.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final experience = context.watch<DashboardExperienceProvider>();
    final now = DateTime.now();
    final tomorrowReset = DateTime(now.year, now.month, now.day + 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Spin'),
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
                  'Spin harian pemburu promo',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Dapatkan coin atau voucher tanpa harus premium. Satu kesempatan tersedia setiap hari.',
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
                      label: experience.canSpinDaily
                          ? 'Spin tersedia'
                          : 'Sudah spin hari ini',
                      icon: Icons.casino_outlined,
                    ),
                    _StatusChip(
                      label: '${experience.coinBalance} coin',
                      icon: Icons.monetization_on_outlined,
                    ),
                    const _StatusChip(
                      label: 'Coin atau voucher',
                      icon: Icons.redeem_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SpinBoard(
            highlightedIndex: _highlightedIndex,
            isSpinning: _isSpinning,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed:
                experience.canSpinDaily && !_isSpinning ? _spin : null,
            icon: Icon(_isSpinning ? Icons.sync_rounded : Icons.casino),
            label: Text(
              _isSpinning
                  ? 'Sedang spin...'
                  : experience.canSpinDaily
                      ? 'Spin Sekarang'
                      : 'Spin Sudah Diklaim',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.wallet),
            icon: const Icon(Icons.confirmation_number_outlined),
            label: const Text('Lihat voucher di wallet'),
          ),
          const SizedBox(height: 18),
          _ResultCard(
            result: _lastResult,
            fallbackText: experience.canSpinDaily
                ? 'Tekan Spin Sekarang untuk melihat hadiah hari ini.'
                : 'Kesempatan spin berikutnya tersedia pada ${DateFormatter.short(tomorrowReset)}.',
          ),
        ],
      ),
    );
  }
}

class _SpinBoard extends StatelessWidget {
  const _SpinBoard({
    required this.highlightedIndex,
    required this.isSpinning,
  });

  final int highlightedIndex;
  final bool isSpinning;

  @override
  Widget build(BuildContext context) {
    const rewards = DashboardExperienceProvider.dailySpinRewards;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rewards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.34,
      ),
      itemBuilder: (context, index) {
        final reward = rewards[index];
        final selected = highlightedIndex == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFF0A8) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFFE2E8F0),
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.24),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                reward.icon,
                color: selected
                    ? const Color(0xFF92400E)
                    : Theme.of(context).colorScheme.secondary,
              ),
              const Spacer(),
              Text(
                reward.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                isSpinning && selected ? 'Berputar...' : reward.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.result,
    required this.fallbackText,
  });

  final DailySpinResult? result;
  final String fallbackText;

  @override
  Widget build(BuildContext context) {
    final reward = result?.reward;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            reward?.icon ?? Icons.info_outline_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward == null ? 'Hadiah Daily Spin' : reward.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  reward == null
                      ? fallbackText
                      : reward.isVoucher
                          ? 'Voucher berhasil ditambahkan ke wallet kamu.'
                          : '${result?.coinsEarned ?? 0} coin berhasil ditambahkan ke saldo.',
                ),
              ],
            ),
          ),
        ],
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
