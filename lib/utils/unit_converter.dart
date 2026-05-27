class UnitConverter {
  static const Map<String, double> _mass = {
    'gram': 1,
    'kg': 1000,
  };
  static const Map<String, double> _volume = {
    'ml': 1,
    'liter': 1000,
  };
  static const Map<String, double> _count = {
    'pcs': 1,
    'pack': 1,
  };

  static double? calculateUnitPrice(double price, double size, String unit) {
    if (size <= 0) return null;
    final normalized = normalize(size, unit);
    if (normalized == null) return null;
    return price / normalized;
  }

  static double? normalize(double size, String unit) {
    final key = unit.toLowerCase();
    if (_mass.containsKey(key)) return size * _mass[key]!;
    if (_volume.containsKey(key)) return size * _volume[key]!;
    if (_count.containsKey(key)) return size * _count[key]!;
    return null;
  }
}

