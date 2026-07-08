import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_experience_provider.dart';

class DailyClaimScreen extends StatelessWidget {
  const DailyClaimScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final experience = context.watch<DashboardExperienceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Claim'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: auth.isLoggedIn
              ? auth.isAdmin
                  ? _AdminRewardView(coinBalance: experience.coinBalance)
                  : _DailyClaimContent(experience: experience)
              : const _GuestRewardView(),
        ),
      ),
    );
  }
}

class _DailyClaimContent extends StatelessWidget {
  const _DailyClaimContent({
    required this.experience,
  });

  final DashboardExperienceProvider experience;

  @override
  Widget build(BuildContext context) {
    final hasClaimedToday = experience.hasClaimedToday;
    final nextDay = experience.nextDailyDay;
    final streak = experience.claimedDaysInCycle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF11998E),
                Color(0xFF38EF7D),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Login harian 7 hari',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hasClaimedToday
                    ? 'Claim hari ini sudah masuk. Besok lanjut ke hari $nextDay.'
                    : 'Masuk setiap hari dan ambil ${DashboardExperienceProvider.dailyClaimCoins} coin selama ${DashboardExperienceProvider.dailyClaimCycleLength} hari.',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _InfoChip(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Streak',
                    value:
                        '$streak/${DashboardExperienceProvider.dailyClaimCycleLength}',
                  ),
                  _InfoChip(
                    icon: Icons.monetization_on_rounded,
                    label: 'Saldo',
                    value: '${experience.coinBalance} coin',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final cardWidth = availableWidth > 360
                ? (availableWidth - 12) / 2
                : availableWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(
                DashboardExperienceProvider.dailyClaimCycleLength,
                (index) {
                  final day = index + 1;
                  final isClaimed = streak >= day;
                  final isToday = !hasClaimedToday && nextDay == day;
                  return SizedBox(
                    width: cardWidth,
                    child: _DayCard(
                      day: day,
                      isClaimed: isClaimed,
                      isToday: isToday,
                    ),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cara kerja reward',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Kamu bisa claim 1 kali per hari. Setelah hari ke-7 selesai, siklus akan kembali ke hari 1 pada claim berikutnya.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4B5563),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: hasClaimedToday
                      ? null
                      : () async {
                          final result = await experience.claimDailyReward();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Hari ${result.day} berhasil diklaim. ${result.coinsEarned} coin sudah masuk.',
                              ),
                            ),
                          );
                        },
                  icon: Icon(
                    hasClaimedToday
                        ? Icons.check_circle_rounded
                        : Icons.redeem_rounded,
                  ),
                  label: Text(
                    hasClaimedToday
                        ? 'Sudah diklaim hari ini'
                        : 'Claim ${DashboardExperienceProvider.dailyClaimCoins} coin',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.isClaimed,
    required this.isToday,
  });

  final int day;
  final bool isClaimed;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.15);
    final backgroundColor = isClaimed
        ? const Color(0xFFD1FAE5)
        : isToday
            ? const Color(0xFFECFDF5)
            : Colors.white;
    final borderColor = isClaimed || isToday
        ? const Color(0xFF10B981)
        : const Color(0xFFE5E7EB);
    final titleColor = isClaimed || isToday
        ? const Color(0xFF047857)
        : const Color(0xFF111827);

    return Container(
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(minHeight: 102),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Hari $day',
            textScaler: textScaler,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '5 coin',
            textScaler: TextScaler.linear(1),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFF059669),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isClaimed
                ? 'Sudah claim'
                : isToday
                    ? 'Claim hari ini'
                    : 'Belum aktif',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textScaler: textScaler,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GuestRewardView extends StatelessWidget {
  const _GuestRewardView();

  @override
  Widget build(BuildContext context) {
    return _StateCard(
      icon: Icons.login_rounded,
      title: 'Masuk untuk claim harian',
      description:
          'Login dulu supaya kamu bisa ambil 5 coin per hari dan melanjutkan siklus reward sampai 7 hari.',
      buttonLabel: 'Masuk',
      onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
    );
  }
}

class _AdminRewardView extends StatelessWidget {
  const _AdminRewardView({
    required this.coinBalance,
  });

  final int coinBalance;

  @override
  Widget build(BuildContext context) {
    return _StateCard(
      icon: Icons.admin_panel_settings_rounded,
      title: 'Reward harian untuk user',
      description:
          'Akun admin tidak mengikuti daily claim. Saldo saat ini tetap bisa dicek dari wallet.',
      buttonLabel: 'Buka Wallet',
      trailingLabel: 'Saldo admin: $coinBalance coin',
      onPressed: () => Navigator.pushNamed(context, AppRoutes.wallet),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
    this.trailingLabel,
  });

  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onPressed;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 42, color: const Color(0xFF10B981)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4B5563),
              height: 1.5,
            ),
          ),
          if (trailingLabel != null) ...[
            const SizedBox(height: 14),
            Text(
              trailingLabel!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF059669),
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onPressed,
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}
