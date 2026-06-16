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
    final stores = provider.sortedStores;
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
              itemCount: stores.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: OutlinedButton.icon(
                      onPressed: provider.isLoadingLocation
                          ? null
                          : () => provider.refreshUserLocation(
                                makeNearestDefault: true,
                              ),
                      icon: provider.isLoadingLocation
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location_rounded),
                      label: Text(
                        provider.hasUserLocation
                            ? 'Toko diurutkan dari lokasi kamu'
                            : 'Gunakan lokasi saya',
                      ),
                    ),
                  );
                }
                final store = stores[index - 1];
                return StoreCard(
                  store: store,
                  distanceKm: provider.distanceToStore(store),
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
