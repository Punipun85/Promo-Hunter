class StoreModel {
  const StoreModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.googleMapsUrl,
    required this.openingHours,
    this.activePromoCount = 0,
  });

  final int id;
  final String name;
  final String address;
  final String city;
  final String googleMapsUrl;
  final String openingHours;
  final int activePromoCount;
}

