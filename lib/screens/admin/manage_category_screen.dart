import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/category_model.dart';
import '../../providers/promo_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/empty_state.dart';

class ManageCategoryScreen extends StatelessWidget {
  const ManageCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PromoProvider>();
    final categories =
        provider.categories.where((item) => item.name != 'Semua').toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Kategori')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCategoryForm(context),
        icon: const Icon(Icons.category_outlined),
        label: const Text('Tambah Kategori'),
      ),
      body: categories.isEmpty
          ? const EmptyState(
              title: 'Belum ada kategori',
              subtitle: 'Tambahkan kategori baru untuk mengelola promo.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Card(
                  child: ListTile(
                    title: Text(category.name),
                    subtitle: Text('Icon: ${category.icon}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          _openCategoryForm(context, initialCategory: category);
                        } else if (value == 'delete') {
                          await provider.deleteCategory(category.id);
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

  Future<void> _openCategoryForm(
    BuildContext context, {
    CategoryModel? initialCategory,
  }) async {
    final provider = context.read<PromoProvider>();
    final nameController =
        TextEditingController(text: initialCategory?.name ?? '');
    final iconController =
        TextEditingController(text: initialCategory?.icon ?? 'category');
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
                  initialCategory == null
                      ? 'Tambah Kategori'
                      : 'Edit Kategori',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama kategori'),
                  validator: (value) =>
                      Validators.requiredField(value, label: 'Nama kategori'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: iconController,
                  decoration: const InputDecoration(labelText: 'Kode icon'),
                  validator: (value) =>
                      Validators.requiredField(value, label: 'Kode icon'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final category = CategoryModel(
                      id: initialCategory?.id ?? 0,
                      name: nameController.text.trim(),
                      icon: iconController.text.trim(),
                    );
                    if (initialCategory == null) {
                      await provider.createCategory(category);
                    } else {
                      await provider.updateCategory(category);
                    }
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  child: Text(initialCategory == null ? 'Tambah' : 'Simpan'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
