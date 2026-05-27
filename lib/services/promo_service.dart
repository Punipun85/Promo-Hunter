import '../models/promo_model.dart';

class PromoService {
  Future<List<PromoModel>> getPromos() async {
    final now = DateTime.now();
    return [
      PromoModel(
        id: 1,
        productName: 'Minyak Goreng Hemat 2L',
        brand: 'SunFresh',
        imageUrl: 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=1200',
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
        imageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=1200',
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
        imageUrl: 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=1200',
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
        imageUrl: 'https://images.unsplash.com/photo-1563453392212-326f5e854473?w=1200',
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
    ];
  }
}

