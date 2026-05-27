import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/promo_provider.dart';
import '../../widgets/empty_state.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final promoProvider = context.watch<PromoProvider>();
    if (!auth.isAdmin) {
      return const Scaffold(
        body: EmptyState(
          title: 'Akses ditolak',
          subtitle: 'Halaman ini hanya untuk admin.',
          icon: Icons.lock_outline,
        ),
      );
    }

    final totalPromos = promoProvider.promos.length;
    final activePromos =
        promoProvider.promos.where((promo) => !promo.isExpired).length;
    final expiredPromos = totalPromos - activePromos;

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _statCard(context, 'Total Promo', totalPromos.toString()),
          _statCard(context, 'Promo Aktif', activePromos.toString()),
          _statCard(context, 'Promo Expired', expiredPromos.toString()),
          _statCard(
            context,
            'Total Toko',
            (promoProvider.stores.length - 1).toString(),
          ),
          _statCard(
            context,
            'Total Kategori',
            (promoProvider.categories.length - 1).toString(),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.managePromos),
            icon: const Icon(Icons.local_offer_outlined),
            label: const Text('Kelola Promo'),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.manageStores),
            icon: const Icon(Icons.storefront_outlined),
            label: const Text('Kelola Toko'),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.manageCategories),
            icon: const Icon(Icons.category_outlined),
            label: const Text('Kelola Kategori'),
          ),
        ],
      ),
    );
  }

  Widget _statCard(BuildContext context, String label, String value) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}
