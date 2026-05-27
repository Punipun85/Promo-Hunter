import 'package:flutter/foundation.dart';

import '../models/category_model.dart';
import '../models/promo_model.dart';
import '../models/reminder_model.dart';
import '../models/store_model.dart';
import '../services/category_service.dart';
import '../services/notification_service.dart';
import '../services/promo_service.dart';
import '../services/store_service.dart';

class PromoProvider extends ChangeNotifier {
  PromoProvider({
    required PromoService promoService,
    required CategoryService categoryService,
    required StoreService storeService,
  })  : _promoService = promoService,
        _categoryService = categoryService,
        _storeService = storeService;

  final PromoService _promoService;
  final CategoryService _categoryService;
  final StoreService _storeService;

  bool isLoading = false;
  List<PromoModel> promos = [];
  List<CategoryModel> categories = [];
  List<StoreModel> stores = [];
  List<ReminderModel> reminders = [];
  String searchKeyword = '';
  String selectedCategory = 'Semua';
  String selectedStore = 'Semua';

  Future<void> bootstrap() async {
    isLoading = true;
    notifyListeners();
    promos = await _promoService.getPromos();
    categories = await _categoryService.getCategories();
    stores = [
      const StoreModel(
        id: 0,
        name: 'Semua',
        address: '',
        city: '',
        googleMapsUrl: '',
        openingHours: '',
      ),
      ...await _storeService.getStores(),
    ];
    isLoading = false;
    notifyListeners();
  }

  List<PromoModel> get filteredPromos {
    return promos.where((promo) {
      final searchMatches = searchKeyword.isEmpty ||
          promo.productName.toLowerCase().contains(searchKeyword.toLowerCase()) ||
          promo.brand.toLowerCase().contains(searchKeyword.toLowerCase());
      final categoryMatches =
          selectedCategory == 'Semua' || promo.categoryName == selectedCategory;
      final storeMatches =
          selectedStore == 'Semua' || promo.storeName == selectedStore;
      return searchMatches && categoryMatches && storeMatches;
    }).toList();
  }

  List<PromoModel> get favoritePromos =>
      promos.where((promo) => promo.isFavorite).toList();

  List<PromoModel> get endingSoonPromos => promos
      .where((promo) => !promo.isExpired && promo.endDate.difference(DateTime.now()).inHours <= 48)
      .toList();

  void updateSearch(String keyword) {
    searchKeyword = keyword;
    notifyListeners();
  }

  void updateCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }

  void updateStore(String store) {
    selectedStore = store;
    notifyListeners();
  }

  void toggleFavorite(int promoId) {
    promos = promos.map((promo) {
      return promo.id == promoId
          ? promo.copyWith(isFavorite: !promo.isFavorite)
          : promo;
    }).toList();
    notifyListeners();
  }

  Future<String?> addReminder(PromoModel promo, Duration beforeEnd) async {
    final scheduledAt = promo.endDate.subtract(beforeEnd);
    if (promo.isExpired || scheduledAt.isBefore(DateTime.now())) {
      return 'Reminder tidak bisa dibuat karena promo sudah terlalu dekat atau sudah berakhir.';
    }
    if (reminders.any((item) => item.promoId == promo.id)) {
      return 'Reminder sudah dibuat untuk promo ini.';
    }
    reminders = [
      ...reminders,
      ReminderModel(
        promoId: promo.id,
        productName: promo.productName,
        storeName: promo.storeName,
        reminderTime: scheduledAt,
      ),
    ];
    await NotificationService.instance.schedulePromoReminder(
      promoId: promo.id,
      title: promo.productName,
      scheduledAt: scheduledAt,
    );
    notifyListeners();
    return null;
  }

  void removeReminder(int promoId) {
    reminders = reminders.where((item) => item.promoId != promoId).toList();
    notifyListeners();
  }
}

