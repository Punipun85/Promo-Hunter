class ReminderModel {
  const ReminderModel({
    required this.promoId,
    required this.productName,
    required this.storeName,
    required this.reminderTime,
  });

  final int promoId;
  final String productName;
  final String storeName;
  final DateTime reminderTime;
}

