import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_routes.dart';
import '../../models/store_model.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/promo_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/promo_card.dart';

class StoreDetailScreen extends StatelessWidget {
  const StoreDetailScreen({super.key, required this.store});

  final StoreModel store;

  @override
  Widget build(BuildContext context) {
    final promoProvider = context.watch<PromoProvider>();
    final auth = context.watch<AuthProvider>();
    final favoriteProvider = context.watch<FavoriteProvider>();
    final promos = promoProvider.promosByStore(store.name);

    return Scaffold(
      appBar: AppBar(title: Text(store.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(store.name, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(store.address),
                  Text('${store.city} - ${store.openingHours}'),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await launchUrl(
                        Uri.parse(store.googleMapsUrl),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Buka Rute'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Promo Aktif', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (promos.isEmpty)
            const EmptyState(
              title: 'Belum ada promo aktif',
              subtitle: 'Promo toko ini akan tampil di sini.',
              icon: Icons.local_offer_outlined,
            )
          else
            ...promos.map(
              (promo) => PromoCard(
                promo: promo.copyWith(
                  isFavorite: favoriteProvider.isFavorite(promo.id),
                ),
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.promoDetail,
                  arguments: promo,
                ),
                onFavoriteTap: () {
                  if (!auth.isLoggedIn) {
                    Navigator.pushNamed(context, AppRoutes.login);
                    return;
                  }
                  favoriteProvider.toggleFavorite(auth.currentUser!.id, promo);
                },
              ),
            ),
        ],
      ),
    );
  }
}

