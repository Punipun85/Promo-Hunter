import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/promo_model.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import 'promo_image.dart';

enum PromoCardVariant { list, grid }

class PromoCard extends StatelessWidget {
  const PromoCard({
    super.key,
    required this.promo,
    required this.onTap,
    required this.onFavoriteTap,
    this.isLocked = false,
    this.lockLabel,
    this.variant = PromoCardVariant.list,
  });

  final PromoModel promo;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;
  final bool isLocked;
  final String? lockLabel;
  final PromoCardVariant variant;

  @override
  Widget build(BuildContext context) {
    if (variant == PromoCardVariant.grid) {
      return _buildGridCard(context);
    }
    return _buildListCard(context);
  }

  Widget _buildGridCard(BuildContext context) {
    final muted = promo.isExpired;
    return Opacity(
      opacity: muted ? 0.65 : 1,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  PromoImage(
                    imageUrl: promo.imageUrl,
                    width: 220,
                    height: 140,
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.15),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0A8),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '-' + promo.discountPercent.toStringAsFixed(0) + '%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7C5A00),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: onFavoriteTap,
                        iconSize: 20,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          promo.isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: promo.isFavorite ? Colors.red : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      promo.productName,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@ ' + promo.storeName,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              if (isLocked)
                                _InfoBadge(
                                  label: 'Terkunci',
                                  backgroundColor: const Color(0xFFFEE2E2),
                                  textColor: const Color(0xFF991B1B),
                                ),
                              _InfoBadge(
                                label:
                                    '-' + promo.discountPercent.toStringAsFixed(0) + '%',
                                backgroundColor: const Color(0xFFFFF0A8),
                                textColor: const Color(0xFF7C5A00),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hemat ' + CurrencyFormatter.format(promo.savingsAmount),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: const Color(0xFF10B981),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF4FF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '⏰ ' + DateFormatter.short(promo.endDate),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context) {
    final muted = promo.isExpired;
    return Opacity(
      opacity: muted ? 0.72 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      PromoImage(
                        imageUrl: promo.imageUrl,
                        width: 100,
                        height: 100,
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 24,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.2),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0A8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '-' + promo.discountPercent.toStringAsFixed(0) + '%',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF7C5A00),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              promo.productName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: onFavoriteTap,
                            child: Icon(
                              promo.isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: promo.isFavorite ? Colors.red : const Color(0xFFC7D2E0),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@ ' + promo.storeName,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: const Color(0xFF64748B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          if (isLocked)
                            _InfoBadge(
                              label: 'Terkunci',
                              backgroundColor: const Color(0xFFFEE2E2),
                              textColor: const Color(0xFF991B1B),
                            ),
                          _InfoBadge(
                            label: promo.statusLabel,
                            backgroundColor: _statusBackground(promo),
                            textColor: _statusForeground(promo),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Hemat ' + CurrencyFormatter.format(promo.savingsAmount),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: const Color(0xFF10B981),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF4FF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '⏰ ' + DateFormatter.short(promo.endDate),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontSize: 10),
                            ),
                          ),
                        ],
                      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 9,
            ),
      ),
    );
  }
}
