import 'package:flutter/foundation.dart';

import '../models/promo_model.dart';
import '../models/shopping_list_model.dart';
import '../services/shopping_list_service.dart';

class ShoppingListProvider extends ChangeNotifier {
  ShoppingListProvider(this._service);

  final ShoppingListService _service;

  List<ShoppingListModel> items = [];
  bool isLoading = false;
  String? _currentUserId;

  double get totalEstimatedPrice =>
      items.fold(0, (total, item) => total + item.totalPrice);

  Future<void> bootstrap([String? userId]) async {
    _currentUserId = userId ?? _currentUserId;
    isLoading = true;
    notifyListeners();
    items = await _service.getItems(_currentUserId);
    isLoading = false;
    notifyListeners();
  }

  Future<void> addPromo(PromoModel promo, {int quantity = 1}) async {
    await _service.addPromo(_currentUserId, promo, quantity: quantity);
    items = await _service.getItems(_currentUserId);
    notifyListeners();
  }

  Future<void> updateQuantity(int promoId, int quantity) async {
    if (quantity < 1) return;
    await _service.updateItem(_currentUserId, promoId, quantity: quantity);
    items = await _service.getItems(_currentUserId);
    notifyListeners();
  }

  Future<void> togglePurchased(ShoppingListModel item) async {
    await _service.updateItem(
      _currentUserId,
      item.promoId,
      isPurchased: !item.isPurchased,
    );
    items = await _service.getItems(_currentUserId);
    notifyListeners();
  }

  Future<void> removeItem(int promoId) async {
    await _service.removeItem(_currentUserId, promoId);
    items = await _service.getItems(_currentUserId);
    notifyListeners();
  }

  void clear() {
    _currentUserId = null;
    items = <ShoppingListModel>[];
    notifyListeners();
  }
}
