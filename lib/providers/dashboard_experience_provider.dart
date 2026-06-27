import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/midtrans_payment_status_service.dart';
import '../services/notification_service.dart';

class DashboardExperienceProvider extends ChangeNotifier
    with WidgetsBindingObserver {
  static const _premiumKey = 'dashboard_is_premium';
  static const _premiumExpiresAtKey = 'dashboard_premium_expires_at';
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
  static const _paymentTransactionsKey = 'dashboard_payment_transactions';
  static const freeAccessDelay = Duration(hours: 3);
  static const miniGameDailyLimit = 3;
  static const miniGameRounds = 5;
  static const unlockCost = 30;
  static const memberOnlyPromoModulo = 4;
  static const _midtransStatusPollAttempts = 30;
  static const _midtransStatusPollDelay = Duration(seconds: 2);
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
      id: 'trial',
      name: 'Coba Dulu',
      coins: 30,
      price: 3000,
      description: 'Pas untuk membuka 1 promo early access.',
    ),
    CoinPackage(
      id: 'starter',
      name: 'Starter Coin',
      coins: 60,
      price: 5000,
      description: 'Cukup untuk membuka 2 promo early access.',
    ),
    CoinPackage(
      id: 'daily',
      name: 'Daily Hunter',
      coins: 100,
      price: 9000,
      description: 'Pilihan ringan untuk berburu promo harian.',
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
      id: 'family',
      name: 'Family Saver',
      coins: 250,
      price: 19000,
      description: 'Saldo pas untuk belanja mingguan keluarga.',
    ),
    CoinPackage(
      id: 'hunter',
      name: 'Promo Hunter',
      coins: 350,
      price: 25000,
      description: 'Saldo besar untuk banyak unlock promo.',
    ),
    CoinPackage(
      id: 'ultimate',
      name: 'Ultimate Hemat',
      coins: 600,
      price: 39000,
      description: 'Value terbaik untuk pengguna aktif.',
    ),
  ];
  static const subscriptionPlans = <SubscriptionPlan>[
    SubscriptionPlan(
      id: 'weekly',
      name: 'Premium Mingguan',
      price: 9000,
      durationLabel: '7 hari',
      durationDays: 7,
      description: 'Cocok untuk belanja mingguan dan demo singkat.',
    ),
    SubscriptionPlan(
      id: 'monthly',
      name: 'Premium Bulanan',
      price: 29000,
      durationLabel: '30 hari',
      durationDays: 30,
        description: 'Akses semua promo langsung saat rilis selama sebulan.',
      isRecommended: true,
    ),
    SubscriptionPlan(
      id: 'semester',
      name: 'Premium Semester',
      price: 99000,
      durationLabel: '6 bulan',
      durationDays: 180,
      description: 'Paket paling hemat untuk pengguna rutin.',
    ),
    SubscriptionPlan(
      id: 'yearly',
      name: 'Premium Tahunan',
      price: 179000,
      durationLabel: '1 tahun',
      durationDays: 365,
        description: 'Akses promo instan setahun penuh dengan harga terbaik.',
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
  DateTime? premiumExpiresAt;
  int coinBalance = 0;
  Set<int> unlockedPromoIds = <int>{};
  int claimedDaysInCycle = 0;
  DateTime? lastClaimedAt;
  DateTime? lastPopupShownAt;
  int miniGameAttemptsUsedToday = 0;
  DateTime? lastMiniGamePlayedAt;
  DateTime? lastDailySpinAt;
  List<RedeemedVoucher> redeemedVouchers = <RedeemedVoucher>[];
  List<PaymentTransaction> paymentTransactions = <PaymentTransaction>[];
  bool _hasShownEntryDialogsThisSession = false;
  Timer? _lockCountdownTimer;
  Timer? _miniGameResetTimer;
  final MidtransPaymentStatusService _midtransStatusService =
      MidtransPaymentStatusService();
  bool _isLifecycleObserverRegistered = false;

  Future<void> bootstrap() async {
    if (!_isLifecycleObserverRegistered) {
      WidgetsBinding.instance.addObserver(this);
      _isLifecycleObserverRegistered = true;
    }
    final prefs = await SharedPreferences.getInstance();
    _cachedPrefs = prefs;
    isPremium = prefs.getBool(_premiumKey) ?? false;
    premiumExpiresAt = _parseDate(prefs.getString(_premiumExpiresAtKey));
    await _refreshPremiumStatus(prefs);
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
    paymentTransactions = _parsePaymentTransactions(
      prefs.getStringList(_paymentTransactionsKey) ?? const <String>[],
    );
    await _syncMiniGameDailyState(prefs);
    _scheduleMiniGameResetTimer();
    isReady = true;
    _startLockCountdownTimer();
    notifyListeners();
    unawaited(syncSettledMidtransPayments());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(syncSettledMidtransPayments());
    }
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
    if (!isReady || isPremium) {
      return false;
    }
    if (isMemberOnlyPromo(promoId)) return true;
    if (unlockedPromoIds.contains(promoId)) return false;
    final firstSeenAt = _promoFirstSeenAt(promoId);
    if (firstSeenAt == null) return true;
    return DateTime.now().isBefore(firstSeenAt.add(freeAccessDelay));
  }

  bool isMemberOnlyPromo(int promoId) {
    return promoId > 0 && promoId % memberOnlyPromoModulo == 0;
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
    if (isMemberOnlyPromo(promoId) && !isPremium) {
      return 'Khusus member premium';
    }
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

  bool canUnlockPromoWithCoins(int promoId) {
    return !isMemberOnlyPromo(promoId) && canUnlockWithCoins;
  }

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

  List<PaymentTransaction> get pendingPaymentTransactions => paymentTransactions
      .where((transaction) => transaction.status == PaymentStatus.pending)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Duration get premiumRemaining {
    final expiresAt = premiumExpiresAt;
    if (!isPremium || expiresAt == null) return Duration.zero;
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  String get premiumCountdownLabel {
    final remaining = premiumRemaining;
    if (remaining == Duration.zero) return 'Tidak aktif';
    final days = remaining.inDays;
    final hours = remaining.inHours.remainder(24);
    final minutes = remaining.inMinutes.remainder(60);
    if (days > 0) return '$days hari $hours jam tersisa';
    if (hours > 0) return '$hours jam $minutes menit tersisa';
    return '$minutes menit tersisa';
  }

  String get premiumStatusText {
    if (!isPremium) {
      return 'Paket mulai Rp9.000. User gratis menunggu 3 jam setelah promo rilis, sementara premium membuka semua info promo baru secara instan tanpa coin.';
    }
    final expiry = premiumExpiresAt == null
        ? ''
        : ' sampai ${_formatShortDateTime(premiumExpiresAt!)}';
    return 'Premium aktif$expiry. Sisa waktu: $premiumCountdownLabel.';
  }

  Future<bool> unlockPromoWithCoins(int promoId) async {
    if (isPremium || unlockedPromoIds.contains(promoId)) return true;
    if (isMemberOnlyPromo(promoId)) return false;
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

  Future<void> enablePremium(
      {Duration duration = const Duration(days: 30)}) async {
    final prefs = await SharedPreferences.getInstance();
    _cachedPrefs = prefs;
    final now = DateTime.now();
    final baseTime = premiumExpiresAt != null && premiumExpiresAt!.isAfter(now)
        ? premiumExpiresAt!
        : now;
    isPremium = true;
    premiumExpiresAt = baseTime.add(duration);
    await prefs.setBool(_premiumKey, true);
    await prefs.setString(
      _premiumExpiresAtKey,
      premiumExpiresAt!.toIso8601String(),
    );
    notifyListeners();
  }

  Future<void> subscribeToPlan(SubscriptionPlan plan) async {
    await enablePremium(duration: Duration(days: plan.durationDays));
  }

  Future<void> topUpCoins(CoinPackage package) async {
    final prefs = await SharedPreferences.getInstance();
    _cachedPrefs = prefs;
    coinBalance += package.coins;
    await prefs.setInt(_coinsKey, coinBalance);
    notifyListeners();
  }

  Future<PaymentTransaction> createCoinTopUpTransaction({
    required CoinPackage package,
    required String userId,
    required String userName,
    required String userEmail,
    required String paymentMethod,
    required String proofFileName,
    String? paymentReference,
    String? paymentUrl,
  }) async {
    final transaction = PaymentTransaction(
      id: _generateTransactionId(),
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      type: PaymentTransactionType.coinTopUp,
      status: PaymentStatus.pending,
      itemId: package.id,
      itemName: package.name,
      benefitLabel: '${package.coins} coin',
      price: package.price,
      coins: package.coins,
      durationDays: null,
      paymentMethod: paymentMethod,
      proofFileName: proofFileName,
      paymentReference: paymentReference,
      paymentUrl: paymentUrl,
      createdAt: DateTime.now(),
    );
    await _savePaymentTransaction(transaction);
    return transaction;
  }

  Future<PaymentTransaction> createSubscriptionTransaction({
    required SubscriptionPlan plan,
    required String userId,
    required String userName,
    required String userEmail,
    required String paymentMethod,
    required String proofFileName,
    String? paymentReference,
    String? paymentUrl,
  }) async {
    final transaction = PaymentTransaction(
      id: _generateTransactionId(),
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      type: PaymentTransactionType.subscription,
      status: PaymentStatus.pending,
      itemId: plan.id,
      itemName: plan.name,
      benefitLabel: plan.durationLabel,
      price: plan.price,
      coins: null,
      durationDays: plan.durationDays,
      paymentMethod: paymentMethod,
      proofFileName: proofFileName,
      paymentReference: paymentReference,
      paymentUrl: paymentUrl,
      createdAt: DateTime.now(),
    );
    await _savePaymentTransaction(transaction);
    return transaction;
  }

  Future<void> approvePaymentTransaction(String transactionId) async {
    final index = paymentTransactions.indexWhere(
      (transaction) => transaction.id == transactionId,
    );
    if (index == -1) return;
    final transaction = paymentTransactions[index];
    if (transaction.status != PaymentStatus.pending) return;

    final prefs = await SharedPreferences.getInstance();
    _cachedPrefs = prefs;

    if (transaction.type == PaymentTransactionType.coinTopUp) {
      coinBalance += transaction.coins ?? 0;
      await prefs.setInt(_coinsKey, coinBalance);
    } else {
      final now = DateTime.now();
      final baseTime =
          premiumExpiresAt != null && premiumExpiresAt!.isAfter(now)
              ? premiumExpiresAt!
              : now;
      isPremium = true;
      premiumExpiresAt =
          baseTime.add(Duration(days: transaction.durationDays ?? 30));
      await prefs.setBool(_premiumKey, true);
      await prefs.setString(
        _premiumExpiresAtKey,
        premiumExpiresAt!.toIso8601String(),
      );
    }

    final updated = transaction.copyWith(
      status: PaymentStatus.approved,
      verifiedAt: DateTime.now(),
    );
    paymentTransactions = [
      ...paymentTransactions.sublist(0, index),
      updated,
      ...paymentTransactions.sublist(index + 1),
    ];
    await _persistPaymentTransactions(prefs);
    notifyListeners();
    await NotificationService.instance.showPaymentCompleted(
      title: 'Pembayaran berhasil',
      body: '${transaction.itemName} sudah aktif untuk ${transaction.userName}.',
    );
  }

  Future<bool> syncSettledMidtransPayments() async {
    var approvedAny = false;
    final pendingMidtransTransactions = paymentTransactions.where(
      (transaction) =>
          transaction.status == PaymentStatus.pending &&
          transaction.paymentReference != null &&
          transaction.paymentMethod.toLowerCase().contains('midtrans'),
    ).toList();

    for (final transaction in pendingMidtransTransactions) {
      final status = await _midtransStatusService.getStatus(
        transaction.paymentReference!,
      );
      if (status == null || !status.paid) continue;

      await approvePaymentTransaction(transaction.id);
      approvedAny = true;
    }
    return approvedAny;
  }

  Future<bool> waitForMidtransSettlement(String transactionId) async {
    final initialMatch = paymentTransactions.where(
      (item) => item.id == transactionId,
    );
    if (initialMatch.isEmpty ||
        !initialMatch.first.paymentMethod.toLowerCase().contains('midtrans')) {
      return false;
    }

    for (var attempt = 0; attempt < _midtransStatusPollAttempts; attempt += 1) {
      final synced = await syncSettledMidtransPayments();
      final transaction = paymentTransactions.where(
        (item) => item.id == transactionId,
      );
      if (transaction.isNotEmpty &&
          transaction.first.status == PaymentStatus.approved) {
        return true;
      }
      if (synced) return true;
      await Future<void>.delayed(_midtransStatusPollDelay);
    }
    return false;
  }

  Future<PaymentStatus?> syncMidtransTransactionByReference(
    String paymentReference,
  ) async {
    final normalized = paymentReference.trim();
    if (normalized.isEmpty) return null;

    final index = paymentTransactions.indexWhere(
      (transaction) => transaction.paymentReference == normalized,
    );
    if (index == -1) return null;

    final transaction = paymentTransactions[index];
    final status = await _midtransStatusService.getStatus(normalized);
    if (status == null) return transaction.status;

    if (status.paid) {
      await approvePaymentTransaction(transaction.id);
      return PaymentStatus.approved;
    }

    if (status.failed) {
      await rejectPaymentTransaction(transaction.id);
      return PaymentStatus.rejected;
    }

    return transaction.status;
  }

  Future<PaymentStatus?> waitForMidtransResultByReference(
    String paymentReference,
  ) async {
    for (var attempt = 0; attempt < _midtransStatusPollAttempts; attempt += 1) {
      final status = await syncMidtransTransactionByReference(paymentReference);
      if (status == PaymentStatus.approved ||
          status == PaymentStatus.rejected) {
        return status;
      }
      await Future<void>.delayed(_midtransStatusPollDelay);
    }

    return syncMidtransTransactionByReference(paymentReference);
  }

  Future<void> rejectPaymentTransaction(String transactionId) async {
    final index = paymentTransactions.indexWhere(
      (transaction) => transaction.id == transactionId,
    );
    if (index == -1) return;
    final transaction = paymentTransactions[index];
    if (transaction.status != PaymentStatus.pending) return;
    final prefs = await SharedPreferences.getInstance();
    _cachedPrefs = prefs;
    final updated = transaction.copyWith(
      status: PaymentStatus.rejected,
      verifiedAt: DateTime.now(),
    );
    paymentTransactions = [
      ...paymentTransactions.sublist(0, index),
      updated,
      ...paymentTransactions.sublist(index + 1),
    ];
    await _persistPaymentTransactions(prefs);
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

  bool hasUnusedRedeemedVoucher(String voucherId) {
    return redeemedVouchers.any(
      (voucher) => voucher.voucherId == voucherId && !voucher.isUsed,
    );
  }

  bool hasUsedRedeemedVoucher(String voucherId) {
    return redeemedVouchers.any(
      (voucher) => voucher.voucherId == voucherId && voucher.isUsed,
    );
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
    await prefs.setString(
        _dailySpinDateKey, lastDailySpinAt!.toIso8601String());
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

  List<PaymentTransaction> _parsePaymentTransactions(List<String> values) {
    return values
        .map((value) {
          try {
            final decoded = jsonDecode(value);
            if (decoded is Map<String, dynamic>) {
              return PaymentTransaction.fromJson(decoded);
            }
          } catch (_) {
            return null;
          }
          return null;
        })
        .whereType<PaymentTransaction>()
        .toList();
  }

  Future<void> _savePaymentTransaction(
    PaymentTransaction transaction,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    _cachedPrefs = prefs;
    paymentTransactions = [transaction, ...paymentTransactions];
    await _persistPaymentTransactions(prefs);
    notifyListeners();
  }

  Future<void> _persistPaymentTransactions(SharedPreferences prefs) {
    return prefs.setStringList(
      _paymentTransactionsKey,
      paymentTransactions
          .map((transaction) => jsonEncode(transaction.toJson()))
          .toList(),
    );
  }

  String _generateTransactionId() {
    return 'trx-${DateTime.now().millisecondsSinceEpoch}';
  }

  void _startLockCountdownTimer() {
    _lockCountdownTimer?.cancel();
    _lockCountdownTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      if (!isReady) return;
      final prefs = _cachedPrefs ?? await SharedPreferences.getInstance();
      await _refreshPremiumStatus(prefs);
      notifyListeners();
    });
  }

  Future<bool> _refreshPremiumStatus(SharedPreferences prefs) async {
    final expiresAt = premiumExpiresAt;
    if (!isPremium || expiresAt == null) return false;
    if (DateTime.now().isBefore(expiresAt)) return false;

    isPremium = false;
    premiumExpiresAt = null;
    await prefs.setBool(_premiumKey, false);
    await prefs.remove(_premiumExpiresAtKey);
    return true;
  }

  String _formatShortDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  @override
  void dispose() {
    if (_isLifecycleObserverRegistered) {
      WidgetsBinding.instance.removeObserver(this);
      _isLifecycleObserverRegistered = false;
    }
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
      isUsed: false,
      usedAt: null,
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
    required this.durationDays,
    required this.description,
    this.isRecommended = false,
  });

  final String id;
  final String name;
  final int price;
  final String durationLabel;
  final int durationDays;
  final String description;
  final bool isRecommended;
}

enum PaymentTransactionType {
  coinTopUp,
  subscription;

  String get label {
    switch (this) {
      case PaymentTransactionType.coinTopUp:
        return 'Topup Coin';
      case PaymentTransactionType.subscription:
        return 'Langganan Premium';
    }
  }
}

enum PaymentStatus {
  pending,
  approved,
  rejected;

  String get label {
    switch (this) {
      case PaymentStatus.pending:
        return 'Menunggu Verifikasi';
      case PaymentStatus.approved:
        return 'Berhasil';
      case PaymentStatus.rejected:
        return 'Ditolak';
    }
  }
}

class PaymentTransaction {
  const PaymentTransaction({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.type,
    required this.status,
    required this.itemId,
    required this.itemName,
    required this.benefitLabel,
    required this.price,
    required this.paymentMethod,
    required this.proofFileName,
    required this.createdAt,
    this.coins,
    this.durationDays,
    this.paymentReference,
    this.paymentUrl,
    this.verifiedAt,
  });

  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final PaymentTransactionType type;
  final PaymentStatus status;
  final String itemId;
  final String itemName;
  final String benefitLabel;
  final int price;
  final int? coins;
  final int? durationDays;
  final String paymentMethod;
  final String proofFileName;
  final String? paymentReference;
  final String? paymentUrl;
  final DateTime createdAt;
  final DateTime? verifiedAt;

  bool get isMidtransPayment =>
      paymentMethod.toLowerCase().contains('midtrans') ||
      paymentReference != null;

  String get statusLabel {
    if (status == PaymentStatus.pending && isMidtransPayment) {
      return 'Menunggu Konfirmasi Midtrans';
    }
    return status.label;
  }

  PaymentTransaction copyWith({
    PaymentStatus? status,
    DateTime? verifiedAt,
  }) {
    return PaymentTransaction(
      id: id,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      type: type,
      status: status ?? this.status,
      itemId: itemId,
      itemName: itemName,
      benefitLabel: benefitLabel,
      price: price,
      coins: coins,
      durationDays: durationDays,
      paymentMethod: paymentMethod,
      proofFileName: proofFileName,
      paymentReference: paymentReference,
      paymentUrl: paymentUrl,
      createdAt: createdAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
    );
  }

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? 'User PromoHunter',
      userEmail: json['userEmail'] as String? ?? '',
      type: PaymentTransactionType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => PaymentTransactionType.coinTopUp,
      ),
      status: PaymentStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      itemId: json['itemId'] as String? ?? '',
      itemName: json['itemName'] as String? ?? '',
      benefitLabel: json['benefitLabel'] as String? ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      coins: (json['coins'] as num?)?.toInt(),
      durationDays: (json['durationDays'] as num?)?.toInt(),
      paymentMethod: json['paymentMethod'] as String? ?? '',
      proofFileName: json['proofFileName'] as String? ?? '',
      paymentReference: json['paymentReference'] as String?,
      paymentUrl: json['paymentUrl'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      verifiedAt: DateTime.tryParse(json['verifiedAt'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'type': type.name,
      'status': status.name,
      'itemId': itemId,
      'itemName': itemName,
      'benefitLabel': benefitLabel,
      'price': price,
      'coins': coins,
      'durationDays': durationDays,
      'paymentMethod': paymentMethod,
      'proofFileName': proofFileName,
      'paymentReference': paymentReference,
      'paymentUrl': paymentUrl,
      'createdAt': createdAt.toIso8601String(),
      'verifiedAt': verifiedAt?.toIso8601String(),
    };
  }
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
    required this.isUsed,
    required this.usedAt,
  });

  final String id;
  final String voucherId;
  final String title;
  final String benefitLabel;
  final int coinCost;
  final String code;
  final DateTime redeemedAt;
  final bool isUsed;
  final DateTime? usedAt;

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
      isUsed: json['isUsed'] as bool? ?? false,
      usedAt: DateTime.tryParse(json['usedAt'] as String? ?? ''),
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
      'isUsed': isUsed,
      'usedAt': usedAt?.toIso8601String(),
    };
  }
}
