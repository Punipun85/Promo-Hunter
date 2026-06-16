class StoreModel {
  const StoreModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.googleMapsUrl,
    required this.openingHours,
    this.latitude,
    this.longitude,
    this.activePromoCount = 0,
  });

  final int id;
  final String name;
  final String address;
  final String city;
  final String googleMapsUrl;
  final String openingHours;
  final double? latitude;
  final double? longitude;
  final int activePromoCount;

  factory StoreModel.fromMap(Map<String, dynamic> map) {
    return StoreModel(
      id: (map['id'] as num).toInt(),
      name: map['name'] as String? ?? '',
      address: map['address'] as String? ?? '',
      city: map['city'] as String? ?? '',
      googleMapsUrl: map['google_maps_url'] as String? ?? '',
      openingHours: map['opening_hours'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      activePromoCount: ((map['active_promo_count'] ?? 0) as num).toInt(),
    );
  }
}
