import '../models/promo_model.dart';
import 'supabase_service.dart';

class PromoService {
  PromoService([SupabaseService? supabaseService])
      : _supabaseService = supabaseService ?? const SupabaseService();

  final SupabaseService _supabaseService;

  Future<List<PromoModel>> getPromos() async {
    final client = _supabaseService.clientOrNull;
    if (client != null) {
      try {
        final response = await client
            .from('promos')
            .select(
                '*, stores(name,address,latitude,longitude), categories(name)')
            .eq('is_active', true)
            .order('end_date');
        return (response as List)
            .map((item) => PromoModel.fromMap(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        // Fallback to local demo data below.
      }
    }

    final now = DateTime.now();
    return [
      PromoModel(
        id: 1,
        productName: 'Minyak Goreng Hemat 2L',
        brand: 'SunFresh',
        imageUrl:
            'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=1200',
        normalPrice: 32000,
        promoPrice: 28900,
        unitSize: 2,
        unitType: 'liter',
        storeName: 'Indomaret Slamet Riyadi Solo',
        storeAddress: 'Jl. Slamet Riyadi No. 275, Sriwedari',
        categoryName: 'Minyak',
        storeLatitude: -7.56655,
        storeLongitude: 110.80890,
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 2)),
        terms: 'Berlaku selama stok tersedia.',
      ),
      PromoModel(
        id: 2,
        productName: 'Beras Premium 5kg',
        brand: 'Makmur',
        imageUrl:
            'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=1200',
        normalPrice: 79000,
        promoPrice: 69900,
        unitSize: 5,
        unitType: 'kg',
        storeName: 'Super Indo Solo Grand Mall',
        storeAddress: 'Jl. Brigjen Slamet Riyadi No. 273, Penumping',
        categoryName: 'Beras',
        storeLatitude: -7.56573,
        storeLongitude: 110.80584,
        startDate: now.subtract(const Duration(days: 2)),
        endDate: now.add(const Duration(days: 4)),
        terms: 'Maksimal 2 produk per transaksi.',
      ),
      PromoModel(
        id: 3,
        productName: 'Susu UHT Cokelat 1L',
        brand: 'Milko',
        imageUrl:
            'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=1200',
        normalPrice: 21000,
        promoPrice: 16900,
        unitSize: 1,
        unitType: 'liter',
        storeName: 'Alfamart Laweyan Solo',
        storeAddress: 'Jl. Dr. Rajiman No. 525, Laweyan',
        categoryName: 'Susu',
        storeLatitude: -7.56082,
        storeLongitude: 110.80163,
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(hours: 18)),
        terms: 'Khusus member.',
      ),
      PromoModel(
        id: 4,
        productName: 'Deterjen Cair 800ml',
        brand: 'CleanPro',
        imageUrl:
            'https://images.unsplash.com/photo-1563453392212-326f5e854473?w=1200',
        normalPrice: 24000,
        promoPrice: 19900,
        unitSize: 800,
        unitType: 'ml',
        storeName: 'Indomaret Slamet Riyadi Solo',
        storeAddress: 'Jl. Slamet Riyadi No. 275, Sriwedari',
        categoryName: 'Deterjen',
        storeLatitude: -7.56655,
        storeLongitude: 110.80890,
        startDate: now.subtract(const Duration(days: 3)),
        endDate: now.add(const Duration(days: 5)),
        terms: 'Tidak berlaku digabung voucher lain.',
      ),
      PromoModel(
        id: 5,
        productName: 'Saus Cabe Botol 535ml',
        brand: 'Dua Belibis',
        imageUrl:
            'https://images.unsplash.com/photo-1604908554027-783cb79a89ec?w=1200',
        normalPrice: 42990,
        promoPrice: 28900,
        unitSize: 535,
        unitType: 'ml',
        storeName: 'Super Indo Solo Grand Mall',
        storeAddress: 'Jl. Brigjen Slamet Riyadi No. 273, Penumping',
        categoryName: 'Bumbu',
        storeLatitude: -7.56573,
        storeLongitude: 110.80584,
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 2)),
        terms: 'Diskon 30%. Maksimal 4 botol per transaksi.',
        sourceUrl: 'https://www.superindo.co.id/',
      ),
      PromoModel(
        id: 6,
        productName: 'French Fries 1kg',
        brand: '365',
        imageUrl:
            'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=1200',
        normalPrice: 42900,
        promoPrice: 32900,
        unitSize: 1,
        unitType: 'kg',
        storeName: 'Super Indo Solo Grand Mall',
        storeAddress: 'Jl. Brigjen Slamet Riyadi No. 273, Penumping',
        categoryName: 'Frozen Food',
        storeLatitude: -7.56573,
        storeLongitude: 110.80584,
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 2)),
        terms: 'Diskon 20%. Maksimal 4 pack per transaksi.',
        sourceUrl: 'https://www.superindo.co.id/',
      ),
      PromoModel(
        id: 7,
        productName: 'Chiki Balls 200gr',
        brand: 'Chiki',
        imageUrl:
            'https://images.unsplash.com/photo-1621939514649-280e2ee25f60?w=1200',
        normalPrice: 23190,
        promoPrice: 16900,
        unitSize: 200,
        unitType: 'gram',
        storeName: 'Super Indo Solo Grand Mall',
        storeAddress: 'Jl. Brigjen Slamet Riyadi No. 273, Penumping',
        categoryName: 'Snack',
        storeLatitude: -7.56573,
        storeLongitude: 110.80584,
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 2)),
        terms: 'Diskon 25%. Maksimal 4 pack per transaksi.',
        sourceUrl: 'https://www.superindo.co.id/',
      ),
    ];
  }

  Future<PromoModel> createPromo(PromoModel promo) async {
    final client = _supabaseService.clientOrNull;
    if (client != null) {
      try {
        final storeId = await _findOrCreateStoreId(promo);
        final categoryId = await _findOrCreateCategoryId(promo.categoryName);
        final promoId = await _nextTableId('promos');
        await client.from('promos').insert({
          'id': promoId,
          ...promo.toInsertMap(storeId: storeId, categoryId: categoryId),
        });
        return promo.copyWith(id: promoId);
      } catch (error) {
        throw PromoPersistenceException(
          'Promo gagal disimpan ke Supabase: $error',
        );
      }
    }
    return promo;
  }

  Future<PromoModel> updatePromo(PromoModel promo) async {
    final client = _supabaseService.clientOrNull;
    if (client != null) {
      try {
        final storeId = await _findOrCreateStoreId(promo);
        final categoryId = await _findOrCreateCategoryId(promo.categoryName);
        await client
            .from('promos')
            .update(promo.toInsertMap(storeId: storeId, categoryId: categoryId))
            .eq('id', promo.id);
      } catch (error) {
        throw PromoPersistenceException(
          'Promo gagal diperbarui di Supabase: $error',
        );
      }
    }
    return promo;
  }

  Future<void> deletePromo(int promoId) async {
    final client = _supabaseService.clientOrNull;
    if (client != null) {
      try {
        await client.from('promos').delete().eq('id', promoId);
      } catch (error) {
        throw PromoPersistenceException(
          'Promo gagal dihapus dari Supabase: $error',
        );
      }
    }
  }

  Future<int?> _findOrCreateStoreId(PromoModel promo) async {
    final client = _supabaseService.clientOrNull;
    if (client == null || promo.storeName.trim().isEmpty) return null;
    final storeDefaults = _storeDefaultsFor(promo);

    final existing = await client
        .from('stores')
        .select('id,address,city,google_maps_url,opening_hours')
        .eq('name', promo.storeName)
        .limit(1);
    if (existing.isNotEmpty) {
      final existingStore = existing.first as Map;
      final storeId = (existingStore['id'] as num).toInt();
      if (_shouldEnrichStore(existingStore)) {
        await client.from('stores').update(storeDefaults).eq('id', storeId);
      }
      return storeId;
    }

    final inserted = await client
        .from('stores')
        .insert({
          'id': await _nextTableId('stores'),
          'name': promo.storeName,
          ...storeDefaults,
        })
        .select('id')
        .single();
    return (inserted['id'] as num).toInt();
  }

  bool _shouldEnrichStore(Map existingStore) {
    final address = (existingStore['address'] ?? '').toString().trim();
    final mapsUrl = (existingStore['google_maps_url'] ?? '').toString().trim();
    return address.isEmpty ||
        address == 'Sumber promo dari n8n' ||
        mapsUrl.isEmpty;
  }

  Map<String, dynamic> _storeDefaultsFor(PromoModel promo) {
    final rawName = promo.storeName.trim();
    final normalized = rawName.toLowerCase();
    final chainProfiles = <String, ({String address, String hours})>{
      'indomaret': (
        address: 'Gerai Indomaret terdekat',
        hours: '07.00 - 22.00',
      ),
      'klik indomaret': (
        address: 'Layanan online Klik Indomaret',
        hours: '24 jam',
      ),
      'alfamart': (
        address: 'Gerai Alfamart terdekat',
        hours: '24 jam',
      ),
      'alfagift': (
        address: 'Layanan online Alfagift',
        hours: '24 jam',
      ),
      'super indo': (
        address: 'Gerai Super Indo terdekat',
        hours: '08.00 - 22.00',
      ),
      'hypermart': (
        address: 'Gerai Hypermart terdekat',
        hours: '10.00 - 22.00',
      ),
      'transmart': (
        address: 'Gerai Transmart terdekat',
        hours: '10.00 - 22.00',
      ),
      'lotte mart': (
        address: 'Gerai Lotte Mart terdekat',
        hours: '09.00 - 22.00',
      ),
      'farmers market': (
        address: 'Gerai Farmers Market terdekat',
        hours: '08.00 - 22.00',
      ),
      'ranch market': (
        address: 'Gerai Ranch Market terdekat',
        hours: '08.00 - 22.00',
      ),
      'grand lucky': (
        address: 'Gerai Grand Lucky terdekat',
        hours: '08.00 - 22.00',
      ),
      'hero supermarket': (
        address: 'Gerai Hero Supermarket terdekat',
        hours: '08.00 - 22.00',
      ),
    };

    ({String address, String hours})? matchedProfile;
    for (final entry in chainProfiles.entries) {
      if (normalized.contains(entry.key)) {
        matchedProfile = entry.value;
        break;
      }
    }
    final address = promo.storeAddress.trim().isNotEmpty &&
            promo.storeAddress != 'Sumber promo dari n8n'
        ? promo.storeAddress
        : matchedProfile?.address ?? 'Gerai $rawName terdekat';

    return {
      'address': address,
      'city': 'Indonesia',
      'google_maps_url':
          'https://www.openstreetmap.org/search?query=${Uri.encodeComponent(rawName)}',
      'opening_hours': matchedProfile?.hours ?? '08.00 - 22.00',
      'latitude': _defaultLatitudeFor(normalized),
      'longitude': _defaultLongitudeFor(normalized),
    };
  }

  double _defaultLatitudeFor(String normalizedStoreName) {
    if (normalizedStoreName.contains('alfamart')) return -6.2091;
    if (normalizedStoreName.contains('super indo')) return -6.2245;
    if (normalizedStoreName.contains('hypermart')) return -6.1767;
    if (normalizedStoreName.contains('transmart')) return -6.2431;
    if (normalizedStoreName.contains('lotte')) return -6.2271;
    if (normalizedStoreName.contains('farmers')) return -6.2440;
    if (normalizedStoreName.contains('ranch')) return -6.2088;
    if (normalizedStoreName.contains('grand lucky')) return -6.2364;
    if (normalizedStoreName.contains('hero')) return -6.2297;
    return -6.2000;
  }

  double _defaultLongitudeFor(String normalizedStoreName) {
    if (normalizedStoreName.contains('alfamart')) return 106.8459;
    if (normalizedStoreName.contains('super indo')) return 106.8098;
    if (normalizedStoreName.contains('hypermart')) return 106.7906;
    if (normalizedStoreName.contains('transmart')) return 106.8448;
    if (normalizedStoreName.contains('lotte')) return 106.8331;
    if (normalizedStoreName.contains('farmers')) return 106.7990;
    if (normalizedStoreName.contains('ranch')) return 106.8200;
    if (normalizedStoreName.contains('grand lucky')) return 106.7815;
    if (normalizedStoreName.contains('hero')) return 106.8140;
    return 106.8167;
  }

  Future<int?> _findOrCreateCategoryId(String categoryName) async {
    final client = _supabaseService.clientOrNull;
    final normalized = categoryName.trim();
    if (client == null || normalized.isEmpty || normalized == 'Semua') {
      return null;
    }

    final existing = await client
        .from('categories')
        .select('id')
        .eq('name', normalized)
        .limit(1);
    if (existing.isNotEmpty) {
      return ((existing.first as Map)['id'] as num).toInt();
    }

    final inserted = await client
        .from('categories')
        .insert({
          'id': await _nextTableId('categories'),
          'name': normalized,
          'icon': 'category',
        })
        .select('id')
        .single();
    return (inserted['id'] as num).toInt();
  }

  Future<int> _nextTableId(String table) async {
    final client = _supabaseService.clientOrNull;
    if (client == null) return 1;

    final response = await client
        .from(table)
        .select('id')
        .order('id', ascending: false)
        .limit(1);
    final rows = response as List;
    if (rows.isNotEmpty) {
      return (((rows.first as Map)['id']) as num).toInt() + 1;
    }
    return 1;
  }
}

class PromoPersistenceException implements Exception {
  const PromoPersistenceException(this.message);

  final String message;

  @override
  String toString() => message;
}
