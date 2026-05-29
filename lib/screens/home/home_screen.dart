import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/promo_provider.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/promo_card.dart';
import '../../widgets/store_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final favoriteProvider = context.watch<FavoriteProvider>();
    final promoProvider = context.watch<PromoProvider>();
    final nearbyStores =
        promoProvider.stores.where((store) => store.id != 0).take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              auth.isLoggedIn
                  ? 'Halo, ${auth.currentUser?.name.split(' ').first ?? 'Teman'}'
                  : 'Halo, pemburu promo',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text('PromoHunter', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
            icon: const Icon(Icons.person_outline_rounded),
          ),
        ],
      ),
      body: promoProvider.isLoading
          ? const LoadingWidget(message: 'Sedang memuat promo pilihan...')
          : promoProvider.errorMessage != null
              ? ErrorState(
                  title: 'Gagal memuat beranda',
                  message: promoProvider.errorMessage!,
                  onRetry: () => context.read<PromoProvider>().bootstrap(),
                )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x10000000),
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0A8),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Diskon pilihan hari ini',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: const Color(0xFF7C5A00),
                              ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Cari promo apa hari ini?',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pantau diskon, bandingkan harga, dan belanja lebih hemat dari satu dashboard yang rapi.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: const Color(0xFF64748B),
                            ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF4FF),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${promoProvider.popularPromos.length}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primaryContainer,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'promo aktif',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F7FF),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${nearbyStores.length}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondaryContainer,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'toko siap dikunjungi',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  onChanged: promoProvider.updateSearch,
                  decoration: const InputDecoration(
                    hintText: 'Cari minyak, beras, susu...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: promoProvider.categories.map((category) {
                      return CategoryChip(
                        label: category.name,
                        selected: promoProvider.selectedCategory == category.name,
                        onTap: () =>
                            promoProvider.updateSelectedCategory(category.name),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                _SectionHeader(
                  title: 'Promo Populer',
                  actionLabel: 'Jelajahi',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.promoList),
                ),
                const SizedBox(height: 12),
                ...promoProvider.popularPromos.take(3).map(
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
                const SizedBox(height: 8),
                _SectionHeader(
                  title: 'Promo Hampir Berakhir',
                  actionLabel: 'Lihat semua',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.promoList),
                ),
                const SizedBox(height: 12),
                ...promoProvider.endingSoonPromos.take(3).map(
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
                if (promoProvider.recentlyViewedPromos.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _SectionHeader(
                    title: 'Terakhir Dilihat',
                    actionLabel: 'Lihat promo',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.promoList),
                  ),
                  const SizedBox(height: 12),
                  ...promoProvider.recentlyViewedPromos.take(3).map(
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
                        favoriteProvider.toggleFavorite(
                          auth.currentUser!.id,
                          promo,
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                _SectionHeader(
                  title: 'Toko Terdekat',
                  actionLabel: 'Lihat toko',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.stores),
                ),
                const SizedBox(height: 12),
                if (nearbyStores.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Text(
                      'Toko terdekat akan muncul setelah data toko tersedia.',
                    ),
                  )
                else
                  SizedBox(
                    height: 230,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: nearbyStores.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final store = nearbyStores[index];
                        return StoreCard(
                          store: store,
                          compact: true,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.storeDetail,
                            arguments: store,
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.favorites),
                      icon: const Icon(Icons.favorite_border_rounded),
                      label: const Text('Favorit'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.reminders),
                      icon: const Icon(Icons.notifications_none_rounded),
                      label: const Text('Reminder'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.calculator),
                      icon: const Icon(Icons.calculate_outlined),
                      label: const Text('Kalkulator'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.shoppingList),
                      icon: const Icon(Icons.shopping_cart_outlined),
                      label: const Text('Belanja'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.stores),
                      icon: const Icon(Icons.store_mall_directory_outlined),
                      label: const Text('Toko'),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        TextButton(onPressed: onTap, child: Text(actionLabel)),
      ],
    );
  }
}
