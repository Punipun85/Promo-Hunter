import 'package:geolocator/geolocator.dart';

class LocationService {
  const LocationService();

  Future<UserLocation> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceException(
        'GPS belum aktif. Aktifkan lokasi perangkat untuk melihat promo terdekat.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationServiceException(
        'Izin lokasi ditolak. Promo masih bisa dilihat dengan urutan biasa.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationServiceException(
        'Izin lokasi diblokir permanen. Buka pengaturan aplikasi untuk mengaktifkannya.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
      ),
    );
    return UserLocation(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}

class UserLocation {
  const UserLocation({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

class LocationServiceException implements Exception {
  const LocationServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
