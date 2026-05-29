import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/category_model.dart';
import '../../models/promo_model.dart';
import '../../models/store_model.dart';
import '../../providers/promo_provider.dart';
import '../../services/storage_service.dart';
import '../../utils/validators.dart';

class PromoFormScreen extends StatefulWidget {
  const PromoFormScreen({super.key, this.initialPromo});

  final PromoModel? initialPromo;

  @override
  State<PromoFormScreen> createState() => _PromoFormScreenState();
}

class _PromoFormScreenState extends State<PromoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _storageService = StorageService();

  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _imageController;
  late final TextEditingController _normalPriceController;
  late final TextEditingController _promoPriceController;
  late final TextEditingController _unitSizeController;
  late final TextEditingController _termsController;

  String _unitType = 'pcs';
  StoreModel? _selectedStore;
  CategoryModel? _selectedCategory;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 3));
  String? _formError;
  bool _isUploadingImage = false;
  Uint8List? _pickedImageBytes;
  String? _pickedImageName;

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
    final availableStores =
        provider.stores.where((item) => item.id != 0).toList(growable: false);
    final availableCategories = provider.categories
        .where((item) => item.name != 'Semua')
        .toList(growable: false);

    _selectedStore ??= _resolveInitialStore(availableStores, promo);
    _selectedCategory ??= _resolveInitialCategory(availableCategories, promo);

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Promo' : 'Tambah Promo')),
      body: availableStores.isEmpty || availableCategories.isEmpty
          ? _MissingMasterData(
              hasStores: availableStores.isNotEmpty,
              hasCategories: availableCategories.isNotEmpty,
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _ImageSection(
                    imageUrl: _imageController.text.trim(),
                    imageBytes: _pickedImageBytes,
                    imageName: _pickedImageName,
                    isUploading: _isUploadingImage,
                    onPickImage: _pickAndUploadImage,
                  ),
                  const SizedBox(height: 16),
                  _field(_nameController, 'Nama produk'),
                  const SizedBox(height: 12),
                  _field(_brandController, 'Brand'),
                  const SizedBox(height: 12),
                  _field(
                    _imageController,
                    'URL gambar',
                    required: false,
                    helperText:
                        'Terisi otomatis setelah upload. Bisa juga diisi manual.',
                  ),
                  const SizedBox(height: 12),
                  _field(
                    _normalPriceController,
                    'Harga normal',
                    numeric: true,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    _promoPriceController,
                    'Harga promo',
                    numeric: true,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    _unitSizeController,
                    'Ukuran produk',
                    numeric: true,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _unitType,
                    decoration: const InputDecoration(labelText: 'Satuan'),
                    items: const [
                      'gram',
                      'kg',
                      'ml',
                      'liter',
                      'pcs',
                      'pack',
                      'sachet',
                    ]
                        .map(
                          (item) =>
                              DropdownMenuItem(value: item, child: Text(item)),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _unitType = value!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<StoreModel>(
                    initialValue: _selectedStore,
                    decoration: const InputDecoration(labelText: 'Toko'),
                    items: availableStores
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item.name),
                          ),
                        )
                        .toList(),
                    validator: (value) =>
                        value == null ? 'Toko wajib dipilih' : null,
                    onChanged: (value) => setState(() => _selectedStore = value),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<CategoryModel>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: availableCategories
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item.name),
                          ),
                        )
                        .toList(),
                    validator: (value) =>
                        value == null ? 'Kategori wajib dipilih' : null,
                    onChanged: (value) =>
                        setState(() => _selectedCategory = value),
                  ),
                  const SizedBox(height: 12),
                  _field(
                    _termsController,
                    'Syarat & ketentuan',
                    maxLines: 3,
                  ),
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
                  if (_formError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _formError!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _isUploadingImage
                        ? null
                        : () async {
                            setState(() => _formError = null);
                            if (!_formKey.currentState!.validate()) return;

                            final normalPrice =
                                double.parse(_normalPriceController.text.trim());
                            final promoPrice =
                                double.parse(_promoPriceController.text.trim());
                            final unitSize =
                                double.parse(_unitSizeController.text.trim());

                            if (promoPrice > normalPrice) {
                              setState(() {
                                _formError =
                                    'Harga promo tidak boleh lebih besar dari harga normal.';
                              });
                              return;
                            }

                            if (_endDate.isBefore(_startDate)) {
                              setState(() {
                                _formError =
                                    'Tanggal berakhir tidak boleh sebelum tanggal mulai.';
                              });
                              return;
                            }

                            final builtPromo = PromoModel(
                              id: promo?.id ?? 0,
                              productName: _nameController.text.trim(),
                              brand: _brandController.text.trim(),
                              imageUrl: _imageController.text.trim(),
                              normalPrice: normalPrice,
                              promoPrice: promoPrice,
                              unitSize: unitSize,
                              unitType: _unitType,
                              storeName: _selectedStore!.name,
                              storeAddress: _selectedStore!.address,
                              categoryName: _selectedCategory!.name,
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
                    child: Text(
                      _isUploadingImage
                          ? 'Mengunggah Gambar...'
                          : isEdit
                              ? 'Simpan Perubahan'
                              : 'Tambah Promo',
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (file == null) return;

      setState(() {
        _isUploadingImage = true;
        _formError = null;
        _pickedImageName = file.name;
      });

      final bytes = await _storageService.readBytes(file);
      if (!mounted) return;
      setState(() => _pickedImageBytes = bytes);

      final imageUrl = await _storageService.uploadPromoImage(file);
      if (!mounted) return;

      if (imageUrl == null) {
        setState(() {
          _formError =
              'Upload gambar belum tersedia. Pastikan Supabase dan bucket promo-images sudah siap.';
          _isUploadingImage = false;
        });
        return;
      }

      setState(() {
        _imageController.text = imageUrl;
        _isUploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gambar promo berhasil diunggah.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isUploadingImage = false;
        _formError =
            'Gagal mengunggah gambar. Periksa bucket storage atau koneksi lalu coba lagi.';
      });
    }
  }

  StoreModel? _resolveInitialStore(List<StoreModel> stores, PromoModel? promo) {
    if (stores.isEmpty) return null;
    if (promo == null) return stores.first;
    return stores.where((item) => item.name == promo.storeName).firstOrNull ??
        stores.first;
  }

  CategoryModel? _resolveInitialCategory(
    List<CategoryModel> categories,
    PromoModel? promo,
  ) {
    if (categories.isEmpty) return null;
    if (promo == null) return categories.first;
    return categories.where((item) => item.name == promo.categoryName).firstOrNull ??
        categories.first;
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool numeric = false,
    bool required = true,
    int maxLines = 1,
    String? helperText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
      ),
      validator: (value) {
        if (!required) return null;
        if (numeric) {
          return Validators.positiveNumber(value, label: label);
        }
        return Validators.requiredField(value, label: label);
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

class _ImageSection extends StatelessWidget {
  const _ImageSection({
    required this.imageUrl,
    required this.imageBytes,
    required this.imageName,
    required this.isUploading,
    required this.onPickImage,
  });

  final String imageUrl;
  final Uint8List? imageBytes;
  final String? imageName;
  final bool isUploading;
  final Future<void> Function() onPickImage;

  @override
  Widget build(BuildContext context) {
    final hasNetworkImage = imageUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gambar Produk',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              height: 190,
              color: Colors.white,
              child: imageBytes != null
                  ? Image.memory(imageBytes!, fit: BoxFit.cover)
                  : hasNetworkImage
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const _ImagePlaceholder(),
                        )
                      : const _ImagePlaceholder(),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            imageName ?? (hasNetworkImage ? 'Gambar sudah tersedia.' : 'Belum ada gambar dipilih.'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: isUploading ? null : onPickImage,
            icon: Icon(isUploading ? Icons.cloud_upload : Icons.photo_library_outlined),
            label: Text(isUploading ? 'Mengunggah...' : 'Upload dari Galeri'),
          ),
          const SizedBox(height: 8),
          Text(
            'Gunakan bucket public `promo-images` di Supabase Storage agar gambar bisa tampil di katalog.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF64748B),
                ),
          ),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_outlined,
            size: 42,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 8),
          Text(
            'Preview gambar promo',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _MissingMasterData extends StatelessWidget {
  const _MissingMasterData({
    required this.hasStores,
    required this.hasCategories,
  });

  final bool hasStores;
  final bool hasCategories;

  @override
  Widget build(BuildContext context) {
    final messages = <String>[
      if (!hasStores) 'Data toko belum tersedia.',
      if (!hasCategories) 'Data kategori belum tersedia.',
      'Lengkapi master data terlebih dahulu sebelum menambah promo.',
    ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 56),
            const SizedBox(height: 16),
            Text(
              'Master data belum lengkap',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ...messages.map(
              (message) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
