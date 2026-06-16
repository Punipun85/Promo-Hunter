import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../providers/dashboard_experience_provider.dart';
import '../../utils/date_formatter.dart';

class CoinRushScreen extends StatefulWidget {
  const CoinRushScreen({super.key});

  @override
  State<CoinRushScreen> createState() => _CoinRushScreenState();
}

class _CoinRushScreenState extends State<CoinRushScreen> {
  final Random _random = Random();

  bool _isPlaying = false;
  bool _isRevealing = false;
  int _roundIndex = 0;
  int _score = 0;
  int _luckyCard = 0;
  int? _selectedCard;
  bool? _wasCorrect;
  MiniGameResult? _lastResult;

  void _startGame() {
    final experience = context.read<DashboardExperienceProvider>();
    if (!experience.canPlayMiniGame) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kuota Coin Rush hari ini sudah habis.')),
      );
      return;
    }

    setState(() {
      _isPlaying = true;
      _isRevealing = false;
      _roundIndex = 0;
      _score = 0;
      _selectedCard = null;
      _wasCorrect = null;
      _lastResult = null;
      _luckyCard = _random.nextInt(4);
    });
  }

  void _prepareNextRound() {
    setState(() {
      _selectedCard = null;
      _wasCorrect = null;
      _isRevealing = false;
      _luckyCard = _random.nextInt(4);
    });
  }

  Future<void> _chooseCard(int index) async {
    if (!_isPlaying || _isRevealing) return;

    final correct = index == _luckyCard;
    setState(() {
      _selectedCard = index;
      _wasCorrect = correct;
      _isRevealing = true;
      if (correct) _score += 1;
    });

    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    if (_roundIndex >= DashboardExperienceProvider.miniGameRounds - 1) {
      await _finishGame();
    } else {
      setState(() {
        _roundIndex += 1;
      });
      _prepareNextRound();
    }
  }

  Future<void> _finishGame() async {
    final experience = context.read<DashboardExperienceProvider>();
    final result = await experience.playMiniGame(score: _score);
    if (!mounted) return;

    setState(() {
      _isPlaying = false;
      _isRevealing = false;
      _lastResult = result;
    });

    final message = result.isLimitReached
        ? 'Kuota harian sudah habis.'
        : result.coinsEarned > 0
            ? 'Kamu mendapatkan ${result.coinsEarned} coin.'
            : 'Belum dapat coin, coba lagi besok.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final experience = context.watch<DashboardExperienceProvider>();
    final now = DateTime.now();
    final tomorrowReset = DateTime(now.year, now.month, now.day + 1);
    final attemptsLeft = experience.miniGameRemainingAttempts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coin Rush'),
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
                  'Cari kartu coin di 5 ronde cepat.',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Setiap hari kamu punya 3 kesempatan. Kuota akan kembali lagi besok.',
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
                      label: 'Tersisa $attemptsLeft/3',
                      icon: Icons.timelapse_outlined,
                    ),
                    _StatusChip(
                      label: '${experience.coinBalance} coin',
                      icon: Icons.monetization_on_outlined,
                    ),
                    const _StatusChip(
                      label:
                          '${DashboardExperienceProvider.miniGameRounds} ronde',
                      icon: Icons.sports_esports_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (!_isPlaying) ...[
            _SummaryCard(
              title: _lastResult == null
                  ? 'Siap main?'
                  : 'Hasil permainan terakhir',
              subtitle: _lastResult == null
                  ? 'Tekan mulai untuk membuka putaran baru dan kumpulkan coin.'
                  : _lastResult!.isLimitReached
                      ? 'Kuota hari ini sudah penuh. Coba lagi setelah reset besok.'
                      : 'Skor kamu ${_lastResult!.score}/${DashboardExperienceProvider.miniGameRounds}.',
              trailing: _lastResult == null
                  ? null
                  : Text(
                      '+${_lastResult!.coinsEarned} coin',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: attemptsLeft > 0 ? _startGame : null,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(attemptsLeft > 0 ? 'Mulai Main' : 'Kuota Habis'),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.wallet),
              icon: const Icon(Icons.storefront_outlined),
              label: const Text('Tukar coin jadi voucher'),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reset harian',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kuota Coin Rush kembali pada ${DateFormatter.short(tomorrowReset)}.',
                  ),
                ],
              ),
            ),
          ] else ...[
            _SummaryCard(
              title:
                  'Ronde ${_roundIndex + 1} dari ${DashboardExperienceProvider.miniGameRounds}',
              subtitle: 'Pilih kartu yang menyembunyikan coin di bawahnya.',
              trailing: Text(
                'Skor $_score',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: List.generate(4, (index) {
                final isCorrect = _selectedCard == index && _wasCorrect == true;
                final isWrong = _selectedCard == index && _wasCorrect == false;
                final reveal = _isRevealing;
                return InkWell(
                  onTap: () => _chooseCard(index),
                  borderRadius: BorderRadius.circular(24),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? const Color(0xFFE8F7EE)
                          : isWrong
                              ? const Color(0xFFFFEBEE)
                              : const Color(0xFFEFF4FF),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isCorrect
                            ? const Color(0xFF0F9D58)
                            : isWrong
                                ? const Color(0xFFE53935)
                                : const Color(0xFFD7E3FF),
                        width: 1.3,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          reveal && index == _luckyCard
                              ? Icons.monetization_on
                              : Icons.question_mark_rounded,
                          size: 40,
                          color: isCorrect
                              ? const Color(0xFF0F9D58)
                              : isWrong
                                  ? const Color(0xFFE53935)
                                  : Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          reveal && index == _luckyCard
                              ? 'Coin'
                              : 'Kartu ${index + 1}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          reveal
                              ? index == _luckyCard
                                  ? 'Benar'
                                  : index == _selectedCard
                                      ? 'Salah'
                                      : 'Tutup'
                              : 'Tap untuk buka',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.wallet),
              icon: const Icon(Icons.wallet_outlined),
              label: const Text('Cek voucher di wallet'),
            ),
          ],
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(subtitle),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}
