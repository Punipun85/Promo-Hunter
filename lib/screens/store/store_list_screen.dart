import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../providers/promo_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/store_card.dart';

class StoreListScreen extends StatelessWidget {
  const StoreListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stores =
        context.watch<PromoProvider>().stores.where((store) => store.id != 0).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Toko')),
      body: stores.isEmpty
          ? const EmptyState(
              title: 'Belum ada toko',
              subtitle: 'Data toko akan muncul setelah backend dihubungkan.',
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
