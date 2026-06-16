import '../models/store_model.dart';
import 'supabase_service.dart';

class StoreService {
  StoreService([SupabaseService? supabaseService])
      : _supabaseService = supabaseService ?? const SupabaseService();

  final SupabaseService _supabaseService;
  final List<StoreModel> _fallbackStores = const [
    StoreModel(
      id: 1,
      name: 'Indomaret Sudirman',
      address: 'Jl. Sudirman No. 8',
      city: 'Jakarta',
      googleMapsUrl: 'https://maps.google.com',
      openingHours: '07.00 - 22.00',
      latitude: -6.2000,
      longitude: 106.8167,
      activePromoCount: 6,
    ),
    StoreModel(
      id: 2,
      name: 'Alfamart Merdeka',
      address: 'Jl. Merdeka No. 15',
      city: 'Bandung',
      googleMapsUrl: 'https://maps.google.com',
      openingHours: '24 jam',
      latitude: -6.2091,
      longitude: 106.8459,
      activePromoCount: 4,
    ),
    StoreModel(
      id: 3,
      name: 'Super Indo Melati',
      address: 'Jl. Melati No. 22',
      city: 'Surabaya',
      googleMapsUrl: 'https://maps.google.com',
      openingHours: '08.00 - 21.00',
      latitude: -6.2245,
      longitude: 106.8098,
      activePromoCount: 5,
    ),
    StoreModel(
      id: 4,
      name: 'Hypermart',
      address: 'Mall dan pusat belanja terdekat',
      city: 'Indonesia',
      googleMapsUrl: 'https://maps.google.com/?q=Hypermart',
      openingHours: '10.00 - 22.00',
      latitude: -6.1767,
      longitude: 106.7906,
      activePromoCount: 0,
    ),
    StoreModel(
      id: 5,
      name: 'Transmart',
      address: 'Gerai Transmart terdekat',
      city: 'Indonesia',
      googleMapsUrl: 'https://maps.google.com/?q=Transmart',
      openingHours: '10.00 - 22.00',
      latitude: -6.2431,
      longitude: 106.8448,
      activePromoCount: 0,
    ),
    StoreModel(
      id: 6,
      name: 'Lotte Mart',
      address: 'Gerai Lotte Mart terdekat',
      city: 'Indonesia',
      googleMapsUrl: 'https://maps.google.com/?q=Lotte+Mart',
      openingHours: '09.00 - 22.00',
      latitude: -6.2271,
      longitude: 106.8331,
      activePromoCount: 0,
    ),
    StoreModel(
      id: 7,
      name: 'Farmers Market',
      address: 'Gerai Farmers Market terdekat',
      city: 'Indonesia',
      googleMapsUrl: 'https://maps.google.com/?q=Farmers+Market',
      openingHours: '08.00 - 22.00',
      latitude: -6.2440,
      longitude: 106.7990,
      activePromoCount: 0,
    ),
    StoreModel(
      id: 8,
      name: 'Ranch Market',
      address: 'Gerai Ranch Market terdekat',
      city: 'Indonesia',
      googleMapsUrl: 'https://maps.google.com/?q=Ranch+Market',
      openingHours: '08.00 - 22.00',
      latitude: -6.2088,
      longitude: 106.8200,
      activePromoCount: 0,
    ),
    StoreModel(
      id: 9,
      name: 'Grand Lucky',
      address: 'Gerai Grand Lucky terdekat',
      city: 'Indonesia',
      googleMapsUrl: 'https://maps.google.com/?q=Grand+Lucky+Superstore',
      openingHours: '08.00 - 22.00',
      latitude: -6.2364,
      longitude: 106.7815,
      activePromoCount: 0,
    ),
    StoreModel(
      id: 10,
      name: 'Hero Supermarket',
      address: 'Gerai Hero Supermarket terdekat',
      city: 'Indonesia',
      googleMapsUrl: 'https://maps.google.com/?q=Hero+Supermarket',
      openingHours: '08.00 - 22.00',
      latitude: -6.2297,
      longitude: 106.8140,
      activePromoCount: 0,
    ),
  ];

  Future<List<StoreModel>> getStores() async {
    final client = _supabaseService.clientOrNull;
    if (client != null) {
      try {
        final response = await client.from('stores').select().order('name');
        return (response as List)
            .map((item) => StoreModel.fromMap(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        // Fallback to local demo data below.
      }
    }

    return _fallbackStores.map((item) => item).toList();
  }

  Future<StoreModel> createStore(StoreModel store) async {
    final client = _supabaseService.clientOrNull;
    if (client != null) {
      try {
        await client.from('stores').insert({
          'name': store.name,
          'address': store.address,
          'city': store.city,
          'google_maps_url': store.googleMapsUrl,
          'opening_hours': store.openingHours,
          'latitude': store.latitude,
          'longitude': store.longitude,
        });
      } catch (_) {}
    }
    return store;
  }

  Future<StoreModel> updateStore(StoreModel store) async {
    final client = _supabaseService.clientOrNull;
    if (client != null) {
      try {
        await client.from('stores').update({
          'name': store.name,
          'address': store.address,
          'city': store.city,
          'google_maps_url': store.googleMapsUrl,
          'opening_hours': store.openingHours,
          'latitude': store.latitude,
          'longitude': store.longitude,
        }).eq('id', store.id);
      } catch (_) {}
    }
    return store;
  }

  Future<void> deleteStore(int storeId) async {
    final client = _supabaseService.clientOrNull;
    if (client != null) {
      try {
        await client.from('stores').delete().eq('id', storeId);
      } catch (_) {}
    }
  }
}
