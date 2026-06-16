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
      appBar: AppBar(
        title: const Text('Kelola Promo'),
        actions: [
          IconButton(
            tooltip: 'Sync promo dari n8n',
            onPressed: provider.isSyncingN8n
                ? null
                : () async {
                    try {
                      final imported =
                          await context.read<PromoProvider>().syncPromosFromN8n();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            imported == 0
                                ? 'n8n dicek, belum ada promo baru.'
                                : '$imported promo baru berhasil diimpor.',
                          ),
                        ),
                      );
                    } catch (_) {
                      if (!context.mounted) return;
                      final message =
                          context.read<PromoProvider>().syncMessage ??
                              'Gagal sync dari n8n. Cek workflow dan koneksi.';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message),
                        ),
                      );
                    }
                  },
            icon: provider.isSyncingN8n
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.promoForm),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Promo'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4FF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.hub_outlined,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    provider.isSyncingN8n
                        ? 'Sedang scraping promo dari n8n. Proses bisa memakan waktu 1-3 menit...'
                        : provider.syncMessage ??
                            'Ambil promo otomatis dari n8n agar katalog selalu terisi. Format data mengikuti tabel PromoHunter.',
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: provider.isSyncingN8n
                      ? null
                      : () async {
                          try {
                            final imported = await context
                                .read<PromoProvider>()
                                .syncPromosFromN8n();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  imported == 0
                                      ? 'n8n dicek, belum ada promo baru.'
                                      : '$imported promo baru berhasil diimpor.',
                                ),
                              ),
                            );
                          } catch (_) {
                            if (!context.mounted) return;
                            final message =
                                context.read<PromoProvider>().syncMessage ??
                                    'Gagal sync dari n8n. Cek workflow dan koneksi.';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(message),
                              ),
                            );
                          }
                        },
                  child: const Text('Sync'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (provider.promos.isEmpty)
            const EmptyState(
              title: 'Belum ada promo',
              subtitle:
                  'Tambahkan promo manual atau tekan Sync untuk mengambil dari n8n.',
            )
          else
            ...List.generate(provider.promos.length, (index) {
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
              }),
        ],
      ),
    );
  }
}
