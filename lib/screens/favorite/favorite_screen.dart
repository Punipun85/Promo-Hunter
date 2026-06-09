import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_experience_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/promo_provider.dart';
import '../../utils/promo_access_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/promo_card.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Promo Favorit')),
        body: Center(
          child: FilledButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
            child: const Text('Login untuk melihat favorit'),
          ),
        ),
      );
    }

    final favoriteProvider = context.watch<FavoriteProvider>();
    final promoProvider = context.watch<PromoProvider>();
    final experience = context.watch<DashboardExperienceProvider>();
    if (favoriteProvider.isLoading || promoProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Promo Favorit')),
        body: const LoadingWidget(message: 'Sedang memuat promo favorit...'),
      );
    }
    final favorites = promoProvider.promos
        .where((promo) => favoriteProvider.isFavorite(promo.id))
        .map((promo) => promo.copyWith(isFavorite: true))
        .toList()
      ..sort((a, b) => a.endDate.compareTo(b.endDate));

    return Scaffold(
      appBar: AppBar(title: const Text('Promo Favorit')),
      body: favorites.isEmpty
          ? const EmptyState(
              title: 'Belum ada promo favorit',
              subtitle: 'Simpan promo dari halaman detail atau daftar promo.',
              icon: Icons.favorite_border,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final promo = favorites[index];
                return PromoCard(
                  promo: promo,
                  isLocked: experience.isPromoLocked(promo.id),
                  lockLabel: experience.promoLockLabel(promo.id),
                  onTap: () => openPromoWithAccessGuard(context, promo),
                  onFavoriteTap: () => context
                      .read<FavoriteProvider>()
                      .toggleFavorite(auth.currentUser!.id, promo),
                );
              },
            ),
    );
  }
}
