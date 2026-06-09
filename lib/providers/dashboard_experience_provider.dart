import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardExperienceProvider extends ChangeNotifier {
  static const _premiumKey = 'dashboard_is_premium';
  static const _dailyCycleKey = 'dashboard_daily_cycle_count';
  static const _lastClaimKey = 'dashboard_last_claim_date';
  static const _lastPopupKey = 'dashboard_last_popup_date';

  bool isReady = false;
  bool isPremium = false;
  int claimedDaysInCycle = 0;
  DateTime? lastClaimedAt;
  DateTime? lastPopupShownAt;

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    isPremium = prefs.getBool(_premiumKey) ?? false;
    claimedDaysInCycle = prefs.getInt(_dailyCycleKey) ?? 0;
    lastClaimedAt = _parseDate(prefs.getString(_lastClaimKey));
    lastPopupShownAt = _parseDate(prefs.getString(_lastPopupKey));
    isReady = true;
    notifyListeners();
  }

  bool get hasClaimedToday {
    if (lastClaimedAt == null) return false;
    return _isSameDay(lastClaimedAt!, DateTime.now());
  }

  int get nextDailyDay {
    final isCycleComplete = claimedDaysInCycle >= 7;
    if (isCycleComplete && !hasClaimedToday) {
      return 1;
    }
    if (hasClaimedToday) {
      return claimedDaysInCycle == 0 ? 1 : claimedDaysInCycle;
    }
    return (claimedDaysInCycle + 1).clamp(1, 7);
  }

  bool shouldShowEntryDialogs() {
    if (!isReady) return false;
    final today = DateTime.now();
    if (lastPopupShownAt == null) return true;
    return !_isSameDay(lastPopupShownAt!, today);
  }

  Future<void> markEntryDialogsShown() async {
    final prefs = await SharedPreferences.getInstance();
    lastPopupShownAt = DateTime.now();
    await prefs.setString(_lastPopupKey, lastPopupShownAt!.toIso8601String());
    notifyListeners();
  }

  Future<void> enablePremium() async {
    final prefs = await SharedPreferences.getInstance();
    isPremium = true;
    await prefs.setBool(_premiumKey, true);
    notifyListeners();
  }

  Future<int> claimDailyReward() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    if (hasClaimedToday) {
      return claimedDaysInCycle == 0 ? 1 : claimedDaysInCycle;
    }

    final previousClaim = lastClaimedAt;
    if (previousClaim == null) {
      claimedDaysInCycle = 1;
    } else {
      final previousDate =
          DateTime(previousClaim.year, previousClaim.month, previousClaim.day);
      final currentDate = DateTime(now.year, now.month, now.day);
      final gap = currentDate.difference(previousDate).inDays;
      if (gap <= 1) {
        claimedDaysInCycle = claimedDaysInCycle >= 7 ? 1 : claimedDaysInCycle + 1;
      } else {
        claimedDaysInCycle = 1;
      }
    }

    lastClaimedAt = now;
    await prefs.setInt(_dailyCycleKey, claimedDaysInCycle);
    await prefs.setString(_lastClaimKey, now.toIso8601String());
    notifyListeners();
    return claimedDaysInCycle;
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}
