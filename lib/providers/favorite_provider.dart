import 'package:flutter/foundation.dart';

import '../models/promo_model.dart';
import '../services/favorite_service.dart';

class FavoriteProvider extends ChangeNotifier {
  FavoriteProvider(this._service);

  final FavoriteService _service;

  Set<int> favoriteIds = <int>{};
  bool isLoading = false;

  bool isFavorite(int promoId) => favoriteIds.contains(promoId);

  Future<void> bootstrapForUser(String userId) async {
    isLoading = true;
    notifyListeners();
    favoriteIds = await _service.getUserFavorites(userId);
    isLoading = false;
    notifyListeners();
  }

  Future<void> toggleFavorite(String userId, PromoModel promo) async {
    if (favoriteIds.contains(promo.id)) {
      await _service.removeFavorite(userId, promo.id);
      favoriteIds = {...favoriteIds}..remove(promo.id);
    } else {
      await _service.addFavorite(userId, promo.id);
      favoriteIds = {...favoriteIds, promo.id};
    }
    notifyListeners();
  }

  void clear() {
    favoriteIds = <int>{};
    notifyListeners();
  }
}
