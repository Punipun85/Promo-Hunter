import 'package:flutter/foundation.dart';

import '../models/promo_model.dart';
import '../models/reminder_model.dart';
import '../services/reminder_service.dart';

class ReminderProvider extends ChangeNotifier {
  ReminderProvider(this._service);

  final ReminderService _service;

  List<ReminderModel> reminders = [];
  bool isLoading = false;

  bool hasReminder(int promoId) =>
      reminders.any((item) => item.promoId == promoId);

  Future<void> bootstrapForUser(String userId) async {
    isLoading = true;
    notifyListeners();
    reminders = await _service.getUserReminders(userId);
    isLoading = false;
    notifyListeners();
  }

  Future<String?> addReminder(
    String userId,
    PromoModel promo,
    Duration beforeEnd,
  ) async {
    final message =
        await _service.createReminder(userId, promo, promo.endDate.subtract(beforeEnd));
    reminders = await _service.getUserReminders(userId);
    notifyListeners();
    return message;
  }

  Future<void> removeReminder(String userId, int promoId) async {
    await _service.deleteReminder(userId, promoId);
    reminders = await _service.getUserReminders(userId);
    notifyListeners();
  }

  void clear() {
    reminders = <ReminderModel>[];
    notifyListeners();
  }
}
