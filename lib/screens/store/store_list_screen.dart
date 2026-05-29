import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../providers/promo_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/store_card.dart';

class StoreListScreen extends StatelessWidget {
  const StoreListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PromoProvider>();
    final stores = provider.stores.where((store) => store.id != 0).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Toko')),
      body: provider.isLoading
          ? const LoadingWidget(message: 'Sedang memuat data toko...')
          : provider.errorMessage != null
              ? ErrorState(
                  title: 'Gagal memuat toko',
                  message: provider.errorMessage!,
                  onRetry: () => context.read<PromoProvider>().bootstrap(),
                )
              : stores.isEmpty
          ? const EmptyState(
              title: 'Belum ada toko',
              subtitle: 'Belum ada data toko yang bisa ditampilkan.',
              icon: Icons.storefront_outlined,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: stores.length,
              itemBuilder: (context, index) {
                final store = stores[index];
                return StoreCard(
                  store: store,
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.storeDetail,
                    arguments: store,
                  ),
                );
              },
            ),
    );
  }
}
