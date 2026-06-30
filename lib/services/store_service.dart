import '../models/store_model.dart';
import 'supabase_service.dart';

class StoreService {
  StoreService([SupabaseService? supabaseService])
      : _supabaseService = supabaseService ?? const SupabaseService();

  final SupabaseService _supabaseService;
  final List<StoreModel> _fallbackStores = const [
    StoreModel(
      id: 1,
      name: 'Indomaret Slamet Riyadi Solo',
      address: 'Jl. Slamet Riyadi No. 275, Sriwedari',
      city: 'Surakarta',
      googleMapsUrl:
          'https://www.openstreetmap.org/?mlat=-7.56655&mlon=110.80890#map=17/-7.56655/110.80890',
      openingHours: '07.00 - 22.00',
      latitude: -7.56655,
      longitude: 110.80890,
      activePromoCount: 2,
    ),
    StoreModel(
      id: 2,
      name: 'Alfamart Laweyan Solo',
      address: 'Jl. Dr. Rajiman No. 525, Laweyan',
      city: 'Surakarta',
      googleMapsUrl:
          'https://www.openstreetmap.org/?mlat=-7.56082&mlon=110.80163#map=17/-7.56082/110.80163',
      openingHours: '24 jam',
      latitude: -7.56082,
      longitude: 110.80163,
      activePromoCount: 1,
    ),
    StoreModel(
      id: 3,
      name: 'Super Indo Solo Grand Mall',
      address: 'Jl. Brigjen Slamet Riyadi No. 273, Penumping',
      city: 'Surakarta',
      googleMapsUrl:
          'https://www.openstreetmap.org/?mlat=-7.56573&mlon=110.80584#map=17/-7.56573/110.80584',
      openingHours: '08.00 - 21.00',
      latitude: -7.56573,
      longitude: 110.80584,
      activePromoCount: 4,
    ),
    StoreModel(
      id: 4,
      name: 'Hypermart Solo Square',
      address: 'Jl. Slamet Riyadi No. 451-455, Laweyan',
      city: 'Surakarta',
      googleMapsUrl:
          'https://www.openstreetmap.org/?mlat=-7.55920&mlon=110.79480#map=17/-7.55920/110.79480',
      openingHours: '10.00 - 22.00',
      latitude: -7.55920,
      longitude: 110.79480,
      activePromoCount: 0,
    ),
    StoreModel(
      id: 5,
      name: 'Transmart Pabelan',
      address: 'Jl. Ahmad Yani, Pabelan, Kartasura',
      city: 'Sukoharjo',
      googleMapsUrl:
          'https://www.openstreetmap.org/?mlat=-7.55470&mlon=110.76850#map=17/-7.55470/110.76850',
      openingHours: '10.00 - 22.00',
      latitude: -7.55470,
      longitude: 110.76850,
      activePromoCount: 0,
    ),
    StoreModel(
      id: 6,
      name: 'Lotte Mart Solo Baru',
      address: 'Jl. Ir. Soekarno, Solo Baru',
      city: 'Sukoharjo',
      googleMapsUrl:
          'https://www.openstreetmap.org/?mlat=-7.59220&mlon=110.82440#map=17/-7.59220/110.82440',
      openingHours: '09.00 - 22.00',
      latitude: -7.59220,
      longitude: 110.82440,
      activePromoCount: 0,
    ),
    StoreModel(
      id: 7,
      name: 'Farmers Market Solo Paragon',
      address: 'Jl. Yosodipuro No. 133, Mangkubumen',
      city: 'Surakarta',
      googleMapsUrl:
          'https://www.openstreetmap.org/?mlat=-7.55740&mlon=110.81970#map=17/-7.55740/110.81970',
      openingHours: '08.00 - 22.00',
      latitude: -7.55740,
      longitude: 110.81970,
      activePromoCount: 0,
    ),
    StoreModel(
      id: 8,
      name: 'Ranch Market Solo Baru',
      address: 'Jl. Ir. Soekarno, Madegondo',
      city: 'Sukoharjo',
      googleMapsUrl:
          'https://www.openstreetmap.org/?mlat=-7.60080&mlon=110.82880#map=17/-7.60080/110.82880',
      openingHours: '08.00 - 22.00',
      latitude: -7.60080,
      longitude: 110.82880,
      activePromoCount: 0,
    ),
    StoreModel(
      id: 9,
      name: 'Grand Lucky Solo Baru',
      address: 'Kawasan Solo Baru, Grogol',
      city: 'Sukoharjo',
      googleMapsUrl:
          'https://www.openstreetmap.org/?mlat=-7.59350&mlon=110.82310#map=17/-7.59350/110.82310',
      openingHours: '08.00 - 22.00',
      latitude: -7.59350,
      longitude: 110.82310,
      activePromoCount: 0,
    ),
    StoreModel(
      id: 10,
      name: 'Hero Supermarket Solo',
      address: 'Kawasan pusat belanja Solo',
      city: 'Surakarta',
      googleMapsUrl:
          'https://www.openstreetmap.org/?mlat=-7.56910&mlon=110.82510#map=17/-7.56910/110.82510',
      openingHours: '08.00 - 22.00',
      latitude: -7.56910,
      longitude: 110.82510,
      activePromoCount: 0,
    ),
  ];

  Future<List<StoreModel>> getStores() async {
    final client = _supabaseService.clientOrNull;
    if (client != null) {
      try {
        final response = await client.from('stores').select().order('name');
        final stores = (response as List)
            .map((item) => StoreModel.fromMap(item as Map<String, dynamic>))
            .toList();
        if (stores.isNotEmpty) return stores;
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
          'id': await _nextStoreId(),
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

  Future<int> _nextStoreId() async {
    final client = _supabaseService.clientOrNull;
    if (client == null) return 1;

    final response = await client
        .from('stores')
        .select('id')
        .order('id', ascending: false)
        .limit(1);
    final rows = response as List;
    if (rows.isNotEmpty) {
      return (((rows.first as Map)['id']) as num).toInt() + 1;
    }
    return 1;
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
