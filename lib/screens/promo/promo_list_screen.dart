import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_experience_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/promo_provider.dart';
import '../../utils/promo_access_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/promo_card.dart';

class PromoListScreen extends StatelessWidget {
  const PromoListScreen({super.key});

  static const List<String> _sortOptions = [
    'Terbaru',
    'Diskon terbesar',
    'Harga termurah',
    'Hampir berakhir',
    'Toko A-Z',
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final favoriteProvider = context.watch<FavoriteProvider>();
    final provider = context.watch<PromoProvider>();
    final experience = context.watch<DashboardExperienceProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Promo')),
      body: provider.isLoading
          ? const LoadingWidget(message: 'Sedang memuat katalog promo...')
          : provider.errorMessage != null
              ? ErrorState(
                  title: 'Gagal memuat promo',
                  message: provider.errorMessage!,
                  onRetry: () => context.read<PromoProvider>().bootstrap(),
                )
              : ListView(
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
                            initialValue: provider.selectedCategory,
                            decoration:
                                const InputDecoration(labelText: 'Kategori'),
                            items: provider.categories
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item.name,
                                    child: Text(item.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) => provider
                                .updateSelectedCategory(value ?? 'Semua'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${provider.filteredPromos.length} promo ditemukan',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: provider.resetFilters,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Reset'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Urutkan promo',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _sortOptions.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final option = _sortOptions[index];
                          final selected = provider.selectedSort == option;
                          return ChoiceChip(
                            label: Text(option),
                            selected: selected,
                            onSelected: (_) => provider.updateSort(option),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.tune_rounded, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Menampilkan promo dengan urutan ${provider.selectedSort.toLowerCase()}.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (provider.filteredPromos.isEmpty)
                      const EmptyState(
                        title: 'Promo tidak ditemukan',
                        subtitle: 'Coba kata kunci, toko, kategori, atau urutan lain.',
                      )
                    else
                      ...provider.filteredPromos.map(
                        (promo) => PromoCard(
                          promo: promo.copyWith(
                            isFavorite: favoriteProvider.isFavorite(promo.id),
                          ),
                          isLocked: experience.isPromoLocked(promo.id),
                          lockLabel: experience.promoLockLabel(promo.id),
                          onTap: () => openPromoWithAccessGuard(context, promo),
                          onFavoriteTap: () {
                            if (!auth.isLoggedIn) {
                              Navigator.pushNamed(context, AppRoutes.login);
                              return;
                            }
                            favoriteProvider.toggleFavorite(
                              auth.currentUser!.id,
                              promo,
                            );
                          },
                        ),
                      ),
                  ],
                ),
    );
  }
}
