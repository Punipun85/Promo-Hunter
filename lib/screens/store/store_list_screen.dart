import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/promo_provider.dart';
import '../../widgets/empty_state.dart';

class StoreListScreen extends StatelessWidget {
  const StoreListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stores = context.watch<PromoProvider>().stores.where((store) => store.id != 0).toList();
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
                return Card(
                  child: ListTile(
                    title: Text(store.name),
                    subtitle: Text(
                      '${store.address}\n${store.city} • ${store.openingHours}\n${store.activePromoCount} promo aktif',
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.map_outlined),
                      onPressed: () async {
                        await launchUrl(
                          Uri.parse(store.googleMapsUrl),
                          mode: LaunchMode.externalApplication,
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}

