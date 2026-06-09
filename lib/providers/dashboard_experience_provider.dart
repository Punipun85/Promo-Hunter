import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardExperienceProvider extends ChangeNotifier {
  static const _premiumKey = 'dashboard_is_premium';
  static const _coinsKey = 'dashboard_coin_balance';
  static const _unlockedPromosKey = 'dashboard_unlocked_promos';
  static const _promoFirstSeenPrefix = 'dashboard_promo_first_seen_';
  static const _dailyCycleKey = 'dashboard_daily_cycle_count';
  static const _lastClaimKey = 'dashboard_last_claim_date';
  static const _lastPopupKey = 'dashboard_last_popup_date';
  static const freeAccessDelay = Duration(hours: 6);
  static const unlockCost = 30;
  static const coinPackages = <CoinPackage>[
    CoinPackage(
      id: 'starter',
      name: 'Starter Coin',
      coins: 60,
      price: 5000,
      description: 'Cukup untuk membuka 2 promo early access.',
    ),
    CoinPackage(
      id: 'smart',
      name: 'Smart Saver',
      coins: 150,
      price: 12000,
      description: 'Paket hemat untuk pemburu promo mingguan.',
      isRecommended: true,
    ),
    CoinPackage(
      id: 'hunter',
      name: 'Promo Hunter',
      coins: 350,
      price: 25000,
      description: 'Saldo besar untuk banyak unlock promo.',
    ),
  ];
  static const subscriptionPlans = <SubscriptionPlan>[
    SubscriptionPlan(
      id: 'weekly',
      name: 'Premium Mingguan',
      price: 9000,
      durationLabel: '7 hari',
      description: 'Cocok untuk belanja mingguan dan demo singkat.',
    ),
    SubscriptionPlan(
      id: 'monthly',
      name: 'Premium Bulanan',
      price: 29000,
      durationLabel: '30 hari',
      description: 'Akses semua promo tanpa delay selama sebulan.',
      isRecommended: true,
    ),
    SubscriptionPlan(
      id: 'semester',
      name: 'Premium Semester',
      price: 99000,
      durationLabel: '6 bulan',
      description: 'Paket paling hemat untuk pengguna rutin.',
    ),
  ];

  bool isReady = false;
  bool isPremium = false;
  int coinBalance = 0;
  Set<int> unlockedPromoIds = <int>{};
  int claimedDaysInCycle = 0;
  DateTime? lastClaimedAt;
  DateTime? lastPopupShownAt;
  bool _hasShownEntryDialogsThisSession = false;

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedPrefs = prefs;
    isPremium = prefs.getBool(_premiumKey) ?? false;
    coinBalance = prefs.getInt(_coinsKey) ?? 0;
    unlockedPromoIds = _parseUnlockedPromoIds(
      prefs.getStringList(_unlockedPromosKey) ?? const <String>[],
    );
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
    return isReady && !_hasShownEntryDialogsThisSession;
  }

  Future<void> registerPromos(Iterable<int> promoIds) async {
    if (!isReady) return;
    final prefs = await SharedPreferences.getInstance();
    _cachedPrefs = prefs;
    var changed = false;
    final now = DateTime.now().toIso8601String();
    for (final promoId in promoIds) {
      final key = _promoFirstSeenKey(promoId);
      if (!prefs.containsKey(key)) {
        await prefs.setString(key, now);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  bool isPromoLocked(int promoId) {
    if (!isReady || isPremium || unlockedPromoIds.contains(promoId)) {
      return false;
    }
    final firstSeenAt = _promoFirstSeenAt(promoId);
    if (firstSeenAt == null) return true;
    return DateTime.now().isBefore(firstSeenAt.add(freeAccessDelay));
  }

  Duration promoWaitRemaining(int promoId) {
    final firstSeenAt = _promoFirstSeenAt(promoId);
    if (firstSeenAt == null) return freeAccessDelay;
    final remaining =
        firstSeenAt.add(freeAccessDelay).difference(DateTime.now());
    if (remaining.isNegative) return Duration.zero;
    return remaining;
  }

  String promoLockLabel(int promoId) {
    final remaining = promoWaitRemaining(promoId);
    if (remaining == Duration.zero) return 'Gratis sudah terbuka';
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    if (hours > 0) {
      return 'Tunggu ${hours}j ${minutes}m';
    }
    return 'Tunggu ${minutes}m';
  }

  bool get canUnlockWithCoins => coinBalance >= unlockCost;

  Future<bool> unlockPromoWithCoins(int promoId) async {
    if (isPremium || unlockedPromoIds.contains(promoId)) return true;
    if (coinBalance < unlockCost) return false;
    final prefs = await SharedPreferences.getInstance();
    _cachedPrefs = prefs;
    coinBalance -= unlockCost;
    unlockedPromoIds = {...unlockedPromoIds, promoId};
    await prefs.setInt(_coinsKey, coinBalance);
    await prefs.setStringList(
      _unlockedPromosKey,
      unlockedPromoIds.map((id) => id.toString()).toList(),
    );
    notifyListeners();
    return true;
  }

  Future<void> markEntryDialogsShown() async {
    final prefs = await SharedPreferences.getInstance();
    _hasShownEntryDialogsThisSession = true;
    lastPopupShownAt = DateTime.now();
    await prefs.setString(_lastPopupKey, lastPopupShownAt!.toIso8601String());
    notifyListeners();
  }

  Future<void> resetEntryDialogs() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedPrefs = prefs;
    _hasShownEntryDialogsThisSession = false;
    lastPopupShownAt = null;
    await prefs.remove(_lastPopupKey);
    notifyListeners();
  }

  Future<void> enablePremium() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedPrefs = prefs;
    isPremium = true;
    await prefs.setBool(_premiumKey, true);
    notifyListeners();
  }

  Future<void> subscribeToPlan(SubscriptionPlan plan) async {
    await enablePremium();
  }

  Future<void> topUpCoins(CoinPackage package) async {
    final prefs = await SharedPreferences.getInstance();
    _cachedPrefs = prefs;
    coinBalance += package.coins;
    await prefs.setInt(_coinsKey, coinBalance);
    notifyListeners();
  }

  Future<DailyClaimResult> claimDailyReward() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedPrefs = prefs;
    final now = DateTime.now();
    if (hasClaimedToday) {
      return DailyClaimResult(
        day: claimedDaysInCycle == 0 ? 1 : claimedDaysInCycle,
        coinsEarned: 0,
      );
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
    final coinsEarned = claimedDaysInCycle == 7 ? 50 : 10;
    coinBalance += coinsEarned;
    await prefs.setInt(_dailyCycleKey, claimedDaysInCycle);
    await prefs.setInt(_coinsKey, coinBalance);
    await prefs.setString(_lastClaimKey, now.toIso8601String());
    notifyListeners();
    return DailyClaimResult(day: claimedDaysInCycle, coinsEarned: coinsEarned);
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

  DateTime? _promoFirstSeenAt(int promoId) {
    final prefs = _cachedPrefs;
    if (prefs == null) return null;
    return _parseDate(prefs.getString(_promoFirstSeenKey(promoId)));
  }

  SharedPreferences? _cachedPrefs;

  String _promoFirstSeenKey(int promoId) => '$_promoFirstSeenPrefix$promoId';

  Set<int> _parseUnlockedPromoIds(List<String> values) {
    return values
        .map((value) => int.tryParse(value))
        .whereType<int>()
        .toSet();
  }
}

class DailyClaimResult {
  const DailyClaimResult({
    required this.day,
    required this.coinsEarned,
  });

  final int day;
  final int coinsEarned;
}

class CoinPackage {
  const CoinPackage({
    required this.id,
    required this.name,
    required this.coins,
    required this.price,
    required this.description,
    this.isRecommended = false,
  });

  final String id;
  final String name;
  final int coins;
  final int price;
  final String description;
  final bool isRecommended;
}

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.durationLabel,
    required this.description,
    this.isRecommended = false,
  });

  final String id;
  final String name;
  final int price;
  final String durationLabel;
  final String description;
  final bool isRecommended;
}
