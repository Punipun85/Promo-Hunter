import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardExperienceProvider extends ChangeNotifier {
  static const _premiumKey = 'dashboard_is_premium';
  static const _coinsKey = 'dashboard_coin_balance';
  static const _unlockedPromosKey = 'dashboard_unlocked_promos';
  static const _promoFirstSeenPrefix = 'dashboard_promo_first_seen_';
  static const _dailyCycleKey = 'dashboard_daily_cycle_count';
  static const _lastClaimKey = 'dashboard_last_claim_date';
  static const _lastPopupKey = 'dashboard_last_popup_date';
  static const _miniGameAttemptsKey = 'dashboard_mini_game_attempts';
  static const _miniGameDateKey = 'dashboard_mini_game_date';
  static const _dailySpinDateKey = 'dashboard_daily_spin_date';
  static const _redeemedVouchersKey = 'dashboard_redeemed_vouchers';
  static const freeAccessDelay = Duration(hours: 6);
  static const miniGameDailyLimit = 3;
  static const miniGameRounds = 5;
  static const unlockCost = 30;
  static const dailySpinRewards = <DailySpinReward>[
    DailySpinReward(
      id: 'coin-10',
      title: '10 Coin',
      description: 'Tambahan kecil untuk membuka promo terkunci.',
      coins: 10,
      icon: Icons.monetization_on_outlined,
    ),
    DailySpinReward(
      id: 'coin-20',
      title: '20 Coin',
      description: 'Lumayan dekat ke biaya unlock promo.',
      coins: 20,
      icon: Icons.savings_outlined,
    ),
    DailySpinReward(
      id: 'voucher-ongkir-spin',
      title: 'Gratis Ongkir',
      description: 'Voucher langsung masuk ke wallet kamu.',
      voucherId: 'voucher-ongkir',
      icon: Icons.local_shipping_outlined,
    ),
    DailySpinReward(
      id: 'coin-30',
      title: '30 Coin',
      description: 'Cukup untuk membuka satu promo early access.',
      coins: 30,
      icon: Icons.lock_open_outlined,
    ),
    DailySpinReward(
      id: 'voucher-15k-spin',
      title: 'Voucher Rp15.000',
      description: 'Reward voucher belanja dari spin harian.',
      voucherId: 'voucher-15k',
      icon: Icons.local_offer_outlined,
    ),
    DailySpinReward(
      id: 'coin-15',
      title: '15 Coin',
      description: 'Bonus harian untuk pemburu promo aktif.',
      coins: 15,
      icon: Icons.toll_outlined,
    ),
  ];
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
  static const voucherCatalog = <VoucherReward>[
    VoucherReward(
      id: 'voucher-starter',
      title: 'Voucher Starter Rp5.000',
      coinCost: 0,
      description: 'Voucher gratis agar wallet tidak terasa semua terkunci.',
      benefitLabel: 'Potongan Rp5.000',
      icon: Icons.redeem_outlined,
    ),
    VoucherReward(
      id: 'voucher-15k',
      title: 'Voucher Belanja Rp15.000',
      coinCost: 45,
      description: 'Cocok untuk belanja ringan atau item promo kecil.',
      benefitLabel: 'Potongan Rp15.000',
      icon: Icons.local_offer_outlined,
    ),
    VoucherReward(
      id: 'voucher-ongkir',
      title: 'Voucher Gratis Ongkir',
      coinCost: 30,
      description: 'Pakai saat checkout supaya biaya kirim lebih ringan.',
      benefitLabel: 'Gratis ongkir',
      icon: Icons.local_shipping_outlined,
    ),
    VoucherReward(
      id: 'voucher-25k',
      title: 'Voucher Belanja Rp25.000',
      coinCost: 70,
      description: 'Lebih hemat untuk pembelian mingguan yang lebih besar.',
      benefitLabel: 'Potongan Rp25.000',
      icon: Icons.confirmation_number_outlined,
    ),
  ];

  bool isReady = false;
  bool isPremium = false;
  int coinBalance = 0;
  Set<int> unlockedPromoIds = <int>{};
  int claimedDaysInCycle = 0;
  DateTime? lastClaimedAt;
  DateTime? lastPopupShownAt;
  int miniGameAttemptsUsedToday = 0;
  DateTime? lastMiniGamePlayedAt;
  DateTime? lastDailySpinAt;
  List<RedeemedVoucher> redeemedVouchers = <RedeemedVoucher>[];
  bool _hasShownEntryDialogsThisSession = false;
  Timer? _lockCountdownTimer;
  Timer? _miniGameResetTimer;

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
    lastDailySpinAt = _parseDate(prefs.getString(_dailySpinDateKey));
    redeemedVouchers = _parseRedeemedVouchers(
      prefs.getStringList(_redeemedVouchersKey) ?? const <String>[],
    );
    await _syncMiniGameDailyState(prefs);
    _scheduleMiniGameResetTimer();
    isReady = true;
    _startLockCountdownTimer();
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

  int get miniGameRemainingAttempts {
    final playedAt = lastMiniGamePlayedAt;
    if (playedAt == null || !_isSameDay(playedAt, DateTime.now())) {
      return miniGameDailyLimit;
    }
    return (miniGameDailyLimit - miniGameAttemptsUsedToday)
        .clamp(0, miniGameDailyLimit)
        .toInt();
  }

  bool get canPlayMiniGame => miniGameRemainingAttempts > 0;

  bool get hasSpunToday {
    if (lastDailySpinAt == null) return false;
    return _isSameDay(lastDailySpinAt!, DateTime.now());
  }

  bool get canSpinDaily => !hasSpunToday;

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

  Future<MiniGameResult> playMiniGame({required int score}) async {
    final prefs = await SharedPreferences.getInstance();
    _cachedPrefs = prefs;
    await _syncMiniGameDailyState(prefs);

    if (miniGameRemainingAttempts <= 0) {
      return const MiniGameResult(
        score: 0,
        coinsEarned: 0,
        attemptsLeft: 0,
        isLimitReached: true,
      );
    }

    final safeScore = score.clamp(0, miniGameRounds);
    final coinsEarned = _coinsForMiniGameScore(safeScore);

    miniGameAttemptsUsedToday += 1;
    lastMiniGamePlayedAt = DateTime.now();
    coinBalance += coinsEarned;

    await prefs.setInt(_miniGameAttemptsKey, miniGameAttemptsUsedToday);
    await prefs.setString(
      _miniGameDateKey,
      lastMiniGamePlayedAt!.toIso8601String(),
    );
    await prefs.setInt(_coinsKey, coinBalance);
    notifyListeners();

    return MiniGameResult(
      score: safeScore,
      coinsEarned: coinsEarned,
      attemptsLeft: miniGameRemainingAttempts,
      isLimitReached: false,
    );
  }

  Future<RedeemedVoucher?> redeemVoucher(String voucherId) async {
    VoucherReward? voucher;
    for (final item in voucherCatalog) {
      if (item.id == voucherId) {
        voucher = item;
        break;
      }
    }
    if (voucher == null || coinBalance < voucher.coinCost) {
      return null;
    }
    if (voucher.coinCost == 0 && hasRedeemedVoucher(voucher.id)) {
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    _cachedPrefs = prefs;
    await _syncMiniGameDailyState(prefs);

    coinBalance -= voucher.coinCost;
    final redemption = _createVoucherRedemption(voucher);
    redeemedVouchers = <RedeemedVoucher>[redemption, ...redeemedVouchers];

    await prefs.setInt(_coinsKey, coinBalance);
    await prefs.setStringList(
      _redeemedVouchersKey,
      redeemedVouchers.map((item) => jsonEncode(item.toJson())).toList(),
    );
    notifyListeners();
    return redemption;
  }

  bool hasRedeemedVoucher(String voucherId) {
    return redeemedVouchers.any((voucher) => voucher.voucherId == voucherId);
  }

  Future<DailySpinResult> spinDailyReward({int? forcedIndex}) async {
    final prefs = await SharedPreferences.getInstance();
    _cachedPrefs = prefs;

    if (hasSpunToday) {
      return const DailySpinResult(
        reward: null,
        coinsEarned: 0,
        redeemedVoucher: null,
        isAlreadyClaimed: true,
      );
    }

    final index = forcedIndex ?? Random().nextInt(dailySpinRewards.length);
    final reward = dailySpinRewards[index % dailySpinRewards.length];
    RedeemedVoucher? redeemedVoucher;
    var coinsEarned = reward.coins;

    if (coinsEarned > 0) {
      coinBalance += coinsEarned;
      await prefs.setInt(_coinsKey, coinBalance);
    }

    if (reward.voucherId != null) {
      final voucher = _voucherById(reward.voucherId!);
      if (voucher != null) {
        redeemedVoucher = _createVoucherRedemption(voucher, coinCost: 0);
        redeemedVouchers = <RedeemedVoucher>[
          redeemedVoucher,
          ...redeemedVouchers,
        ];
        await prefs.setStringList(
          _redeemedVouchersKey,
          redeemedVouchers.map((item) => jsonEncode(item.toJson())).toList(),
        );
      }
    }

    lastDailySpinAt = DateTime.now();
    await prefs.setString(_dailySpinDateKey, lastDailySpinAt!.toIso8601String());
    notifyListeners();

    return DailySpinResult(
      reward: reward,
      coinsEarned: coinsEarned,
      redeemedVoucher: redeemedVoucher,
      isAlreadyClaimed: false,
    );
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
        claimedDaysInCycle =
            claimedDaysInCycle >= 7 ? 1 : claimedDaysInCycle + 1;
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
    return values.map((value) => int.tryParse(value)).whereType<int>().toSet();
  }

  Future<void> _syncMiniGameDailyState(SharedPreferences prefs) async {
    final now = DateTime.now();
    final storedDate = _parseDate(prefs.getString(_miniGameDateKey));
    if (storedDate == null || !_isSameDay(storedDate, now)) {
      miniGameAttemptsUsedToday = 0;
      lastMiniGamePlayedAt = null;
      await prefs.remove(_miniGameAttemptsKey);
      await prefs.remove(_miniGameDateKey);
      return;
    }

    miniGameAttemptsUsedToday = prefs.getInt(_miniGameAttemptsKey) ?? 0;
    lastMiniGamePlayedAt = storedDate;
  }

  void _scheduleMiniGameResetTimer() {
    _miniGameResetTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final delay = nextMidnight.difference(now) + const Duration(seconds: 1);
    _miniGameResetTimer = Timer(delay, () async {
      final prefs = _cachedPrefs ?? await SharedPreferences.getInstance();
      await _syncMiniGameDailyState(prefs);
      if (isReady) {
        notifyListeners();
      }
      _scheduleMiniGameResetTimer();
    });
  }

  int _coinsForMiniGameScore(int score) {
    switch (score) {
      case 5:
        return 25;
      case 4:
        return 18;
      case 3:
        return 12;
      case 2:
        return 8;
      case 1:
        return 5;
      default:
        return 0;
    }
  }

  String _generateVoucherCode(VoucherReward voucher) {
    final token = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final prefix = voucher.id.replaceAll('-', '');
    return 'PH-${prefix.substring(0, 3).toUpperCase()}-${token.toUpperCase()}';
  }

  List<RedeemedVoucher> _parseRedeemedVouchers(List<String> values) {
    return values
        .map((value) {
          try {
            final decoded = jsonDecode(value);
            if (decoded is Map<String, dynamic>) {
              return RedeemedVoucher.fromJson(decoded);
            }
          } catch (_) {
            return null;
          }
          return null;
        })
        .whereType<RedeemedVoucher>()
        .toList();
  }

  void _startLockCountdownTimer() {
    _lockCountdownTimer?.cancel();
    _lockCountdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (isReady && !isPremium) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _lockCountdownTimer?.cancel();
    _miniGameResetTimer?.cancel();
    super.dispose();
  }

  VoucherReward? _voucherById(String voucherId) {
    for (final voucher in voucherCatalog) {
      if (voucher.id == voucherId) return voucher;
    }
    return null;
  }

  RedeemedVoucher _createVoucherRedemption(
    VoucherReward voucher, {
    int? coinCost,
  }) {
    return RedeemedVoucher(
      id: 'redeem-${DateTime.now().millisecondsSinceEpoch}',
      voucherId: voucher.id,
      title: voucher.title,
      benefitLabel: voucher.benefitLabel,
      coinCost: coinCost ?? voucher.coinCost,
      code: _generateVoucherCode(voucher),
      redeemedAt: DateTime.now(),
    );
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

class MiniGameResult {
  const MiniGameResult({
    required this.score,
    required this.coinsEarned,
    required this.attemptsLeft,
    required this.isLimitReached,
  });

  final int score;
  final int coinsEarned;
  final int attemptsLeft;
  final bool isLimitReached;
}

class DailySpinReward {
  const DailySpinReward({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.coins = 0,
    this.voucherId,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int coins;
  final String? voucherId;

  bool get isVoucher => voucherId != null;
}

class DailySpinResult {
  const DailySpinResult({
    required this.reward,
    required this.coinsEarned,
    required this.redeemedVoucher,
    required this.isAlreadyClaimed,
  });

  final DailySpinReward? reward;
  final int coinsEarned;
  final RedeemedVoucher? redeemedVoucher;
  final bool isAlreadyClaimed;
}

class VoucherReward {
  const VoucherReward({
    required this.id,
    required this.title,
    required this.coinCost,
    required this.description,
    required this.benefitLabel,
    required this.icon,
  });

  final String id;
  final String title;
  final int coinCost;
  final String description;
  final String benefitLabel;
  final IconData icon;
}

class RedeemedVoucher {
  const RedeemedVoucher({
    required this.id,
    required this.voucherId,
    required this.title,
    required this.benefitLabel,
    required this.coinCost,
    required this.code,
    required this.redeemedAt,
  });

  final String id;
  final String voucherId;
  final String title;
  final String benefitLabel;
  final int coinCost;
  final String code;
  final DateTime redeemedAt;

  factory RedeemedVoucher.fromJson(Map<String, dynamic> json) {
    return RedeemedVoucher(
      id: json['id'] as String? ?? '',
      voucherId: json['voucherId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      benefitLabel: json['benefitLabel'] as String? ?? '',
      coinCost: (json['coinCost'] as num?)?.toInt() ?? 0,
      code: json['code'] as String? ?? '',
      redeemedAt: DateTime.tryParse(json['redeemedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'voucherId': voucherId,
      'title': title,
      'benefitLabel': benefitLabel,
      'coinCost': coinCost,
      'code': code,
      'redeemedAt': redeemedAt.toIso8601String(),
    };
  }
}
