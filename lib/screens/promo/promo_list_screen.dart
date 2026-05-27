import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/promo_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/promo_card.dart';

class PromoListScreen extends StatelessWidget {
  const PromoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final favoriteProvider = context.watch<FavoriteProvider>();
    final provider = context.watch<PromoProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Promo')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            onChanged: provider.updateSearch,
            decoration: const InputDecoration(
              hintText: 'Cari produk, brand, atau toko...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: provider.selectedStore,
                  decoration: const InputDecoration(labelText: 'Toko'),
                  items: provider.stores
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.name,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      provider.updateSelectedStore(value ?? 'Semua'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: provider.selectedSort,
                  decoration: const InputDecoration(labelText: 'Urutkan'),
                  items: const [
                    'Terbaru',
                    'Diskon terbesar',
                    'Harga termurah',
                    'Hampir berakhir',
                  ]
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => provider.updateSort(value ?? 'Terbaru'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: provider.resetFilters,
              child: const Text('Reset Filter'),
            ),
          ),
          if (provider.filteredPromos.isEmpty)
            const EmptyState(
              title: 'Promo tidak ditemukan',
              subtitle: 'Coba kata kunci atau filter lain.',
            )
          else
            ...provider.filteredPromos.map(
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
