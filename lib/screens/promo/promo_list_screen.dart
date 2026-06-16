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
    'Terdekat',
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
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final storeDropdown = _FilterDropdown(
                          label: 'Toko',
                          value: provider.selectedStore,
                          options: provider.stores.map((item) => item.name),
                          onChanged: (value) =>
                              provider.updateSelectedStore(value ?? 'Semua'),
                        );
                        final categoryDropdown = _FilterDropdown(
                          label: 'Kategori',
                          value: provider.selectedCategory,
                          options:
                              provider.categories.map((item) => item.name),
                          onChanged: (value) => provider
                              .updateSelectedCategory(value ?? 'Semua'),
                        );

                        if (constraints.maxWidth < 430) {
                          return Column(
                            children: [
                              storeDropdown,
                              const SizedBox(height: 12),
                              categoryDropdown,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: storeDropdown),
                            const SizedBox(width: 12),
                            Expanded(child: categoryDropdown),
                          ],
                        );
                      },
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
                    OutlinedButton.icon(
                      onPressed: provider.isLoadingLocation
                          ? null
                          : () async {
                              await provider.refreshUserLocation(
                                makeNearestDefault: true,
                              );
                              if (!context.mounted ||
                                  provider.locationMessage == null) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(provider.locationMessage!),
                                ),
                              );
                            },
                      icon: provider.isLoadingLocation
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location_rounded),
                      label: Text(
                        provider.hasUserLocation
                            ? 'Lokasi aktif, prioritaskan terdekat'
                            : 'Gunakan lokasi saya',
                      ),
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

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final Iterable<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final uniqueOptions = options.toSet().toList();
    final safeValue = uniqueOptions.contains(value) ? value : null;

    return DropdownButtonFormField<String>(
      initialValue: safeValue,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      selectedItemBuilder: (context) => uniqueOptions
          .map(
            (item) => Text(
              item,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          )
          .toList(),
      items: uniqueOptions
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
