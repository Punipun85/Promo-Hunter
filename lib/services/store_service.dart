import '../models/store_model.dart';

class StoreService {
  Future<List<StoreModel>> getStores() async {
    return const [
      StoreModel(
        id: 1,
        name: 'Indomaret Sudirman',
        address: 'Jl. Sudirman No. 8',
        city: 'Jakarta',
        googleMapsUrl: 'https://maps.google.com',
        openingHours: '07.00 - 22.00',
        activePromoCount: 6,
      ),
      StoreModel(
        id: 2,
        name: 'Alfamart Merdeka',
        address: 'Jl. Merdeka No. 15',
        city: 'Bandung',
        googleMapsUrl: 'https://maps.google.com',
        openingHours: '24 jam',
        activePromoCount: 4,
      ),
      StoreModel(
        id: 3,
        name: 'Super Indo Melati',
        address: 'Jl. Melati No. 22',
        city: 'Surabaya',
        googleMapsUrl: 'https://maps.google.com',
        openingHours: '08.00 - 21.00',
        activePromoCount: 5,
      ),
    ];
  }
}

