import 'package:flutter_test/flutter_test.dart';
import 'package:promohunter/models/category_model.dart';
import 'package:promohunter/models/promo_model.dart';
import 'package:promohunter/models/store_model.dart';
import 'package:promohunter/providers/promo_provider.dart';
import 'package:promohunter/services/category_service.dart';
import 'package:promohunter/services/promo_service.dart';
import 'package:promohunter/services/store_service.dart';

void main() {
  group('PromoProvider category filtering', () {
    late PromoProvider provider;

    setUp(() {
      provider = PromoProvider(
        promoService: PromoService(),
        categoryService: CategoryService(),
        storeService: StoreService(),
      );

      final now = DateTime.now();
      provider.categories = const [
        CategoryModel(id: 1, name: 'Semua', icon: 'all'),
        CategoryModel(id: 2, name: 'Susu', icon: 'milk'),
        CategoryModel(id: 3, name: 'Snack', icon: 'snack'),
      ];
      provider.stores = const [
        StoreModel(
          id: 1,
          name: 'Semua',
          address: '',
          city: '',
          googleMapsUrl: '',
          openingHours: '',
        ),
        StoreModel(
          id: 2,
          name: 'Alfamart',
          address: 'Alamat',
          city: 'Kota',
          googleMapsUrl: 'https://maps.google.com',
          openingHours: '24 jam',
        ),
      ];
      provider.promos = [
        PromoModel(
          id: 1,
          productName: 'Susu UHT Cokelat',
          brand: 'Milko',
          imageUrl: '',
          normalPrice: 20000,
          promoPrice: 15000,
          unitSize: 1,
          unitType: 'liter',
          storeName: 'Alfamart',
          storeAddress: 'Alamat',
          categoryName: 'Susu',
          startDate: now.subtract(const Duration(days: 1)),
          endDate: now.add(const Duration(days: 2)),
          terms: '',
        ),
        PromoModel(
          id: 2,
          productName: 'Keripik Kentang',
          brand: 'Crunchy',
          imageUrl: '',
          normalPrice: 18000,
          promoPrice: 12000,
          unitSize: 1,
          unitType: 'pack',
          storeName: 'Alfamart',
          storeAddress: 'Alamat',
          categoryName: 'Snack',
          startDate: now.subtract(const Duration(days: 1)),
          endDate: now.add(const Duration(days: 2)),
          terms: '',
        ),
      ];
    });

    test('Semua menampilkan semua promo aktif', () {
      provider.updateSelectedCategory('Semua');

      expect(provider.filteredPromos, hasLength(2));
    });

    test('Kategori tertentu menampilkan promo yang sesuai', () {
      provider.updateSelectedCategory(' susu ');

      expect(provider.filteredPromos, hasLength(1));
      expect(provider.filteredPromos.single.categoryName, 'Susu');
    });
  });
}
