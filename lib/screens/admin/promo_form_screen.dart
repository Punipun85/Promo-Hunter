import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/promo_model.dart';
import '../../providers/promo_provider.dart';
import '../../utils/validators.dart';

class PromoFormScreen extends StatefulWidget {
  const PromoFormScreen({super.key, this.initialPromo});

  final PromoModel? initialPromo;

  @override
  State<PromoFormScreen> createState() => _PromoFormScreenState();
}

class _PromoFormScreenState extends State<PromoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _imageController;
  late final TextEditingController _normalPriceController;
  late final TextEditingController _promoPriceController;
  late final TextEditingController _unitSizeController;
  late final TextEditingController _termsController;

  String _unitType = 'pcs';
  String _storeName = 'Indomaret Sudirman';
  String _storeAddress = 'Jl. Sudirman No. 8';
  String _categoryName = 'Minyak';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 3));

  @override
  void initState() {
    super.initState();
    final promo = widget.initialPromo;
    _nameController = TextEditingController(text: promo?.productName ?? '');
    _brandController = TextEditingController(text: promo?.brand ?? '');
    _imageController = TextEditingController(text: promo?.imageUrl ?? '');
    _normalPriceController = TextEditingController(
      text: promo == null ? '' : promo.normalPrice.toStringAsFixed(0),
    );
    _promoPriceController = TextEditingController(
      text: promo == null ? '' : promo.promoPrice.toStringAsFixed(0),
    );
    _unitSizeController = TextEditingController(
      text: promo == null ? '' : promo.unitSize.toString(),
    );
    _termsController = TextEditingController(text: promo?.terms ?? '');
    _unitType = promo?.unitType ?? _unitType;
    _storeName = promo?.storeName ?? _storeName;
    _storeAddress = promo?.storeAddress ?? _storeAddress;
    _categoryName = promo?.categoryName ?? _categoryName;
    _startDate = promo?.startDate ?? _startDate;
    _endDate = promo?.endDate ?? _endDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _imageController.dispose();
    _normalPriceController.dispose();
    _promoPriceController.dispose();
    _unitSizeController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<PromoProvider>();
    final promo = widget.initialPromo;
    final isEdit = promo != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Promo' : 'Tambah Promo')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _field(_nameController, 'Nama produk'),
            const SizedBox(height: 12),
            _field(_brandController, 'Brand'),
            const SizedBox(height: 12),
            _field(_imageController, 'URL gambar'),
            const SizedBox(height: 12),
            _field(_normalPriceController, 'Harga normal', numeric: true),
            const SizedBox(height: 12),
            _field(_promoPriceController, 'Harga promo', numeric: true),
            const SizedBox(height: 12),
            _field(_unitSizeController, 'Ukuran produk', numeric: true),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _unitType,
              decoration: const InputDecoration(labelText: 'Satuan'),
              items: const ['gram', 'kg', 'ml', 'liter', 'pcs', 'pack']
                  .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                  .toList(),
              onChanged: (value) => setState(() => _unitType = value!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _storeName,
              decoration: const InputDecoration(labelText: 'Toko'),
              items: provider.stores
                  .where((item) => item.id != 0)
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.name,
                      child: Text(item.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                final store =
                    provider.stores.firstWhere((item) => item.name == value);
                setState(() {
                  _storeName = store.name;
                  _storeAddress = store.address;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _categoryName,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: provider.categories
                  .where((item) => item.name != 'Semua')
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.name,
                      child: Text(item.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _categoryName = value!),
            ),
            const SizedBox(height: 12),
            _field(_termsController, 'Syarat & ketentuan', maxLines: 3),
            const SizedBox(height: 12),
            _dateTile(
              context,
              label: 'Tanggal mulai',
              value: _startDate,
              onPick: (picked) => setState(() => _startDate = picked),
            ),
            _dateTile(
              context,
              label: 'Tanggal berakhir',
              value: _endDate,
              onPick: (picked) => setState(() => _endDate = picked),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                final normalPrice = double.parse(_normalPriceController.text);
                final promoPrice = double.parse(_promoPriceController.text);
                if (promoPrice > normalPrice) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Harga promo tidak boleh lebih besar dari harga normal.',
                      ),
                    ),
                  );
                  return;
                }
                if (_endDate.isBefore(_startDate)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Tanggal berakhir tidak boleh sebelum tanggal mulai.',
                      ),
                    ),
                  );
                  return;
                }

                final builtPromo = PromoModel(
                  id: promo?.id ?? 0,
                  productName: _nameController.text.trim(),
                  brand: _brandController.text.trim(),
                  imageUrl: _imageController.text.trim(),
                  normalPrice: normalPrice,
                  promoPrice: promoPrice,
                  unitSize: double.parse(_unitSizeController.text),
                  unitType: _unitType,
                  storeName: _storeName,
                  storeAddress: _storeAddress,
                  categoryName: _categoryName,
                  startDate: _startDate,
                  endDate: _endDate,
                  terms: _termsController.text.trim(),
                );

                if (isEdit) {
                  await provider.updateExistingPromo(builtPromo);
                } else {
                  await provider.createPromo(builtPromo);
                }

                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: Text(isEdit ? 'Simpan Perubahan' : 'Tambah Promo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool numeric = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final required = Validators.requiredField(value, label: label);
        if (required != null) return required;
        if (numeric && double.tryParse(value!) == null) {
          return '$label harus angka';
        }
        return null;
      },
    );
  }

  Widget _dateTile(
    BuildContext context, {
    required String label,
    required DateTime value,
    required ValueChanged<DateTime> onPick,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text('${value.day}/${value.month}/${value.year}'),
      trailing: IconButton(
        icon: const Icon(Icons.calendar_today_outlined),
        onPressed: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value,
            firstDate: DateTime(2024),
            lastDate: DateTime(2030),
          );
          if (picked != null) onPick(picked);
        },
      ),
    );
  }
}
