import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../providers/promo_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/promo_card.dart';

class PromoListScreen extends StatelessWidget {
  const PromoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PromoProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Promo')),
      body: provider.filteredPromos.isEmpty
          ? const EmptyState(
              title: 'Promo tidak ditemukan',
              subtitle: 'Coba kata kunci atau filter lain.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: provider.filteredPromos.length,
              itemBuilder: (context, index) {
                final promo = provider.filteredPromos[index];
                return PromoCard(
                  promo: promo,
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.promoDetail,
                    arguments: promo,
                  ),
                  onFavoriteTap: () => provider.toggleFavorite(promo.id),
                );
              },
            ),
    );
  }
}

