import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/store_model.dart';
import '../../providers/promo_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/empty_state.dart';

class ManageStoreScreen extends StatelessWidget {
  const ManageStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PromoProvider>();
    final stores = provider.stores.where((item) => item.id != 0).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Toko')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openStoreForm(context),
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('Tambah Toko'),
      ),
      body: stores.isEmpty
          ? const EmptyState(
              title: 'Belum ada toko',
              subtitle: 'Tambahkan toko baru untuk mengelola promo.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: stores.length,
              itemBuilder: (context, index) {
                final store = stores[index];
                return Card(
                  child: ListTile(
                    title: Text(store.name),
                    subtitle: Text('${store.address}\n${store.city}'),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          _openStoreForm(context, initialStore: store);
                        } else if (value == 'delete') {
                          await provider.deleteStore(store.id);
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

  Future<void> _openStoreForm(
    BuildContext context, {
    StoreModel? initialStore,
  }) async {
    final provider = context.read<PromoProvider>();
    final nameController = TextEditingController(text: initialStore?.name ?? '');
    final addressController =
        TextEditingController(text: initialStore?.address ?? '');
    final cityController = TextEditingController(text: initialStore?.city ?? '');
    final mapsController =
        TextEditingController(text: initialStore?.googleMapsUrl ?? '');
    final hoursController =
        TextEditingController(text: initialStore?.openingHours ?? '');
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  initialStore == null ? 'Tambah Toko' : 'Edit Toko',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _field(nameController, 'Nama toko'),
                const SizedBox(height: 12),
                _field(addressController, 'Alamat'),
                const SizedBox(height: 12),
                _field(cityController, 'Kota'),
                const SizedBox(height: 12),
                _field(mapsController, 'Google Maps URL'),
                const SizedBox(height: 12),
                _field(hoursController, 'Jam buka'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final store = StoreModel(
                      id: initialStore?.id ?? 0,
                      name: nameController.text.trim(),
                      address: addressController.text.trim(),
                      city: cityController.text.trim(),
                      googleMapsUrl: mapsController.text.trim(),
                      openingHours: hoursController.text.trim(),
                      activePromoCount: initialStore?.activePromoCount ?? 0,
                    );
                    if (initialStore == null) {
                      await provider.createStore(store);
                    } else {
                      await provider.updateStore(store);
                    }
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  child: Text(initialStore == null ? 'Tambah' : 'Simpan'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _field(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      validator: (value) => Validators.requiredField(value, label: label),
    );
  }
}

