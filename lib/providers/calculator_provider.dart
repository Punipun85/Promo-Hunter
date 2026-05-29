import 'package:flutter/foundation.dart';

import '../utils/unit_converter.dart';

class CalculatorInput {
  const CalculatorInput({
    required this.name,
    required this.price,
    required this.size,
    required this.unit,
    required this.quantity,
    this.storeName = '',
  });

  final String name;
  final double price;
  final double size;
  final String unit;
  final int quantity;
  final String storeName;
}

class CalculatorResultItem {
  const CalculatorResultItem({
    required this.name,
    required this.price,
    required this.size,
    required this.unit,
    required this.storeName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.unitFamily,
    required this.baseUnitLabel,
    required this.rank,
    required this.isCheapestInGroup,
    this.differenceFromBest,
  });

  final String name;
  final double price;
  final double size;
  final String unit;
  final String storeName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String unitFamily;
  final String baseUnitLabel;
  final int rank;
  final bool isCheapestInGroup;
  final double? differenceFromBest;
}

class CalculatorProvider extends ChangeNotifier {
  List<CalculatorResultItem> results = [];
  List<String> recommendations = [];
  String? errorMessage;

  void compareMany(List<CalculatorInput> products) {
    results = [];
    recommendations = [];
    errorMessage = null;

    final normalized = <_NormalizedProduct>[];
    for (final product in products) {
      final unitPrice = UnitConverter.calculateUnitPrice(
        product.price,
        product.size,
        product.unit,
      );
      final unitFamily = UnitConverter.unitFamily(product.unit);
      if (unitPrice == null || unitFamily == null) {
        errorMessage = 'Ada produk dengan ukuran atau satuan yang tidak valid.';
        notifyListeners();
        return;
      }
      normalized.add(
        _NormalizedProduct(
          input: product,
          unitPrice: unitPrice,
          totalPrice: product.price * product.quantity,
          unitFamily: unitFamily,
          baseUnitLabel: UnitConverter.baseUnitLabel(product.unit),
        ),
      );
    }

    final grouped = <String, List<_NormalizedProduct>>{};
    for (final item in normalized) {
      grouped.putIfAbsent(item.unitFamily, () => []).add(item);
    }

    final resultItems = <CalculatorResultItem>[];
    final recommendationItems = <String>[];

    for (final entry in grouped.entries) {
      final items = [...entry.value]..sort((a, b) => a.unitPrice.compareTo(b.unitPrice));
      final best = items.first;

      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        resultItems.add(
          CalculatorResultItem(
            name: item.input.name,
            price: item.input.price,
            size: item.input.size,
            unit: item.input.unit,
            storeName: item.input.storeName,
            quantity: item.input.quantity,
            unitPrice: item.unitPrice,
            totalPrice: item.totalPrice,
            unitFamily: item.unitFamily,
            baseUnitLabel: item.baseUnitLabel,
            rank: i + 1,
            isCheapestInGroup: i == 0,
            differenceFromBest:
                i == 0 ? 0 : item.unitPrice - best.unitPrice,
          ),
        );
      }

      recommendationItems.add(
        '${best.input.name} paling hemat untuk kelompok ${_familyLabel(entry.key)}.',
      );
    }

    results = resultItems
      ..sort((a, b) {
        final familyCompare = a.unitFamily.compareTo(b.unitFamily);
        if (familyCompare != 0) return familyCompare;
        return a.rank.compareTo(b.rank);
      });
    recommendations = recommendationItems;
    notifyListeners();
  }

  void reset() {
    results = [];
    recommendations = [];
    errorMessage = null;
    notifyListeners();
  }

  String _familyLabel(String family) {
    switch (family) {
      case 'mass':
        return 'berat';
      case 'volume':
        return 'volume';
      case 'count':
        return 'jumlah item';
      default:
        return family;
    }
  }
}

class _NormalizedProduct {
  const _NormalizedProduct({
    required this.input,
    required this.unitPrice,
    required this.totalPrice,
    required this.unitFamily,
    required this.baseUnitLabel,
  });

  final CalculatorInput input;
  final double unitPrice;
  final double totalPrice;
  final String unitFamily;
  final String baseUnitLabel;
}
