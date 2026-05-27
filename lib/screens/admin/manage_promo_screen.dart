import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../providers/promo_provider.dart';
import '../../widgets/empty_state.dart';

class ManagePromoScreen extends StatelessWidget {
  const ManagePromoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PromoProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Promo')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.promoForm),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Promo'),
      ),
      body: provider.promos.isEmpty
          ? const EmptyState(
              title: 'Belum ada promo',
              subtitle: 'Tambahkan promo baru untuk mulai mengelola katalog.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: provider.promos.length,
              itemBuilder: (context, index) {
                final promo = provider.promos[index];
                return Card(
                  child: ListTile(
                    title: Text(promo.productName),
                    subtitle: Text(
                      '${promo.storeName}\n${promo.categoryName} - Rp${promo.promoPrice.toStringAsFixed(0)}',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await Navigator.pushNamed(
                            context,
                            AppRoutes.promoForm,
                            arguments: promo,
                          );
                        } else if (value == 'delete') {
                          await provider.deletePromo(promo.id);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Hapus')),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
