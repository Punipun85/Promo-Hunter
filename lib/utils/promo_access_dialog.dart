import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_routes.dart';
import '../models/promo_model.dart';
import '../providers/dashboard_experience_provider.dart';

Future<void> openPromoWithAccessGuard(
  BuildContext context,
  PromoModel promo,
) async {
  final experience = context.read<DashboardExperienceProvider>();
  await experience.registerPromos([promo.id]);
  if (!context.mounted) return;

  if (experience.isPromoLocked(promo.id)) {
    final unlocked = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: const Text('Promo Early Access'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                promo.productName,
                style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'User gratis perlu ${experience.promoLockLabel(promo.id).toLowerCase()} untuk membuka info promo ini.',
              ),
              const SizedBox(height: 14),
              _AccessLine(
                icon: Icons.monetization_on_outlined,
                text:
                    'Saldo coin: ${experience.coinBalance}. Unlock butuh ${DashboardExperienceProvider.unlockCost} coin.',
              ),
              const SizedBox(height: 8),
              const _AccessLine(
                icon: Icons.workspace_premium_outlined,
                text: 'Langganan membuka semua promo tanpa menunggu.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Nanti'),
            ),
            TextButton(
              onPressed: experience.canUnlockWithCoins
                  ? () async {
                      final ok = await experience.unlockPromoWithCoins(promo.id);
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext, ok);
                    }
                  : null,
              child: const Text('Pakai Coin'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
                if (!context.mounted) return;
                Navigator.pushNamed(context, AppRoutes.wallet);
              },
              child: const Text('Langganan'),
            ),
          ],
        );
      },
    );
    if (unlocked != true || !context.mounted) return;
  }

  if (!context.mounted) return;
  Navigator.pushNamed(
    context,
    AppRoutes.promoDetail,
    arguments: promo,
  );
}

class _AccessLine extends StatelessWidget {
  const _AccessLine({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}
