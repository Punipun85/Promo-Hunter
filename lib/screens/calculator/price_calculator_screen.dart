import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/calculator_provider.dart';
import '../../utils/currency_formatter.dart';

class PriceCalculatorScreen extends StatefulWidget {
  const PriceCalculatorScreen({super.key});

  @override
  State<PriceCalculatorScreen> createState() => _PriceCalculatorScreenState();
}

class _PriceCalculatorScreenState extends State<PriceCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _units = const ['gram', 'kg', 'ml', 'liter', 'pcs', 'pack', 'sachet'];
  late final List<_CalculatorEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = [_CalculatorEntry(), _CalculatorEntry()];
  }

  @override
  void dispose() {
    for (final entry in _entries) {
      entry.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calculator = context.watch<CalculatorProvider>();
    final groupedResults = <String, List<CalculatorResultItem>>{};
    for (final item in calculator.results) {
      groupedResults.putIfAbsent(item.unitFamily, () => []).add(item);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Kalkulator Harga')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Bandingkan banyak produk sekaligus dan tentukan jumlah barang yang ingin dibeli.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
            ),
            const SizedBox(height: 20),
            ...List.generate(_entries.length, (index) {
              final entry = _entries[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ProductFormCard(
                  index: index,
                  entry: entry,
                  units: _units,
                  canRemove: _entries.length > 2,
                  onRemove: () {
                    setState(() {
                      final removed = _entries.removeAt(index);
                      removed.dispose();
                    });
                  },
                ),
              );
            }),
            OutlinedButton.icon(
              onPressed: () => setState(() => _entries.add(_CalculatorEntry())),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah Produk'),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                final inputs = _entries
                    .map(
                      (entry) => CalculatorInput(
                        name: entry.nameController.text.trim(),
                        storeName: entry.storeController.text.trim(),
                        price: double.parse(entry.priceController.text),
                        size: double.parse(entry.sizeController.text),
                        unit: entry.unit,
                        quantity: int.parse(entry.quantityController.text),
                      ),
                    )
                    .toList();
                calculator.compareMany(inputs);
              },
              child: const Text('Hitung Semua'),
            ),
            if (calculator.errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                calculator.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (calculator.recommendations.isNotEmpty) ...[
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rekomendasi',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      ...calculator.recommendations.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('- $item'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (groupedResults.isNotEmpty) ...[
              const SizedBox(height: 20),
              ...groupedResults.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _groupTitle(entry.key),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          ...entry.value.map(
                            (item) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: item.isCheapestInGroup
                                    ? const Color(0xFFEFFFF4)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${item.rank}. ${item.name}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                      ),
                                      if (item.isCheapestInGroup)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFF0A8),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            'Paling hemat',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(
                                                  color: const Color(0xFF7C5A00),
                                                ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (item.storeName.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      item.storeName,
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Text(
                                    '${CurrencyFormatter.format(item.price)} untuk ${item.size} ${item.unit}',
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Jumlah dibeli: ${item.quantity} item',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${CurrencyFormatter.format(item.unitPrice)} / ${item.baseUnitLabel}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Total belanja: ${CurrencyFormatter.format(item.totalPrice)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  if (!item.isCheapestInGroup &&
                                      item.differenceFromBest != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Selisih ${CurrencyFormatter.format(item.differenceFromBest!)} per ${item.baseUnitLabel} dari yang termurah',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _groupTitle(String key) {
    switch (key) {
      case 'mass':
        return 'Perbandingan Berat';
      case 'volume':
        return 'Perbandingan Volume';
      case 'count':
        return 'Perbandingan Jumlah Item';
      default:
        return 'Hasil';
    }
  }
}

class _ProductFormCard extends StatelessWidget {
  const _ProductFormCard({
    required this.index,
    required this.entry,
    required this.units,
    required this.canRemove,
    required this.onRemove,
  });

  final int index;
  final _CalculatorEntry entry;
  final List<String> units;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Produk ${index + 1}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (canRemove)
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _field(entry.nameController, 'Nama produk'),
            const SizedBox(height: 12),
            _field(entry.storeController, 'Nama toko (opsional)', required: false),
            const SizedBox(height: 12),
            _field(entry.priceController, 'Harga', numeric: true),
            const SizedBox(height: 12),
            _field(entry.sizeController, 'Ukuran', numeric: true),
            const SizedBox(height: 12),
            _field(
              entry.quantityController,
              'Jumlah barang',
              numeric: true,
              integerOnly: true,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: entry.unit,
              decoration: const InputDecoration(labelText: 'Satuan'),
              items: units
                  .map(
                    (unit) => DropdownMenuItem(
                      value: unit,
                      child: Text(unit),
                    ),
                  )
                  .toList(),
              onChanged: (value) => entry.unit = value ?? entry.unit,
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
    bool required = true,
    bool integerOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (!required) return null;
        if (value == null || value.trim().isEmpty) return '$label wajib diisi';
        if (integerOnly && int.tryParse(value) == null) {
          return '$label harus bilangan bulat';
        }
        if (numeric && !integerOnly && double.tryParse(value) == null) {
          return '$label harus angka';
        }
        final parsed = integerOnly
            ? (int.tryParse(value) ?? 0).toDouble()
            : (double.tryParse(value) ?? 0);
        if (numeric && parsed <= 0) {
          return '$label harus lebih dari 0';
        }
        return null;
      },
    );
  }
}

class _CalculatorEntry {
  _CalculatorEntry()
      : nameController = TextEditingController(),
        storeController = TextEditingController(),
        priceController = TextEditingController(),
        sizeController = TextEditingController(),
        quantityController = TextEditingController(text: '1');

  final TextEditingController nameController;
  final TextEditingController storeController;
  final TextEditingController priceController;
  final TextEditingController sizeController;
  final TextEditingController quantityController;
  String unit = 'liter';

  void dispose() {
    nameController.dispose();
    storeController.dispose();
    priceController.dispose();
    sizeController.dispose();
    quantityController.dispose();
  }
}
