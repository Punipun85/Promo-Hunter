import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_routes.dart';
import '../../models/promo_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/promo_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/shopping_list_provider.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';

class PromoDetailScreen extends StatelessWidget {
  const PromoDetailScreen({super.key, required this.promo});

  final PromoModel promo;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PromoProvider>();
    final auth = context.watch<AuthProvider>();
    final favoriteProvider = context.watch<FavoriteProvider>();
    final reminderProvider = context.watch<ReminderProvider>();
    final shoppingList = context.read<ShoppingListProvider>();
    final promoIndex = provider.promos.indexWhere((item) => item.id == promo.id);
    final activePromo = promoIndex >= 0 ? provider.promos[promoIndex] : promo;
    final decoratedPromo = activePromo.copyWith(
      isFavorite: favoriteProvider.isFavorite(activePromo.id),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Promo'),
        actions: [
          IconButton(
            onPressed: () {
              if (!auth.isLoggedIn) {
                Navigator.pushNamed(context, AppRoutes.login);
                return;
              }
              favoriteProvider.toggleFavorite(auth.currentUser!.id, activePromo);
            },
            icon: Icon(
              decoratedPromo.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: decoratedPromo.isFavorite ? Colors.red : null,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: CachedNetworkImage(
              imageUrl: decoratedPromo.imageUrl,
              height: 260,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            decoratedPromo.productName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text('${decoratedPromo.brand} - ${decoratedPromo.categoryName}'),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                CurrencyFormatter.format(decoratedPromo.promoPrice),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
          const SizedBox(height: 12),
          Text(
            'Diskon ${decoratedPromo.discountPercent.toStringAsFixed(0)}% - ${CurrencyFormatter.format(decoratedPromo.unitPrice)}/${decoratedPromo.unitType}',
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
            onPressed: () async {
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
            label: const Text('Tambah ke Daftar Belanja'),
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
            onPressed: () async {
              final uri = Uri.parse(
                'https://maps.google.com/?q=${Uri.encodeComponent(decoratedPromo.storeAddress)}',
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
}
