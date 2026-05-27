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
  String selectedSort = 'Terbaru';

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
    final filtered = promos.where((promo) {
      final keyword = searchKeyword.toLowerCase();
      final searchMatches = searchKeyword.isEmpty ||
          promo.productName.toLowerCase().contains(keyword) ||
          promo.brand.toLowerCase().contains(keyword) ||
          promo.storeName.toLowerCase().contains(keyword);
      final categoryMatches =
          selectedCategory == 'Semua' || promo.categoryName == selectedCategory;
      final storeMatches =
          selectedStore == 'Semua' || promo.storeName == selectedStore;
      return searchMatches && categoryMatches && storeMatches;
    }).toList();

    switch (selectedSort) {
      case 'Diskon terbesar':
        filtered.sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
        break;
      case 'Harga termurah':
        filtered.sort((a, b) => a.promoPrice.compareTo(b.promoPrice));
        break;
      case 'Hampir berakhir':
        filtered.sort((a, b) => a.endDate.compareTo(b.endDate));
        break;
      default:
        filtered.sort((a, b) => b.startDate.compareTo(a.startDate));
        break;
    }
    return filtered;
  }

  List<PromoModel> get favoritePromos =>
      promos.where((promo) => promo.isFavorite).toList()
        ..sort((a, b) => a.endDate.compareTo(b.endDate));

  List<PromoModel> get endingSoonPromos => promos
      .where(
        (promo) =>
            !promo.isExpired &&
            promo.endDate.difference(DateTime.now()).inHours <= 48,
      )
      .toList()
    ..sort((a, b) => a.endDate.compareTo(b.endDate));

  List<PromoModel> get popularPromos {
    final list = [...promos];
    list.sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
    return list.take(5).toList();
  }

  void updateSearch(String keyword) {
    searchKeyword = keyword;
    notifyListeners();
  }

  void updateSelectedCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }

  void updateSelectedStore(String store) {
    selectedStore = store;
    notifyListeners();
  }

  void updateSort(String sort) {
    selectedSort = sort;
    notifyListeners();
  }

  void resetFilters() {
    searchKeyword = '';
    selectedCategory = 'Semua';
    selectedStore = 'Semua';
    selectedSort = 'Terbaru';
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

  Future<void> createPromo(PromoModel promo) async {
    final maxId = promos.fold<int>(
      0,
      (previous, item) => item.id > previous ? item.id : previous,
    );
    final localPromo = promo.copyWith(id: promo.id <= 0 ? maxId + 1 : promo.id);
    await _promoService.createPromo(localPromo);
    promos = [...promos, localPromo];
    notifyListeners();
  }

  Future<void> updateExistingPromo(PromoModel promo) async {
    await _promoService.updatePromo(promo);
    promos = promos.map((item) => item.id == promo.id ? promo : item).toList();
    notifyListeners();
  }

  Future<void> deletePromo(int promoId) async {
    await _promoService.deletePromo(promoId);
    promos = promos.where((item) => item.id != promoId).toList();
    reminders = reminders.where((item) => item.promoId != promoId).toList();
    notifyListeners();
  }

  List<PromoModel> promosByStore(String storeName) {
    final items = promos.where((promo) => promo.storeName == storeName).toList();
    items.sort((a, b) => a.endDate.compareTo(b.endDate));
    return items;
  }

  Future<void> createStore(StoreModel store) async {
    final maxId = stores.fold<int>(
      0,
      (previous, item) => item.id > previous ? item.id : previous,
    );
    final localStore = StoreModel(
      id: store.id <= 0 ? maxId + 1 : store.id,
      name: store.name,
      address: store.address,
      city: store.city,
      googleMapsUrl: store.googleMapsUrl,
      openingHours: store.openingHours,
      activePromoCount: store.activePromoCount,
    );
    await _storeService.createStore(localStore);
    stores = [...stores, localStore];
    notifyListeners();
  }

  Future<void> updateStore(StoreModel store) async {
    await _storeService.updateStore(store);
    stores = stores.map((item) => item.id == store.id ? store : item).toList();
    notifyListeners();
  }

  Future<void> deleteStore(int storeId) async {
    await _storeService.deleteStore(storeId);
    final target = stores.firstWhere((item) => item.id == storeId);
    stores = stores.where((item) => item.id != storeId).toList();
    promos = promos.where((item) => item.storeName != target.name).toList();
    notifyListeners();
  }

  Future<void> createCategory(CategoryModel category) async {
    final existingMax = categories.fold<int>(
      0,
      (previous, item) => item.id > previous ? item.id : previous,
    );
    final localCategory = CategoryModel(
      id: category.id <= 0 ? existingMax + 1 : category.id,
      name: category.name,
      icon: category.icon,
    );
    await _categoryService.createCategory(localCategory);
    categories = [...categories, localCategory];
    notifyListeners();
  }

  Future<void> updateCategory(CategoryModel category) async {
    await _categoryService.updateCategory(category);
    categories =
        categories.map((item) => item.id == category.id ? category : item).toList();
    notifyListeners();
  }

  Future<void> deleteCategory(int categoryId) async {
    await _categoryService.deleteCategory(categoryId);
    final target = categories.firstWhere((item) => item.id == categoryId);
    categories = categories.where((item) => item.id != categoryId).toList();
    promos = promos
        .map((item) => item.categoryName == target.name
            ? item.copyWith(categoryName: 'Lainnya')
            : item)
        .toList();
    notifyListeners();
  }
}
