import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_routes.dart';
import '../../models/promo_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_experience_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/promo_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/shopping_list_provider.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/promo_image.dart';

class PromoDetailScreen extends StatefulWidget {
  const PromoDetailScreen({super.key, required this.promo});

  final PromoModel promo;

  @override
  State<PromoDetailScreen> createState() => _PromoDetailScreenState();
}

class _PromoDetailScreenState extends State<PromoDetailScreen> {
  bool _hasMarkedAsViewed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasMarkedAsViewed) return;
    context.read<PromoProvider>().markAsViewed(widget.promo);
    _hasMarkedAsViewed = true;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PromoProvider>();
    final auth = context.watch<AuthProvider>();
    final experience = context.watch<DashboardExperienceProvider>();
    final favoriteProvider = context.watch<FavoriteProvider>();
    final reminderProvider = context.watch<ReminderProvider>();
    final shoppingList = context.read<ShoppingListProvider>();
    final promoIndex =
        provider.promos.indexWhere((item) => item.id == widget.promo.id);
    final activePromo = promoIndex >= 0 ? provider.promos[promoIndex] : widget.promo;
    final decoratedPromo = activePromo.copyWith(
      isFavorite: favoriteProvider.isFavorite(activePromo.id),
    );
    final isLocked = experience.isPromoLocked(decoratedPromo.id);
    final isMemberOnly = experience.isMemberOnlyPromo(decoratedPromo.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Promo'),
        actions: [
          IconButton(
            onPressed: () => Share.share(_buildShareText(decoratedPromo)),
            icon: const Icon(Icons.share_outlined),
          ),
          IconButton(
            onPressed: () {
              if (!auth.isLoggedIn) {
                Navigator.pushNamed(context, AppRoutes.login);
                return;
              }
              favoriteProvider.toggleFavorite(auth.currentUser!.id, activePromo);
            },
            icon: Icon(
              decoratedPromo.isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: decoratedPromo.isFavorite ? Colors.red : null,
            ),
          ),
        ],
      ),
      body: isLocked
          ? _LockedPromoDetail(
              promo: decoratedPromo,
              waitLabel: experience.promoLockLabel(decoratedPromo.id),
              isMemberOnly: isMemberOnly,
              coinBalance: experience.coinBalance,
              canUnlockWithCoins:
                  experience.canUnlockPromoWithCoins(decoratedPromo.id),
              onUnlockWithCoins: () async {
                final ok =
                    await experience.unlockPromoWithCoins(decoratedPromo.id);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? 'Promo berhasil dibuka memakai coin.'
                          : 'Coin belum cukup untuk membuka promo ini.',
                    ),
                  ),
                );
              },
              onSubscribe: () async {
                Navigator.pushNamed(context, AppRoutes.wallet);
              },
            )
          : ListView(
        padding: const EdgeInsets.all(20),
        children: [
          PromoImage(
            imageUrl: decoratedPromo.imageUrl,
            width: double.infinity,
            height: 260,
            borderRadius: 28,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusBadge(
                label: decoratedPromo.statusLabel,
                backgroundColor: _statusBackground(decoratedPromo),
                textColor: _statusForeground(decoratedPromo),
              ),
              _StatusBadge(
                label: 'Diskon ${decoratedPromo.discountPercent.toStringAsFixed(0)}%',
                backgroundColor: const Color(0xFFFFF0A8),
                textColor: const Color(0xFF7C5A00),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            decoratedPromo.productName,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${decoratedPromo.brand} - ${decoratedPromo.categoryName}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF64748B),
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                CurrencyFormatter.format(decoratedPromo.promoPrice),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(width: 12),
              Text(
                CurrencyFormatter.format(decoratedPromo.normalPrice),
                style: const TextStyle(
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Kamu hemat ${CurrencyFormatter.format(decoratedPromo.savingsAmount)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${CurrencyFormatter.format(decoratedPromo.unitPrice)} / ${decoratedPromo.unitType}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Toko', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(decoratedPromo.storeName),
                  Text(decoratedPromo.storeAddress),
                  const SizedBox(height: 12),
                  Text(
                    'Masa berlaku',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${DateFormatter.short(decoratedPromo.startDate)} - ${DateFormatter.short(decoratedPromo.endDate)}',
                  ),
                  const SizedBox(height: 6),
                  Text(
                    decoratedPromo.isExpired
                        ? 'Promo ini sudah berakhir.'
                        : decoratedPromo.isEndingToday
                            ? 'Promo berakhir hari ini.'
                            : decoratedPromo.isEndingTomorrow
                                ? 'Promo berakhir besok.'
                                : 'Promo masih aktif.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Syarat & ketentuan',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(decoratedPromo.terms),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: decoratedPromo.isExpired
                ? null
                : () async {
                    if (!auth.isLoggedIn) {
                      Navigator.pushNamed(context, AppRoutes.login);
                      return;
                    }
                    await shoppingList.bootstrap(auth.currentUser!.id);
                    await shoppingList.addPromo(decoratedPromo);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Promo ditambahkan ke daftar belanja.'),
                      ),
                    );
                  },
            icon: const Icon(Icons.shopping_cart_outlined),
            label: Text(
              decoratedPromo.isExpired
                  ? 'Promo Sudah Expired'
                  : 'Tambah ke Daftar Belanja',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: decoratedPromo.isExpired
                ? null
                : () async {
                    if (!auth.isLoggedIn) {
                      Navigator.pushNamed(context, AppRoutes.login);
                      return;
                    }
                    await reminderProvider.bootstrapForUser(auth.currentUser!.id);
                    final message = await reminderProvider.addReminder(
                      auth.currentUser!.id,
                      decoratedPromo,
                      const Duration(hours: 3),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          message ??
                              'Reminder 3 jam sebelum promo berakhir berhasil dibuat.',
                        ),
                      ),
                    );
                  },
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Ingatkan Saya'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Share.share(_buildShareText(decoratedPromo)),
            icon: const Icon(Icons.share_outlined),
            label: const Text('Bagikan Promo'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final uri = Uri.parse(
                'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('${decoratedPromo.storeName} ${decoratedPromo.storeAddress}')}',
              );
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.map_outlined),
            label: const Text('Buka Lokasi Toko'),
          ),
        ],
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

  String _buildShareText(PromoModel promo) {
    final expiryLabel = promo.isExpired
        ? 'Promo ini sudah berakhir.'
        : 'Berlaku sampai ${DateFormatter.short(promo.endDate)}.';
    return '${promo.productName} sedang promo di ${promo.storeName}.\n'
        'Harga promo: ${CurrencyFormatter.format(promo.promoPrice)}\n'
        'Harga normal: ${CurrencyFormatter.format(promo.normalPrice)}\n'
        'Hemat: ${CurrencyFormatter.format(promo.savingsAmount)}\n'
        '$expiryLabel\n'
        'Lokasi toko: ${promo.storeAddress}\n'
        'Dibagikan dari PromoHunter.';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

class _LockedPromoDetail extends StatelessWidget {
  const _LockedPromoDetail({
    required this.promo,
    required this.waitLabel,
    required this.isMemberOnly,
    required this.coinBalance,
    required this.canUnlockWithCoins,
    required this.onUnlockWithCoins,
    required this.onSubscribe,
  });

  final PromoModel promo;
  final String waitLabel;
  final bool isMemberOnly;
  final int coinBalance;
  final bool canUnlockWithCoins;
  final Future<void> Function() onUnlockWithCoins;
  final Future<void> Function() onSubscribe;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.lock_clock_outlined),
              ),
              const SizedBox(height: 16),
              Text(
                isMemberOnly ? 'Promo Khusus Member' : 'Promo Early Access',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                promo.productName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                isMemberOnly
                    ? 'Promo ini hanya bisa dibuka oleh member premium. Upgrade akun untuk melihat harga, detail, dan link klaim.'
                    : 'User gratis perlu $waitLabel untuk melihat harga dan detail promo ini.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              _LockedInfoRow(
                icon: Icons.monetization_on_outlined,
                label: isMemberOnly ? 'Akses' : 'Saldo coin',
                value: isMemberOnly ? 'Premium' : '$coinBalance coin',
              ),
              const SizedBox(height: 10),
              _LockedInfoRow(
                icon: Icons.storefront_outlined,
                label: 'Toko',
                value: promo.storeName,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: canUnlockWithCoins ? onUnlockWithCoins : null,
                icon: const Icon(Icons.lock_open_outlined),
                label: Text(
                  isMemberOnly ? 'Tidak tersedia untuk coin' : 'Buka dengan 30 Coin',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: onSubscribe,
                icon: const Icon(Icons.workspace_premium_outlined),
                label: const Text('Langganan Premium'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LockedInfoRow extends StatelessWidget {
  const _LockedInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      ],
    );
  }
}
