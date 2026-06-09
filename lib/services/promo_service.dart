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
            .select('*, stores(name,address), categories(name)')
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
        storeName: 'Indomaret Sudirman',
        storeAddress: 'Jl. Sudirman No. 8',
        categoryName: 'Minyak',
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
        storeName: 'Super Indo Melati',
        storeAddress: 'Jl. Melati No. 22',
        categoryName: 'Beras',
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
        storeName: 'Alfamart Merdeka',
        storeAddress: 'Jl. Merdeka No. 15',
        categoryName: 'Susu',
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
        storeName: 'Indomaret Sudirman',
        storeAddress: 'Jl. Sudirman No. 8',
        categoryName: 'Deterjen',
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
        storeName: 'Super Indo Melati',
        storeAddress: 'Jl. Melati No. 22',
        categoryName: 'Bumbu',
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
        storeName: 'Super Indo Melati',
        storeAddress: 'Jl. Melati No. 22',
        categoryName: 'Frozen Food',
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
        storeName: 'Super Indo Melati',
        storeAddress: 'Jl. Melati No. 22',
        categoryName: 'Snack',
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
        await client.from('promos').insert(promo.toInsertMap());
      } catch (_) {
        // Keep optimistic local support for MVP fallback.
      }
    }
    return promo;
  }

  Future<PromoModel> updatePromo(PromoModel promo) async {
    final client = _supabaseService.clientOrNull;
    if (client != null) {
      try {
        await client.from('promos').update(promo.toInsertMap()).eq('id', promo.id);
      } catch (_) {
        // Keep optimistic local support for MVP fallback.
      }
    }
    return promo;
  }

  Future<void> deletePromo(int promoId) async {
    final client = _supabaseService.clientOrNull;
    if (client != null) {
      try {
        await client.from('promos').delete().eq('id', promoId);
      } catch (_) {
        // Keep optimistic local support for MVP fallback.
      }
    }
  }
}
