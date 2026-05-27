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
  final _controllers = List.generate(6, (_) => TextEditingController());
  String _unitA = 'liter';
  String _unitB = 'liter';
  final _units = const ['gram', 'kg', 'ml', 'liter', 'pcs', 'pack'];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calculator = context.watch<CalculatorProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Kalkulator Harga')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSectionTitle(context, 'Produk A'),
            _buildTextField(_controllers[0], 'Nama produk A'),
            const SizedBox(height: 12),
            _buildTextField(_controllers[1], 'Harga A', numeric: true),
            const SizedBox(height: 12),
            _buildTextField(_controllers[2], 'Ukuran A', numeric: true),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _unitA,
              items: _units.map((unit) => DropdownMenuItem(value: unit, child: Text(unit))).toList(),
              onChanged: (value) => setState(() => _unitA = value!),
              decoration: const InputDecoration(labelText: 'Satuan A'),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'Produk B'),
            _buildTextField(_controllers[3], 'Nama produk B'),
            const SizedBox(height: 12),
            _buildTextField(_controllers[4], 'Harga B', numeric: true),
            const SizedBox(height: 12),
            _buildTextField(_controllers[5], 'Ukuran B', numeric: true),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _unitB,
              items: _units.map((unit) => DropdownMenuItem(value: unit, child: Text(unit))).toList(),
              onChanged: (value) => setState(() => _unitB = value!),
              decoration: const InputDecoration(labelText: 'Satuan B'),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                calculator.compare(
                  productA: _controllers[0].text.trim(),
                  priceA: double.parse(_controllers[1].text),
                  sizeA: double.parse(_controllers[2].text),
                  unitA: _unitA,
                  productB: _controllers[3].text.trim(),
                  priceB: double.parse(_controllers[4].text),
                  sizeB: double.parse(_controllers[5].text),
                  unitB: _unitB,
                );
              },
              child: const Text('Hitung'),
            ),
            if (calculator.recommendation != null) ...[
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hasil', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      Text(
                        '${calculator.productAName}: ${calculator.productAUnitPrice == null ? '-' : CurrencyFormatter.format(calculator.productAUnitPrice!)} / unit dasar',
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${calculator.productBName}: ${calculator.productBUnitPrice == null ? '-' : CurrencyFormatter.format(calculator.productBUnitPrice!)} / unit dasar',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        calculator.recommendation!,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool numeric = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return '$label wajib diisi';
        if (numeric && double.tryParse(value) == null) return '$label harus angka';
        return null;
      },
    );
  }
}

