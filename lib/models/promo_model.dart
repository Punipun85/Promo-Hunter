class PromoModel {
  const PromoModel({
    required this.id,
    required this.productName,
    required this.brand,
    required this.imageUrl,
    required this.normalPrice,
    required this.promoPrice,
    required this.unitSize,
    required this.unitType,
    required this.storeName,
    required this.storeAddress,
    required this.categoryName,
    required this.startDate,
    required this.endDate,
    required this.terms,
    this.sourceUrl = '',
    this.isFavorite = false,
    this.isActive = true,
  });

  final int id;
  final String productName;
  final String brand;
  final String imageUrl;
  final double normalPrice;
  final double promoPrice;
  final double unitSize;
  final String unitType;
  final String storeName;
  final String storeAddress;
  final String categoryName;
  final DateTime startDate;
  final DateTime endDate;
  final String terms;
  final String sourceUrl;
  final bool isFavorite;
  final bool isActive;

  double get discountPercent =>
      ((normalPrice - promoPrice) / normalPrice * 100).clamp(0, 100);

  double get savingsAmount => (normalPrice - promoPrice).clamp(0, normalPrice);

  DateTime get _today =>
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  bool get isExpired => endDate.isBefore(_today);

  bool get isEndingToday => !isExpired && _sameDay(endDate, _today);

  bool get isEndingTomorrow =>
      !isExpired &&
      _sameDay(
        endDate,
        _today.add(const Duration(days: 1)),
      );

  bool get isEndingSoon =>
      !isExpired && endDate.difference(_today).inDays <= 2;

  int get remainingDays => endDate.difference(_today).inDays;

  double get unitPrice => promoPrice / unitSize;

  String get statusLabel {
    if (isExpired) return 'Expired';
    if (isEndingToday) return 'Berakhir Hari Ini';
    if (isEndingTomorrow) return 'Berakhir Besok';
    if (isEndingSoon) return 'Hampir Berakhir';
    return 'Aktif';
  }

  bool get showStatusBadge => isExpired || isEndingSoon || isActive;

  static bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  factory PromoModel.fromMap(Map<String, dynamic> map) {
    return PromoModel(
      id: (map['id'] as num).toInt(),
      productName: map['product_name'] as String? ?? '',
      brand: map['brand'] as String? ?? '',
      imageUrl: map['image_url'] as String? ?? '',
      normalPrice: ((map['normal_price'] ?? 0) as num).toDouble(),
      promoPrice: ((map['promo_price'] ?? 0) as num).toDouble(),
      unitSize: ((map['unit_size'] ?? 1) as num).toDouble(),
      unitType: map['unit_type'] as String? ?? 'pcs',
      storeName:
          map['stores']?['name'] as String? ?? map['store_name'] as String? ?? '',
      storeAddress: map['stores']?['address'] as String? ??
          map['store_address'] as String? ??
          '',
      categoryName: map['categories']?['name'] as String? ??
          map['category_name'] as String? ??
          '',
      startDate:
          DateTime.tryParse(map['start_date']?.toString() ?? '') ?? DateTime.now(),
      endDate:
          DateTime.tryParse(map['end_date']?.toString() ?? '') ?? DateTime.now(),
      terms: map['terms'] as String? ?? '',
      sourceUrl: map['source_url'] as String? ?? '',
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toInsertMap({
    int? storeId,
    int? categoryId,
  }) {
    return {
      'store_id': storeId,
      'category_id': categoryId,
      'product_name': productName,
      'brand': brand,
      'image_url': imageUrl,
      'normal_price': normalPrice,
      'promo_price': promoPrice,
      'unit_size': unitSize,
      'unit_type': unitType,
      'discount_percent': discountPercent,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'terms': terms,
      'source_url': sourceUrl,
      'is_active': isActive,
    };
  }

  PromoModel copyWith({
    int? id,
    String? productName,
    String? brand,
    String? imageUrl,
    double? normalPrice,
    double? promoPrice,
    double? unitSize,
    String? unitType,
    String? storeName,
    String? storeAddress,
    String? categoryName,
    DateTime? startDate,
    DateTime? endDate,
    String? terms,
    String? sourceUrl,
    bool? isFavorite,
    bool? isActive,
  }) {
    return PromoModel(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      brand: brand ?? this.brand,
      imageUrl: imageUrl ?? this.imageUrl,
      normalPrice: normalPrice ?? this.normalPrice,
      promoPrice: promoPrice ?? this.promoPrice,
      unitSize: unitSize ?? this.unitSize,
      unitType: unitType ?? this.unitType,
      storeName: storeName ?? this.storeName,
      storeAddress: storeAddress ?? this.storeAddress,
      categoryName: categoryName ?? this.categoryName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      terms: terms ?? this.terms,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      isActive: isActive ?? this.isActive,
    );
  }
}
