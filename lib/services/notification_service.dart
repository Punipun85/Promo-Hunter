class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  Future<void> initialize() async {
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> schedulePromoReminder({
    required int promoId,
    required String title,
    required DateTime scheduledAt,
  }) async {
    await Future<void>.delayed(Duration.zero);
  }
}

