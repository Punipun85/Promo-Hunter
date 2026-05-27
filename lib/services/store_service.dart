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
