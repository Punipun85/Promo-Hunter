import 'package:flutter_test/flutter_test.dart';
import 'package:promohunter/models/store_model.dart';
import 'package:promohunter/utils/maps_launcher.dart';

void main() {
  group('MapsLauncher', () {
    test('uses clean store name for generic OpenStreetMap search', () {
      const store = StoreModel(
        id: 1,
        name: 'Gerai Alfamart terdekat',
        address: 'Gerai Alfamart terdekat',
        city: 'Indonesia',
        googleMapsUrl:
            'https://www.openstreetmap.org/search?query=Gerai%20Alfamart%20terdekat',
        openingHours: '24 jam',
        latitude: -6.2091,
        longitude: 106.8459,
      );

      final uri = MapsLauncher.storeUri(store);

      expect(uri.path, '/search');
      expect(uri.queryParameters['query'], 'Alfamart');
      expect(uri.fragment, isEmpty);
    });

    test('keeps exact coordinates for real branch locations', () {
      const store = StoreModel(
        id: 2,
        name: 'Alfamart Laweyan Solo',
        address: 'Jl. Dr. Radjiman, Laweyan',
        city: 'Surakarta',
        googleMapsUrl: '',
        openingHours: '24 jam',
        latitude: -7.56655,
        longitude: 110.80890,
      );

      final uri = MapsLauncher.storeUri(store);

      expect(uri.path, '/');
      expect(uri.queryParameters['mlat'], '-7.56655');
      expect(uri.queryParameters['mlon'], '110.8089');
      expect(uri.fragment, 'map=17/-7.56655/110.8089');
    });
  });
}
