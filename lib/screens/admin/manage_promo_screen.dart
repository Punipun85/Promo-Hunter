import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../providers/promo_provider.dart';
import '../../widgets/empty_state.dart';

class ManagePromoScreen extends StatelessWidget {
  const ManagePromoScreen({super.key});

  Future<void> _syncPromos(
    BuildContext context, {
    required bool fromNotion,
  }) async {
    try {
      final promoProvider = context.read<PromoProvider>();
      final imported = fromNotion
          ? await promoProvider.syncPromosFromNotion()
          : await promoProvider.syncPromosFromN8n();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            imported == 0
                ? promoProvider.syncMessage ??
                    'n8n dicek, belum ada promo baru.'
                : '$imported promo baru berhasil diimpor.',
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      final message = context.read<PromoProvider>().syncMessage ??
          'Gagal sync dari n8n. Cek workflow dan koneksi.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

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
                : () => _syncPromos(context, fromNotion: false),
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 420;
                return isCompact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.hub_outlined,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  provider.isSyncingN8n
                                      ? 'Sedang mengambil promo dari n8n. Proses bisa memakan waktu 1-3 menit...'
                                      : provider.syncMessage ??
                                          'Ambil promo otomatis dari web scraping atau promo kurasi dari Notion. Gambar akan diupload ke Supabase Storage.',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton.tonalIcon(
                                onPressed: provider.isSyncingN8n
                                    ? null
                                    : () =>
                                        _syncPromos(context, fromNotion: false),
                                icon: const Icon(Icons.public_rounded),
                                label: const Text('Web'),
                              ),
                              FilledButton.icon(
                                onPressed: provider.isSyncingN8n
                                    ? null
                                    : () =>
                                        _syncPromos(context, fromNotion: true),
                                icon: const Icon(Icons.table_chart_outlined),
                                label: const Text('Notion'),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Icon(
                            Icons.hub_outlined,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              provider.isSyncingN8n
                                  ? 'Sedang mengambil promo dari n8n. Proses bisa memakan waktu 1-3 menit...'
                                  : provider.syncMessage ??
                                      'Ambil promo otomatis dari web scraping atau promo kurasi dari Notion. Gambar akan diupload ke Supabase Storage.',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.end,
                            children: [
                              FilledButton.tonalIcon(
                                onPressed: provider.isSyncingN8n
                                    ? null
                                    : () =>
                                        _syncPromos(context, fromNotion: false),
                                icon: const Icon(Icons.public_rounded),
                                label: const Text('Web'),
                              ),
                              FilledButton.icon(
                                onPressed: provider.isSyncingN8n
                                    ? null
                                    : () =>
                                        _syncPromos(context, fromNotion: true),
                                icon: const Icon(Icons.table_chart_outlined),
                                label: const Text('Notion'),
                              ),
                            ],
                          ),
                        ],
                      );
              },
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
