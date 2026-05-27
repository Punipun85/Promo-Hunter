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
  final bool isFavorite;
  final bool isActive;

  double get discountPercent =>
      ((normalPrice - promoPrice) / normalPrice * 100).clamp(0, 100);

  bool get isExpired => endDate.isBefore(DateTime.now());

  int get remainingDays => endDate.difference(DateTime.now()).inDays;

  double get unitPrice => promoPrice / unitSize;

  PromoModel copyWith({bool? isFavorite}) {
    return PromoModel(
      id: id,
      productName: productName,
      brand: brand,
      imageUrl: imageUrl,
      normalPrice: normalPrice,
      promoPrice: promoPrice,
      unitSize: unitSize,
      unitType: unitType,
      storeName: storeName,
      storeAddress: storeAddress,
      categoryName: categoryName,
      startDate: startDate,
      endDate: endDate,
      terms: terms,
      isFavorite: isFavorite ?? this.isFavorite,
      isActive: isActive,
    );
  }
}

