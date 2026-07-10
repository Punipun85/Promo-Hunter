import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/dashboard_experience_provider.dart';

class DailyClaimScreen extends StatelessWidget {
  const DailyClaimScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final experience = context.watch<DashboardExperienceProvider>();
    final currentDay = experience.hasClaimedToday
        ? experience.claimedDaysInCycle.clamp(1, 7)
        : experience.nextDailyDay;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: const Text('Daily Claim'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 24,
                    offset: Offset(0, 12),
                  ),
                ],
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
                          color: const Color(0xFFE8F7EE),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.card_giftcard_rounded,
                          color: Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Login harian',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${experience.coinBalance} coin tersedia',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    experience.hasClaimedToday
                        ? 'Reward hari ini sudah diambil. Besok lanjut lagi ke hari ${experience.nextDailyDay}/7.'
                        : 'Hari $currentDay/7 siap diambil. Kamu mendapat 5 coin setiap hari.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF334155),
                          height: 1.45,
                        ),
                  ),
                  const SizedBox(height: 18),
                  _ClaimProgress(
                    claimedDays: experience.claimedDaysInCycle,
                    currentDay: currentDay,
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: experience.hasClaimedToday
                          ? null
                          : () => _claim(context, experience),
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: Text(
                        experience.hasClaimedToday
                            ? 'Sudah claim hari ini'
                            : 'Claim 5 coin',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Text(
                'Siklus akan kembali ke hari 1 setelah hari ke-7. Claim hanya bisa dilakukan satu kali per hari.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF1E3A8A),
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _claim(
    BuildContext context,
    DashboardExperienceProvider experience,
  ) async {
    final result = await experience.claimDailyReward();
    if (!context.mounted) return;
    final message = result.coinsEarned == 0
        ? 'Reward hari ini sudah diambil.'
        : 'Hari ${result.day}/7 berhasil claim ${result.coinsEarned} coin.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _ClaimProgress extends StatelessWidget {
  const _ClaimProgress({
    required this.claimedDays,
    required this.currentDay,
  });

  final int claimedDays;
  final int currentDay;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(7, (index) {
        final day = index + 1;
        final claimed = day <= claimedDays;
        final active = day == currentDay;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == 6 ? 0 : 6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 42,
              decoration: BoxDecoration(
                color: claimed
                    ? const Color(0xFF10B981)
                    : active
                        ? const Color(0xFFD1FAE5)
                        : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: active
                      ? const Color(0xFF10B981)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: claimed ? Colors.white : const Color(0xFF0F172A),
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
