import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/promo_provider.dart';
import '../../widgets/empty_state.dart';
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
    final favorites = context.watch<PromoProvider>().favoritePromos;
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
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.promoDetail,
                    arguments: promo,
                  ),
                  onFavoriteTap: () =>
                      context.read<PromoProvider>().toggleFavorite(promo.id),
                );
              },
            ),
    );
  }
}
