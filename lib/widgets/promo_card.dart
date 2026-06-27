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

  bool get _isMemberOnlyLock =>
      isLocked && (lockLabel?.toLowerCase().contains('member') ?? false);

  bool get _isTimedLock =>
      isLocked && (lockLabel?.toLowerCase().contains('tunggu') ?? false);

  Duration? get _timedLockRemaining {
    if (!_isTimedLock || lockLabel == null) return null;
    final text = lockLabel!.toLowerCase();
    final hoursMatch = RegExp(r'(\d+)j').firstMatch(text);
    final minutesMatch = RegExp(r'(\d+)m').firstMatch(text);
    final hours = hoursMatch != null ? int.tryParse(hoursMatch.group(1)!) : 0;
    final minutes =
        minutesMatch != null ? int.tryParse(minutesMatch.group(1)!) : 0;
    return Duration(hours: hours ?? 0, minutes: minutes ?? 0);
  }

  Color get _lockBackgroundColor {
    if (_isMemberOnlyLock) return const Color(0xFFEDE9FE);
    final remaining = _timedLockRemaining;
    if (remaining != null) {
      if (remaining.inMinutes <= 30) return const Color(0xFFFEE2E2);
      if (remaining.inHours <= 1) return const Color(0xFFFFEDD5);
      return const Color(0xFFFEF3C7);
    }
    return const Color(0xFFFEE2E2);
  }

  Color get _lockTextColor {
    if (_isMemberOnlyLock) return const Color(0xFF5B21B6);
    final remaining = _timedLockRemaining;
    if (remaining != null) {
      if (remaining.inMinutes <= 30) return const Color(0xFF991B1B);
      if (remaining.inHours <= 1) return const Color(0xFF9A3412);
      return const Color(0xFF854D0E);
    }
    return const Color(0xFF991B1B);
  }

  String get _lockBadgeLabel {
    if (_isMemberOnlyLock) return 'Premium only';
    if (_isTimedLock && lockLabel != null) {
      final badgeLabel = lockLabel!.replaceFirst('Tunggu', 'Gratis dalam');
      return badgeLabel;
    }
    return 'Terkunci';
  }

  String get _lockDescription {
    if (_isMemberOnlyLock) return 'Premium: akses instan';
    if (_isTimedLock && lockLabel != null) {
      return '${lockLabel!.replaceFirst('Tunggu', 'Gratis dalam')} | Premium instan';
    }
    return lockLabel ?? 'Buka dengan coin atau premium';
  }

  String get _gridLockBadgeLabel {
    if (_isMemberOnlyLock) return 'Premium';
    final remaining = _timedLockRemaining;
    if (remaining != null) {
      final hours = remaining.inHours;
      final minutes = remaining.inMinutes.remainder(60);
      if (hours > 0) return '${hours}j ${minutes}m lagi';
      return '${minutes}m lagi';
    }
    return 'Terkunci';
  }

  String get _gridLockDescription {
    if (_isMemberOnlyLock) return 'Premium instan';
    if (_isTimedLock) return 'Gratis nanti, premium instan';
    return 'Buka dengan coin';
  }

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
                        '-${promo.discountPercent.toStringAsFixed(0)}%',
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
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        icon: Icon(
                          promo.isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: promo.isFavorite ? Colors.red : null,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  if (isLocked)
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _lockBackgroundColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _gridLockBadgeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: _lockTextColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      promo.productName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0B1C30),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${promo.brand} - ${promo.storeName}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isLocked
                          ? 'Harga terkunci'
                          : CurrencyFormatter.format(promo.promoPrice),
                      style: const TextStyle(
                        fontSize: 17,
                        color: Color(0xFF059669),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (!isLocked) ...[
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(promo.normalPrice),
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      isLocked
                          ? _gridLockDescription
                          : 'Hemat ${CurrencyFormatter.format(promo.savingsAmount)}',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isLocked ? _lockTextColor : const Color(0xFF059669),
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: PromoImage(
                    imageUrl: promo.imageUrl,
                    width: 88,
                    height: 88,
                  ),
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
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            onPressed: onFavoriteTap,
                            iconSize: 22,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            icon: Icon(
                              promo.isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: promo.isFavorite ? Colors.red : null,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${promo.brand} - ${promo.storeName}',
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (isLocked)
                            _InfoBadge(
                              label: _lockBadgeLabel,
                              backgroundColor: _lockBackgroundColor,
                              textColor: _lockTextColor,
                            ),
                          if (isLocked && !_isMemberOnlyLock)
                            const _InfoBadge(
                              label: 'Premium instan',
                              backgroundColor: Color(0xFFE8F7EE),
                              textColor: Color(0xFF166534),
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
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            isLocked
                                ? 'Harga terkunci'
                                : CurrencyFormatter.format(promo.promoPrice),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          if (!isLocked)
                            Text(
                              CurrencyFormatter.format(promo.normalPrice),
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                fontSize: 12,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isLocked
                                  ? _lockDescription
                                  : 'Hemat ${CurrencyFormatter.format(promo.savingsAmount)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: isLocked
                                        ? _lockTextColor
                                        : Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
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
                              'Ends ${DateFormatter.short(promo.endDate)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      if (promo.sourceUrl.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: isLocked
                                ? null
                                : () => _openClaimUrl(promo.sourceUrl),
                            icon: const Icon(
                              Icons.open_in_new_rounded,
                              size: 16,
                            ),
                            label: const Text('Claim Promo'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
      ),
    );
  }
}
