import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/category_model.dart';
import '../models/promo_model.dart';
import '../models/reminder_model.dart';
import '../models/store_model.dart';
import '../services/category_service.dart';
import '../services/location_service.dart';
import '../services/n8n_promo_import_service.dart';
import '../services/notification_service.dart';
import '../services/promo_service.dart';
import '../services/store_service.dart';

class PromoProvider extends ChangeNotifier {
  PromoProvider({
    required PromoService promoService,
    required CategoryService categoryService,
    required StoreService storeService,
    LocationService locationService = const LocationService(),
  })  : _promoService = promoService,
        _categoryService = categoryService,
        _storeService = storeService,
        _locationService = locationService;

  final PromoService _promoService;
  final CategoryService _categoryService;
  final StoreService _storeService;
  final LocationService _locationService;
  final N8nPromoImportService _n8nPromoImportService = N8nPromoImportService();
  static const _recentlyViewedPromoIdsKey = 'promo_recently_viewed_ids';

  bool isLoading = false;
  bool isSyncingN8n = false;
  bool isLoadingLocation = false;
  String? errorMessage;
  String? syncMessage;
  String? locationMessage;
  List<PromoModel> promos = [];
  List<CategoryModel> categories = [];
  List<StoreModel> stores = [];
  List<ReminderModel> reminders = [];
  UserLocation? userLocation;
  List<int> recentlyViewedPromoIds = [];
  String searchKeyword = '';
  String selectedCategory = 'Semua';
  String selectedStore = 'Semua';
  String selectedSort = 'Terbaru';

  Future<void> bootstrap() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      promos = await _promoService.getPromos();
      await _restoreRecentlyViewedPromos();
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
      await refreshUserLocation(makeNearestDefault: true, notify: false);
    } catch (_) {
      errorMessage =
          'Gagal memuat katalog promo. Periksa koneksi lalu coba lagi.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  bool get hasUserLocation => userLocation != null;

  List<StoreModel> get sortedStores {
    final visibleStores = stores
        .where((store) => store.id != 0)
        .map(_storeWithActivePromoCount)
        .where((store) => store.activePromoCount > 0)
        .toList();
    if (userLocation == null) return visibleStores;
    visibleStores.sort((a, b) {
      return distanceToStore(a).compareTo(distanceToStore(b));
    });
    return visibleStores;
  }

  List<StoreModel> get allStoresWithPromoCounts {
    return stores
        .where((store) => store.id != 0)
        .map(_storeWithActivePromoCount)
        .toList();
  }

  StoreModel? get nearestStoreWithActivePromos {
    if (userLocation == null) return null;
    final candidates = allStoresWithPromoCounts
        .where(
          (store) =>
              store.activePromoCount > 0 &&
              store.latitude != null &&
              store.longitude != null,
        )
        .toList();
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => distanceToStore(a).compareTo(distanceToStore(b)));
    return candidates.first;
  }

  StoreModel _storeWithActivePromoCount(StoreModel store) {
    return store.copyWith(activePromoCount: promosByStore(store.name).length);
  }

  List<PromoModel> get filteredPromos {
    final filtered = promos.where((promo) {
      final keyword = _normalizeLabel(searchKeyword);
      final searchMatches = searchKeyword.isEmpty ||
          _normalizeLabel(promo.productName).contains(keyword) ||
          _normalizeLabel(promo.brand).contains(keyword) ||
          _normalizeLabel(promo.storeName).contains(keyword);
      final categoryMatches = _isAllSelection(selectedCategory) ||
          _normalizeLabel(promo.categoryName) ==
              _normalizeLabel(selectedCategory);
      final storeMatches = _isAllSelection(selectedStore) ||
          _normalizeLabel(promo.storeName) == _normalizeLabel(selectedStore);
      return !promo.isExpired &&
          searchMatches &&
          categoryMatches &&
          storeMatches;
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
      case 'Terdekat':
        filtered
            .sort((a, b) => distanceToPromo(a).compareTo(distanceToPromo(b)));
        break;
      case 'Toko A-Z':
        filtered.sort((a, b) => a.storeName.compareTo(b.storeName));
        break;
      default:
        filtered.sort((a, b) => b.startDate.compareTo(a.startDate));
        break;
    }
    return filtered;
  }

  double distanceToStore(StoreModel store) {
    final location = userLocation;
    final latitude = store.latitude;
    final longitude = store.longitude;
    if (location == null || latitude == null || longitude == null) {
      return double.infinity;
    }
    return _haversineDistanceKm(
      location.latitude,
      location.longitude,
      latitude,
      longitude,
    );
  }

  double distanceToPromo(PromoModel promo) {
    final location = userLocation;
    final matchingStore = _storeForPromo(promo);
    final latitude = promo.storeLatitude ?? matchingStore?.latitude;
    final longitude = promo.storeLongitude ?? matchingStore?.longitude;
    if (location == null || latitude == null || longitude == null) {
      return double.infinity;
    }
    return _haversineDistanceKm(
      location.latitude,
      location.longitude,
      latitude,
      longitude,
    );
  }

  StoreModel? _storeForPromo(PromoModel promo) {
    for (final store in stores) {
      if (store.name == promo.storeName) return store;
    }
    return null;
  }

  double _haversineDistanceKm(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(endLatitude - startLatitude);
    final dLon = _degreesToRadians(endLongitude - startLongitude);
    final lat1 = _degreesToRadians(startLatitude);
    final lat2 = _degreesToRadians(endLatitude);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) => degrees * math.pi / 180;

  Future<void> refreshUserLocation({
    bool makeNearestDefault = false,
    bool notify = true,
  }) async {
    isLoadingLocation = true;
    locationMessage = null;
    if (notify) notifyListeners();

    try {
      userLocation = await _locationService.getCurrentLocation();
      if (makeNearestDefault && selectedSort == 'Terbaru') {
        selectedSort = 'Terdekat';
      }
      final nearestStore = nearestStoreWithActivePromos;
      if (makeNearestDefault &&
          nearestStore != null &&
          selectedStore == 'Semua') {
        selectedStore = nearestStore.name;
      }
      locationMessage = nearestStore == null
          ? 'Promo terdekat diurutkan dari lokasi kamu.'
          : 'Promo disesuaikan ke toko terdekat: ${nearestStore.name}.';
    } on LocationServiceException catch (error) {
      locationMessage = error.message;
    } catch (_) {
      locationMessage =
          'Lokasi belum bisa dibaca. Promo ditampilkan dengan urutan biasa.';
    } finally {
      isLoadingLocation = false;
      if (notify) notifyListeners();
    }
  }

  List<PromoModel> get favoritePromos =>
      promos.where((promo) => promo.isFavorite && !promo.isExpired).toList()
        ..sort((a, b) => a.endDate.compareTo(b.endDate));

  List<PromoModel> get endingSoonPromos => promos
      .where(
        (promo) => promo.isEndingSoon,
      )
      .toList()
    ..sort((a, b) => a.endDate.compareTo(b.endDate));

  List<PromoModel> get popularPromos {
    final list = promos.where((promo) => !promo.isExpired).toList();
    list.sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
    return list.take(5).toList();
  }

  List<PromoModel> get recentlyViewedPromos {
    final availablePromos = {
      for (final promo in promos) promo.id: promo,
    };
    return recentlyViewedPromoIds
        .map((id) => availablePromos[id])
        .whereType<PromoModel>()
        .toList();
  }

  List<PromoModel> get recommendedPromos {
    final recentCategories = recentlyViewedPromos
        .map((promo) => promo.categoryName)
        .where((category) => category.trim().isNotEmpty)
        .toSet();
    final favoriteCategories = favoritePromos
        .map((promo) => promo.categoryName)
        .where((category) => category.trim().isNotEmpty)
        .toSet();
    final preferredCategories = {...recentCategories, ...favoriteCategories};

    final candidates = promos
        .where(
          (promo) =>
              !promo.isExpired &&
              !recentlyViewedPromoIds.contains(promo.id) &&
              preferredCategories.contains(promo.categoryName),
        )
        .toList()
      ..sort((a, b) {
        final discountCompare = b.discountPercent.compareTo(a.discountPercent);
        if (discountCompare != 0) return discountCompare;
        return a.endDate.compareTo(b.endDate);
      });

    if (candidates.isNotEmpty) return candidates.take(5).toList();

    return popularPromos
        .where((promo) => !recentlyViewedPromoIds.contains(promo.id))
        .take(5)
        .toList();
  }

  void updateSearch(String keyword) {
    searchKeyword = keyword;
    notifyListeners();
  }

  void updateSelectedCategory(String category) {
    selectedCategory = category.trim().isEmpty ? 'Semua' : category.trim();
    notifyListeners();
  }

  void updateSelectedStore(String store) {
    selectedStore = store.trim().isEmpty ? 'Semua' : store.trim();
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

  Future<void> markAsViewed(PromoModel promo) async {
    recentlyViewedPromoIds = [
      promo.id,
      ...recentlyViewedPromoIds.where((id) => id != promo.id),
    ].take(6).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _recentlyViewedPromoIdsKey,
      recentlyViewedPromoIds.map((id) => id.toString()).toList(),
    );
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
    final savedPromo = await _promoService.createPromo(promo);
    promos = [...promos, savedPromo];
    notifyListeners();
  }

  Future<int> syncPromosFromN8n({
    PromoImportSource source = PromoImportSource.webScrape,
  }) async {
    isSyncingN8n = true;
    syncMessage = null;
    notifyListeners();

    try {
      final result = await _n8nPromoImportService.importPromos(source: source);
      if (result.isDirectSupabaseInsert) {
        await bootstrap();
        syncMessage = result.insertedCount == 0
            ? result.message ??
                'Pipedream selesai sync ${source.label}, belum ada data baru.'
            : 'Pipedream berhasil menyimpan ${result.insertedCount} promo dari ${source.label}.';
        return result.insertedCount;
      }

      var insertedCount = 0;

      for (final promo in result.importedPromos) {
        if (_hasSimilarPromo(promo)) continue;
        await createPromo(promo);
        insertedCount++;
      }

      await bootstrap();
      syncMessage = insertedCount == 0
          ? result.message ??
              'Pipedream berhasil mengecek ${source.label}, belum ada promo baru.'
          : '$insertedCount promo baru berhasil diimpor dari ${source.label}.';
      return insertedCount;
    } on N8nPromoImportException catch (error) {
      syncMessage = error.message;
      rethrow;
    } on PromoPersistenceException catch (error) {
      syncMessage = error.message;
      rethrow;
    } catch (_) {
      syncMessage =
          'Gagal sinkron promo dari ${source.label}. Pastikan workflow Pipedream aktif dan coba lagi.';
      rethrow;
    } finally {
      isSyncingN8n = false;
      notifyListeners();
    }
  }

  Future<int> syncPromosFromNotion() {
    return syncPromosFromN8n(source: PromoImportSource.notion);
  }

  bool _hasSimilarPromo(PromoModel incoming) {
    return promos.any((promo) {
      final sameProduct = promo.productName.trim().toLowerCase() ==
          incoming.productName.trim().toLowerCase();
      final sameStore = promo.storeName.trim().toLowerCase() ==
          incoming.storeName.trim().toLowerCase();
      final sameEndDate = promo.endDate.year == incoming.endDate.year &&
          promo.endDate.month == incoming.endDate.month &&
          promo.endDate.day == incoming.endDate.day;
      final sameSource = incoming.sourceUrl.isNotEmpty &&
          promo.sourceUrl.trim().toLowerCase() ==
              incoming.sourceUrl.trim().toLowerCase();
      return sameProduct && (sameSource || (sameStore && sameEndDate));
    });
  }

  Future<void> updateExistingPromo(PromoModel promo) async {
    await _promoService.updatePromo(promo);
    promos = promos.map((item) => item.id == promo.id ? promo : item).toList();
    notifyListeners();
  }

  Future<void> deletePromo(int promoId) async {
    await _promoService.deletePromo(promoId);
    promos = promos.where((item) => item.id != promoId).toList();
    recentlyViewedPromoIds =
        recentlyViewedPromoIds.where((id) => id != promoId).toList();
    reminders = reminders.where((item) => item.promoId != promoId).toList();
    notifyListeners();
  }

  Future<void> _restoreRecentlyViewedPromos() async {
    final prefs = await SharedPreferences.getInstance();
    recentlyViewedPromoIds =
        (prefs.getStringList(_recentlyViewedPromoIdsKey) ?? const <String>[])
            .map((value) => int.tryParse(value))
            .whereType<int>()
            .toList();
  }

  List<PromoModel> promosByStore(String storeName) {
    final items = promos
        .where((promo) => promo.storeName == storeName && !promo.isExpired)
        .toList();
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
      latitude: store.latitude,
      longitude: store.longitude,
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
    if (_normalizeLabel(selectedStore) == _normalizeLabel(target.name)) {
      selectedStore = 'Semua';
    }
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
    categories = categories
        .map((item) => item.id == category.id ? category : item)
        .toList();
    notifyListeners();
  }

  Future<void> deleteCategory(int categoryId) async {
    await _categoryService.deleteCategory(categoryId);
    final target = categories.firstWhere((item) => item.id == categoryId);
    categories = categories.where((item) => item.id != categoryId).toList();
    if (_normalizeLabel(selectedCategory) == _normalizeLabel(target.name)) {
      selectedCategory = 'Semua';
    }
    promos = promos
        .map((item) => item.categoryName == target.name
            ? item.copyWith(categoryName: 'Lainnya')
            : item)
        .toList();
    notifyListeners();
  }

  bool _isAllSelection(String value) {
    return _normalizeLabel(value) == 'semua';
  }

  String _normalizeLabel(String value) {
    return value.trim().toLowerCase();
  }
}
