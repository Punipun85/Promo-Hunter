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
    final isMemberOnly = experience.isMemberOnlyPromo(promo.id);
    final unlocked = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          titlePadding: const EdgeInsets.fromLTRB(24, 18, 14, 0),
          title: Row(
            children: [
              const Expanded(child: Text('Promo Early Access')),
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
              Text(
                promo.productName,
                style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                isMemberOnly
                    ? 'Promo ini khusus member premium. Upgrade akun untuk membuka harga, detail, dan link klaim.'
                    : 'User gratis menunggu maksimal 3 jam setelah promo rilis. Saat ini kamu masih perlu ${experience.promoLockLabel(promo.id).toLowerCase()} untuk membuka info promo ini.',
              ),
              const SizedBox(height: 14),
              _AccessLine(
                icon: Icons.monetization_on_outlined,
                text: isMemberOnly
                    ? 'Promo member tidak bisa dibuka dengan coin.'
                    : 'Saldo coin: ${experience.coinBalance}. Unlock butuh ${DashboardExperienceProvider.unlockCost} coin.',
              ),
              const SizedBox(height: 8),
              const _AccessLine(
                icon: Icons.workspace_premium_outlined,
                text: 'Langganan membuka semua promo secara instan saat promo rilis.',
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
          actions: [
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: experience.canUnlockPromoWithCoins(promo.id)
                        ? () async {
                            final ok =
                                await experience.unlockPromoWithCoins(promo.id);
                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext, ok);
                          }
                        : null,
                    child: Text(isMemberOnly ? 'Khusus Member' : 'Pakai Coin'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(dialogContext, false);
                      if (!context.mounted) return;
                      Navigator.pushNamed(context, AppRoutes.wallet);
                    },
                    child: const Text('Langganan'),
                  ),
                ),
              ],
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
