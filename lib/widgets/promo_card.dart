import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/promo_model.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import 'promo_image.dart';

class PromoCard extends StatelessWidget {
  const PromoCard({
    super.key,
    required this.promo,
    required this.onTap,
    required this.onFavoriteTap,
    this.isLocked = false,
    this.lockLabel,
  });

  final PromoModel promo;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;
  final bool isLocked;
  final String? lockLabel;

  @override
  Widget build(BuildContext context) {
    final muted = promo.isExpired;
    return Opacity(
      opacity: muted ? 0.72 : 1,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PromoImage(
                  imageUrl: promo.imageUrl,
                  width: 96,
                  height: 96,
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
                              promo.productName,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            onPressed: onFavoriteTap,
                            icon: Icon(
                              promo.isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: promo.isFavorite ? Colors.red : null,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${promo.brand} - ${promo.storeName}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (isLocked)
                            const _InfoBadge(
                              label: 'Terkunci',
                              backgroundColor: Color(0xFFFEE2E2),
                              textColor: Color(0xFF991B1B),
                            ),
                          _InfoBadge(
                            label:
                                '-${promo.discountPercent.toStringAsFixed(0)}%',
                            backgroundColor: const Color(0xFFFFF0A8),
                            textColor: const Color(0xFF7C5A00),
                          ),
                          _InfoBadge(
                            label: promo.statusLabel,
                            backgroundColor: _statusBackground(promo),
                            textColor: _statusForeground(promo),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            isLocked
                                ? 'Harga terkunci'
                                : CurrencyFormatter.format(promo.promoPrice),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          if (!isLocked)
                            Text(
                              CurrencyFormatter.format(promo.normalPrice),
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isLocked
                            ? lockLabel ?? 'Buka dengan coin atau premium'
                            : 'Hemat ${CurrencyFormatter.format(promo.savingsAmount)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF4FF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Berlaku sampai ${DateFormatter.short(promo.endDate)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      if (promo.sourceUrl.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: isLocked
                                ? null
                                : () => _openClaimUrl(promo.sourceUrl),
                            icon: const Icon(Icons.open_in_new_rounded),
                            label: const Text('Claim Promo'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statusBackground(PromoModel promo) {
    if (promo.isExpired) return const Color(0xFFFEE2E2);
    if (promo.isEndingToday || promo.isEndingTomorrow) {
      return const Color(0xFFFFEDD5);
    }
    if (promo.isEndingSoon) return const Color(0xFFFEF3C7);
    return const Color(0xFFE8F7EE);
  }

  Color _statusForeground(PromoModel promo) {
    if (promo.isExpired) return const Color(0xFF991B1B);
    if (promo.isEndingToday || promo.isEndingTomorrow) {
      return const Color(0xFF9A3412);
    }
    if (promo.isEndingSoon) return const Color(0xFF854D0E);
    return const Color(0xFF166534);
  }

  Future<void> _openClaimUrl(String sourceUrl) async {
    final uri = Uri.tryParse(sourceUrl);
    if (uri == null || !uri.hasScheme) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: textColor,
            ),
      ),
    );
  }
}
