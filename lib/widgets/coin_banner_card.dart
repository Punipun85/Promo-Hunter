import 'package:flutter/material.dart';

import '../config/app_routes.dart';
import '../utils/currency_formatter.dart';

class CoinBannerCard extends StatelessWidget {
  final int coinBalance;
  final VoidCallback? onPlayGamesPressed;
  final VoidCallback? onViewRewardsPressed;

  const CoinBannerCard({
    super.key,
    required this.coinBalance,
    this.onPlayGamesPressed,
    this.onViewRewardsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF064E3B), Color(0xFF065F46), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF065F46).withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with icon
          Row(
            children: [
              const Icon(
                Icons.monetization_on_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                'Your Coins',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Coin balance - main display
          Text(
            'Rp ${CurrencyFormatter.formatSimple(coinBalance)}',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 8),
          
          // Subtitle
          Text(
            'Unlock exclusive promos',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.85),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onPlayGamesPressed,
                  icon: const Icon(Icons.sports_esports_rounded, size: 18),
                  label: const Text('Play Games'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF059669),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onViewRewardsPressed,
                  icon: const Icon(Icons.card_giftcard_rounded, size: 18),
                  label: const Text('Rewards'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

