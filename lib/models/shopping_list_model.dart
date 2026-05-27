class ShoppingListModel {
  const ShoppingListModel({
    required this.promoId,
    required this.productName,
    required this.storeName,
    required this.price,
    this.quantity = 1,
    this.note = '',
    this.isPurchased = false,
  });

  final int promoId;
  final String productName;
  final String storeName;
  final double price;
  final int quantity;
  final String note;
  final bool isPurchased;

  double get totalPrice => price * quantity;

  ShoppingListModel copyWith({
    int? quantity,
    String? note,
    bool? isPurchased,
  }) {
    return ShoppingListModel(
      promoId: promoId,
      productName: productName,
      storeName: storeName,
      price: price,
      quantity: quantity ?? this.quantity,
      note: note ?? this.note,
      isPurchased: isPurchased ?? this.isPurchased,
    );
  }
}

