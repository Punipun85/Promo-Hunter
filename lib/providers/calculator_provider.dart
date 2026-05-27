import 'package:flutter/foundation.dart';

import '../utils/unit_converter.dart';

class CalculatorProvider extends ChangeNotifier {
  String productAName = '';
  String productBName = '';
  double? productAUnitPrice;
  double? productBUnitPrice;
  String? recommendation;

  void compare({
    required String productA,
    required double priceA,
    required double sizeA,
    required String unitA,
    required String productB,
    required double priceB,
    required double sizeB,
    required String unitB,
  }) {
    productAName = productA;
    productBName = productB;
    productAUnitPrice = UnitConverter.calculateUnitPrice(priceA, sizeA, unitA);
    productBUnitPrice = UnitConverter.calculateUnitPrice(priceB, sizeB, unitB);

    if (productAUnitPrice == null || productBUnitPrice == null) {
      recommendation = 'Satuan tidak kompatibel untuk dibandingkan.';
    } else if (productAUnitPrice! < productBUnitPrice!) {
      recommendation = '$productA lebih hemat.';
    } else if (productBUnitPrice! < productAUnitPrice!) {
      recommendation = '$productB lebih hemat.';
    } else {
      recommendation = 'Keduanya setara.';
    }
    notifyListeners();
  }
}

