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

class PromoListScreen extends StatefulWidget {
  const PromoListScreen({super.key});

  @override
  State<PromoListScreen> createState() => _PromoListScreenState();
}

class _PromoListScreenState extends State<PromoListScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  static const List<String> _sortOptions = [
    'Terbaru',
    'Diskon terbesar',
    'Harga termurah',
    'Hampir berakhir',
    'Terdekat',
    'Toko A-Z',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final favoriteProvider = context.watch<FavoriteProvider>();
    final provider = context.watch<PromoProvider>();
    final experience = context.watch<DashboardExperienceProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      context
          .read<DashboardExperienceProvider>()
          .registerPromos(provider.promos.map((promo) => promo.id));
    });
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Daftar Promo'),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: provider.isLoading
          ? const LoadingWidget(message: 'Sedang memuat katalog promo...')
          : provider.errorMessage != null
              ? ErrorState(
                  title: 'Gagal memuat promo',
                  message: provider.errorMessage!,
                  onRetry: () => context.read<PromoProvider>().bootstrap(),
                )
              : ListView(
                  padding: const EdgeInsets.all(0),
                  children: [
                    // Search Bar Section
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: TextField(
                        controller: _searchController,
                        onChanged: provider.updateSearch,
                        decoration: InputDecoration(
                          hintText: 'Cari produk, brand, atau toko...',
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                    
                    // Category Filter Chips
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: provider.categories.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final category = provider.categories[index];
                            final selected = provider.selectedCategory == category.name;
                            return _CategoryChip(
                              label: category.name,
                              selected: selected,
                              onTap: () => provider.updateSelectedCategory(category.name),
                            );
                          },
                        ),
                      ),
                    ),
                    
                    // Divider
                    Container(
                      color: Colors.white,
                      child: const Divider(height: 0.5, color: Color(0xFFE2E8F0)),
                    ),
                    
                    // Filters & Info Section
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Filter Dropdowns Row
                          Row(
                            children: [
                              Expanded(
                                child: _FilterDropdown(
                                  label: 'Semua Toko',
                                  value: provider.selectedStore,
                                  options: provider.stores.map((item) => item.name),
                                  onChanged: (value) =>
                                      provider.updateSelectedStore(value ?? 'Semua'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _FilterDropdown(
                                  label: 'Urutan',
                                  value: provider.selectedSort,
                                  options: _sortOptions,
                                  onChanged: (value) =>
                                      provider.updateSort(value ?? 'Terbaru'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: provider.resetFilters,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: const Icon(
                                    Icons.refresh_rounded,
                                    size: 20,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Promo Count & Location Info
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${provider.filteredPromos.length} promo ditemukan',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0B1C30),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Location Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF4FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFD7E3FF)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: Color(0xFF2170E4),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Lokasi aktif, prioritaskan terdekat',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF2170E4),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Promo List
                    if (provider.filteredPromos.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: EmptyState(
                          title: 'Promo tidak ditemukan',
                          subtitle: 'Coba kata kunci, toko, kategori, atau urutan lain.',
                        ),
                      )
                    else
                      Container(
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: provider.filteredPromos.map((promo) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: PromoCard(
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
                                  variant: PromoCardVariant.list,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF10B981) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF64748B),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
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
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 13,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
        ),
      ),
      selectedItemBuilder: (context) => uniqueOptions
          .map(
            (item) => Text(
              item,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0B1C30),
              ),
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
