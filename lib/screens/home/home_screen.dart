import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../models/promo_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_experience_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/promo_provider.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/promo_card.dart';
import '../../widgets/store_card.dart';
import '../../widgets/stats_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isShowingEntryDialogs = false;

  // ── Category icons map ──
  static const Map<String, String> _categoryIcons = {
    'Semua': '🔥',
    'Makanan': '🍔',
    'Minuman': '🥤',
    'Elektronik': '📱',
    'Fashion': '👗',
    'Kesehatan': '💊',
    'Travel': '✈️',
    'Hiburan': '🎬',
    'Otomotif': '🚗',
    'Belanja': '🛍️',
    'Kuliner': '🍽️',
    'Kebutuhan Harian': '🛒',
    'Gadget': '📱',
    'Kosmetik': '💄',
    'Olahraga': '⚽',
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerVisiblePromos();
      _showEntryDialogsIfNeeded();
    });
  }

  Future<void> _registerVisiblePromos() async {
    if (!mounted) return;
    final promoProvider = context.read<PromoProvider>();
    final experience = context.read<DashboardExperienceProvider>();
    if (!experience.isReady || promoProvider.promos.isEmpty) return;
    await experience
        .registerPromos(promoProvider.promos.map((promo) => promo.id));
  }

  Future<void> _showEntryDialogsIfNeeded() async {
    if (!mounted || _isShowingEntryDialogs) return;

    final promoProvider = context.read<PromoProvider>();
    final experience = context.read<DashboardExperienceProvider>();
    if (promoProvider.isLoading ||
        promoProvider.errorMessage != null ||
        promoProvider.popularPromos.isEmpty ||
        !experience.isReady ||
        !experience.shouldShowEntryDialogs()) {
      return;
    }

    _isShowingEntryDialogs = true;
    PromoModel? selectedPromo;

    final featuredPromo = promoProvider.popularPromos.first;
    final wantsToViewPromo = await _showFeaturedPromoDialog(featuredPromo);
    if (!mounted) return;
    if (wantsToViewPromo == true) {
      selectedPromo = featuredPromo;
    }

    if (!experience.isPremium) {
      final premiumAccepted = await _showPremiumDialog();
      if (!mounted) return;
      if (premiumAccepted == true) {
        Navigator.pushNamed(context, AppRoutes.wallet);
      }
    }

    final claimedDay = await _showDailyRewardDialog();
    if (!mounted) return;
    if (claimedDay != null) {
      final message = claimedDay.day == 7
          ? 'Day 7 memberi ${claimedDay.coinsEarned} coin. Reward mingguan lengkap.'
          : 'Day ${claimedDay.day} memberi ${claimedDay.coinsEarned} coin.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }

    await experience.markEntryDialogsShown();
    _isShowingEntryDialogs = false;

    if (selectedPromo != null && mounted) {
      Navigator.pushNamed(
        context,
        AppRoutes.promoDetail,
        arguments: selectedPromo,
      );
    }
  }

  Future<bool?> _showFeaturedPromoDialog(PromoModel promo) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          titlePadding: const EdgeInsets.fromLTRB(24, 18, 14, 0),
          title: Row(
            children: [
              const Expanded(child: Text('Promo Bagus Hari Ini')),
              IconButton(
                tooltip: 'Tutup',
                onPressed: () => Navigator.pop(context, false),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0A8),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Diskon ${promo.discountPercent.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: const Color(0xFF7C5A00),
                      ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                promo.productName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text('${promo.storeName} • ${promo.categoryName}'),
              const SizedBox(height: 12),
              Text(
                CurrencyFormatter.format(promo.promoPrice),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hemat ${CurrencyFormatter.format(promo.savingsAmount)} sampai promo berakhir.',
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Lihat Promo'),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showPremiumDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          titlePadding: const EdgeInsets.fromLTRB(24, 18, 14, 0),
          title: Row(
            children: [
              const Expanded(child: Text('Langganan Member Premium')),
              IconButton(
                tooltip: 'Tutup',
                onPressed: () => Navigator.pop(context, false),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih paket premium atau topup coin sesuai kebutuhan berburu promo kamu.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 14),
              const _BenefitRow(
                icon: Icons.bolt_outlined,
                text: 'Premium Mingguan: Rp9.000 untuk 7 hari',
              ),
              const SizedBox(height: 8),
              const _BenefitRow(
                icon: Icons.workspace_premium_outlined,
                text: 'Premium Bulanan: Rp29.000 untuk 30 hari',
              ),
              const SizedBox(height: 8),
              const _BenefitRow(
                icon: Icons.auto_awesome_outlined,
                text: 'Premium Semester: Rp99.000 untuk 6 bulan',
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Lihat Paket'),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<DailyClaimResult?> _showDailyRewardDialog() {
    final experience = context.read<DashboardExperienceProvider>();
    return showDialog<DailyClaimResult?>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final activeDay = experience.nextDailyDay;
        final claimedToday = experience.hasClaimedToday;
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          titlePadding: const EdgeInsets.fromLTRB(24, 18, 14, 0),
          title: Row(
            children: [
              const Expanded(child: Text('7 Day Daily')),
              IconButton(
                tooltip: 'Tutup',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                claimedToday
                    ? 'Kamu sudah klaim reward hari ini. Lanjut lagi besok.'
                    : 'Klaim reward harianmu dan lanjutkan streak sampai 7 hari.',
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(7, (index) {
                  final day = index + 1;
                  final reached = day <= experience.claimedDaysInCycle;
                  final highlighted = day == activeDay;
                  return Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: reached
                          ? const Color(0xFF0F9D58)
                          : highlighted
                              ? const Color(0xFFFFF0A8)
                              : const Color(0xFFEFF4FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '$day',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: reached
                                ? Colors.white
                                : highlighted
                                    ? const Color(0xFF7C5A00)
                                    : Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  );
                }),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: claimedToday
                    ? null
                    : () async {
                        final result = await experience.claimDailyReward();
                        if (!context.mounted) return;
                        Navigator.pop(context, result);
                      },
                child: Text(claimedToday ? 'Sudah Diklaim' : 'Claim Hari Ini'),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openPromo(PromoModel promo) async {
    final experience = context.read<DashboardExperienceProvider>();
    if (experience.isPromoLocked(promo.id)) {
      final unlocked = await _showLockedPromoDialog(promo);
      if (unlocked != true || !mounted) return;
    }
    Navigator.pushNamed(
      context,
      AppRoutes.promoDetail,
      arguments: promo,
    );
  }

  Future<bool?> _showLockedPromoDialog(PromoModel promo) {
    final pageContext = context;
    final experience = context.read<DashboardExperienceProvider>();
    final isMemberOnly = experience.isMemberOnlyPromo(promo.id);
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          titlePadding: const EdgeInsets.fromLTRB(24, 18, 14, 0),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  isMemberOnly ? 'Promo Khusus Member' : 'Promo Early Access',
                ),
              ),
              IconButton(
                tooltip: 'Tutup',
                onPressed: () => Navigator.pop(dialogContext, false),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                promo.productName,
                style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                isMemberOnly
                    ? 'Promo ini hanya bisa dibuka oleh member premium. Upgrade untuk melihat harga dan detail.'
                    : 'User gratis bisa membuka promo ini setelah ${experience.promoLockLabel(promo.id).toLowerCase()}.',
              ),
              const SizedBox(height: 14),
              _BenefitRow(
                icon: Icons.monetization_on_outlined,
                text: isMemberOnly
                    ? 'Promo member tidak bisa dibuka dengan coin.'
                    : 'Saldo coin: ${experience.coinBalance}. Butuh ${DashboardExperienceProvider.unlockCost} coin.',
              ),
              const SizedBox(height: 8),
              const _BenefitRow(
                icon: Icons.workspace_premium_outlined,
                text: 'Premium membuka semua info promo tanpa menunggu.',
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
          actions: [
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: experience.canUnlockPromoWithCoins(promo.id)
                        ? () async {
                            final ok =
                                await experience.unlockPromoWithCoins(promo.id);
                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext, ok);
                          }
                        : null,
                    child: Text(isMemberOnly ? 'Khusus Member' : 'Pakai Coin'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(dialogContext, false);
                      Navigator.pushNamed(pageContext, AppRoutes.wallet);
                    },
                    child: const Text('Langganan'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _timeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final favoriteProvider = context.watch<FavoriteProvider>();
    final promoProvider = context.watch<PromoProvider>();
    final experience = context.watch<DashboardExperienceProvider>();
    final nearbyStores = promoProvider.sortedStores.take(3).toList();
    final isLoggedIn = auth.isLoggedIn;
    final userName = auth.currentUser?.name.split(' ').first ?? 'Teman';
    final greetingPrefix = _timeBasedGreeting();
    final greeting = isLoggedIn ? '$greetingPrefix, $userName!' : 'Halo, pemburu promo!';

    // Count total savings from popular promos
    final totalPromos = promoProvider.popularPromos.length;
    final totalStores = promoProvider.sortedStores.length;
    final estimatedSavings = promoProvider.popularPromos
        .take(3)
        .fold<double>(0, (sum, p) => sum + p.savingsAmount);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: promoProvider.isLoading
          ? const LoadingWidget(message: 'Sedang memuat promo pilihan...')
          : promoProvider.errorMessage != null
              ? ErrorState(
                  title: 'Gagal memuat beranda',
                  message: promoProvider.errorMessage!,
                  onRetry: () => context.read<PromoProvider>().bootstrap(),
                )
              : CustomScrollView(
                  slivers: [
                    // ── SliverAppBar: Minimal + Hero ──
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.88),
                              Theme.of(context)
                                  .colorScheme
                                  .tertiary
                                  .withValues(alpha: 0.72),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.18),
                              blurRadius: 28,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // ── Top Bar: Greeting + Avatar ──
                            Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.35),
                                      width: 2,
                                    ),
                                  ),
                                  child: IconButton(
                                    onPressed: () => Navigator.pushNamed(
                                        context, AppRoutes.profile),
                                    icon: const Icon(
                                      Icons.person_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 42,
                                      minHeight: 42,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        greeting,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'PromoHunter',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Stack(
                                  children: [
                                    IconButton(
                                      onPressed: () {},
                                      icon: Icon(
                                        Icons.notifications_outlined,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFACC15),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // ── Hero Statement ──
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          '🔥 ${isLoggedIn ? 'Diskon pilihan untukmu' : 'Diskon pilihan hari ini'}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: Colors.white
                                                    .withOpacity(0.9),
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        estimatedSavings > 0
                                            ? 'Hemat sampai\n${CurrencyFormatter.format(estimatedSavings)}!'
                                            : 'Cari promo\nfavorit hari ini',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              height: 1.15,
                                            ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Pantau diskon, bandingkan harga, dan belanja lebih hemat.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color:
                                                  Colors.white.withOpacity(0.75),
                                              height: 1.4,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.18),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.35),
                                      width: 2,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.local_offer_rounded,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // ── Quick Actions ──
                            Row(
                              children: [
                                Expanded(
                                  child: _QuickActionButton(
                                    icon: Icons.qr_code_scanner_rounded,
                                    label: 'Scan Barcode',
                                    onTap: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Fitur scan segera hadir!'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _QuickActionButton(
                                    icon: Icons.near_me_rounded,
                                    label: 'Promo Terdekat',
                                    onTap: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Fitur lokasi segera hadir!'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Search Bar (Elevated) ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant
                                  .withOpacity(0.5),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: TextField(
                            onChanged: promoProvider.updateSearch,
                            style: Theme.of(context).textTheme.bodyMedium,
                            decoration: InputDecoration(
                              hintText: 'Cari promo, merchant, atau kategori…',
                              hintStyle: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                        .withOpacity(0.6),
                                  ),
                              prefixIcon: Padding(
                                padding:
                                    const EdgeInsets.only(left: 16, right: 8),
                                child: Icon(
                                  Icons.search_rounded,
                                  size: 22,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                              prefixIconConstraints:
                                  const BoxConstraints(minWidth: 44),
                              suffixIcon: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Filter',
                                      onPressed: () =>
                                          _showFilterSheet(context, promoProvider),
                                      icon: Icon(
                                        Icons.tune_rounded,
                                        size: 20,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                      style: IconButton.styleFrom(
                                        minimumSize: const Size(36, 36),
                                        padding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              suffixIconConstraints:
                                  const BoxConstraints(minWidth: 52),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Section: Today's Stats ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                        child: Row(
                          children: [
                            StatsCard(
                              icon: Icons.discount_rounded,
                              value: '$totalPromos',
                              label: 'Promo Aktif',
                              iconColor: Theme.of(context).colorScheme.primary,
                              backgroundColor: const Color(0xFFE8F7EE),
                            ),
                            const SizedBox(width: 10),
                            StatsCard(
                              icon: Icons.storefront_rounded,
                              value: '$totalStores',
                              label: 'Toko Tersedia',
                              iconColor:
                                  Theme.of(context).colorScheme.secondary,
                              backgroundColor: const Color(0xFFEFF4FF),
                            ),
                            const SizedBox(width: 10),
                            StatsCard(
                              icon: Icons.savings_rounded,
                              value: CurrencyFormatter.format(estimatedSavings)
                                  .split(',')
                                  .first,
                              label: 'Total Hemat',
                              iconColor: const Color(0xFFB45309),
                              backgroundColor: const Color(0xFFFFF8E1),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Rewards Hub: Premium + Daily in one ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                if (experience.isPremium)
                                  const Color(0xFFE8F7EE)
                                else
                                  const Color(0xFFFFF8E1),
                                if (experience.isPremium)
                                  const Color(0xFFD1FAE5)
                                else
                                  const Color(0xFFFFF3C4),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: experience.isPremium
                                  ? const Color(0xFF22C55E).withOpacity(0.3)
                                  : const Color(0xFFFACC15).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                // Premium section
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            experience.isPremium
                                                ? Icons.workspace_premium_rounded
                                                : Icons
                                                    .workspace_premium_outlined,
                                            size: 20,
                                            color: experience.isPremium
                                                ? const Color(0xFF0F9D58)
                                                : const Color(0xFFB45309),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            experience.isPremium
                                                ? '💎 Premium Aktif'
                                                : '💎 Premium Member',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        experience.isPremium
                                            ? 'Nikmati benefit premium-mu!'
                                            : 'Buka promo lebih awal, tanpa antri. Coin: ${experience.coinBalance}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        height: 36,
                                        child: FilledButton.tonal(
                                          onPressed: experience.isPremium
                                              ? null
                                              : () => Navigator.pushNamed(
                                                  context, AppRoutes.wallet),
                                          style: FilledButton.styleFrom(
                                            minimumSize: Size.zero,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            tapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                          child: Text(
                                            experience.isPremium
                                                ? '✓ Aktif'
                                                : '⚡ Aktifkan',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(
                                                  fontSize: 12,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 1,
                                  height: 70,
                                  color: Colors.black.withOpacity(0.08),
                                ),
                                const SizedBox(width: 12),
                                // Daily section
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            '🔥',
                                            style:
                                                const TextStyle(fontSize: 16),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Streak Day ${experience.nextDailyDay}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      // Mini streak row
                                      Row(
                                        children: List.generate(
                                          7,
                                          (index) {
                                            final day = index + 1;
                                            final reached =
                                                day <=
                                                    experience
                                                        .claimedDaysInCycle;
                                            return Container(
                                              width: 28,
                                              height: 28,
                                              margin: const EdgeInsets.only(
                                                  right: 4),
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: reached
                                                    ? const Color(0xFF0F9D58)
                                                    : const Color(0xFFEFF4FF),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '$day',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: reached
                                                          ? Colors.white
                                                          : Theme.of(context)
                                                              .colorScheme
                                                              .secondary,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 10,
                                                    ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        height: 36,
                                        child: FilledButton.tonal(
                                          onPressed: experience.hasClaimedToday
                                              ? null
                                              : () async {
                                                  final result =
                                                      await experience
                                                          .claimDailyReward();
                                                  if (!context.mounted) return;
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Day ${result.day} memberi ${result.coinsEarned} coin. 🪙',
                                                      ),
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                    ),
                                                  );
                                                },
                                          style: FilledButton.styleFrom(
                                            minimumSize: Size.zero,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            tapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                          child: Text(
                                            experience.hasClaimedToday
                                                ? '✓ Diklaim'
                                                : '🎯 Klaim',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(
                                                  fontSize: 12,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Category Chips ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 0, 0),
                        child: Stack(
                          children: [
                            SizedBox(
                              height: 44,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                clipBehavior: Clip.none,
                                padding: const EdgeInsets.only(right: 32),
                                children: promoProvider.categories.map((category) {
                                  return CategoryChip(
                                    label: category.name,
                                    icon: _categoryIcons[category.name],
                                    selected: promoProvider.selectedCategory ==
                                        category.name,
                                    onTap: () => promoProvider
                                        .updateSelectedCategory(category.name),
                                  );
                                }).toList(),
                              ),
                            ),
                            // Fade edge gradient
                            Positioned(
                              top: 0,
                              right: 0,
                              bottom: 0,
                              width: 32,
                              child: IgnorePointer(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Theme.of(context).colorScheme.surface.withOpacity(0),
                                        Theme.of(context).colorScheme.surface,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Section: Promo Populer (Horizontal) ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                        child: _SectionHeader(
                          title: 'Promo Populer',
                          actionLabel: 'Jelajahi',
                          onTap: () =>
                              Navigator.pushNamed(context, AppRoutes.promoList),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Container(
                        height: 290,
                        margin: const EdgeInsets.only(top: 8),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          clipBehavior: Clip.none,
                          itemCount: promoProvider.popularPromos.length,
                          itemBuilder: (context, index) {
                            final promo = promoProvider.popularPromos[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                right: index <
                                        promoProvider.popularPromos.length - 1
                                    ? 12
                                    : 0,
                              ),
                              child: PromoCard(
                                promo: promo.copyWith(
                                  isFavorite:
                                      favoriteProvider.isFavorite(promo.id),
                                ),
                                isLocked: experience.isPromoLocked(promo.id),
                                lockLabel: experience.promoLockLabel(promo.id),
                                onTap: () => _openPromo(promo),
                                onFavoriteTap: () {
                                  if (!auth.isLoggedIn) {
                                    Navigator.pushNamed(
                                        context, AppRoutes.login);
                                    return;
                                  }
                                  favoriteProvider.toggleFavorite(
                                      auth.currentUser!.id, promo);
                                },
                                variant: PromoCardVariant.grid,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // ── Section: Promo Hampir Berakhir ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: _SectionHeader(
                          title: 'Hampir Berakhir ⏳',
                          actionLabel: 'Lihat semua',
                          onTap: () =>
                              Navigator.pushNamed(context, AppRoutes.promoList),
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final promo = promoProvider.endingSoonPromos[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              left: 16,
                              right: 16,
                              top: index == 0 ? 8 : 0,
                            ),
                            child: PromoCard(
                              promo: promo.copyWith(
                                isFavorite:
                                    favoriteProvider.isFavorite(promo.id),
                              ),
                              isLocked: experience.isPromoLocked(promo.id),
                              lockLabel: experience.promoLockLabel(promo.id),
                              onTap: () => _openPromo(promo),
                              onFavoriteTap: () {
                                if (!auth.isLoggedIn) {
                                  Navigator.pushNamed(
                                      context, AppRoutes.login);
                                  return;
                                }
                                favoriteProvider.toggleFavorite(
                                    auth.currentUser!.id, promo);
                              },
                              variant: PromoCardVariant.list,
                            ),
                          );
                        },
                        childCount: promoProvider.endingSoonPromos
                            .take(3)
                            .length,
                      ),
                    ),

                    // ── Section: Rekomendasi ──
                    if (promoProvider.recommendedPromos.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: _SectionHeader(
                            title: 'Rekomendasi Untukmu ✨',
                            actionLabel: 'Jelajahi',
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.promoList),
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final promo =
                                promoProvider.recommendedPromos[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                left: 16,
                                right: 16,
                                top: index == 0 ? 8 : 0,
                              ),
                              child: PromoCard(
                                promo: promo.copyWith(
                                  isFavorite:
                                      favoriteProvider.isFavorite(promo.id),
                                ),
                                isLocked: experience.isPromoLocked(promo.id),
                                lockLabel: experience.promoLockLabel(promo.id),
                                onTap: () => _openPromo(promo),
                                onFavoriteTap: () {
                                  if (!auth.isLoggedIn) {
                                    Navigator.pushNamed(
                                        context, AppRoutes.login);
                                    return;
                                  }
                                  favoriteProvider.toggleFavorite(
                                    auth.currentUser!.id,
                                    promo,
                                  );
                                },
                                variant: PromoCardVariant.list,
                              ),
                            );
                          },
                          childCount:
                              promoProvider.recommendedPromos.take(3).length,
                        ),
                      ),
                    ],

                    // ── Section: Terakhir Dilihat ──
                    if (promoProvider.recentlyViewedPromos.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: _SectionHeader(
                            title: 'Terakhir Dilihat 👀',
                            actionLabel: 'Lihat promo',
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.promoList),
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final promo =
                                promoProvider.recentlyViewedPromos[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                left: 16,
                                right: 16,
                                top: index == 0 ? 8 : 0,
                              ),
                              child: PromoCard(
                                promo: promo.copyWith(
                                  isFavorite:
                                      favoriteProvider.isFavorite(promo.id),
                                ),
                                isLocked: experience.isPromoLocked(promo.id),
                                lockLabel: experience.promoLockLabel(promo.id),
                                onTap: () => _openPromo(promo),
                                onFavoriteTap: () {
                                  if (!auth.isLoggedIn) {
                                    Navigator.pushNamed(
                                        context, AppRoutes.login);
                                    return;
                                  }
                                  favoriteProvider.toggleFavorite(
                                    auth.currentUser!.id,
                                    promo,
                                  );
                                },
                                variant: PromoCardVariant.list,
                              ),
                            );
                          },
                          childCount: promoProvider.recentlyViewedPromos
                              .take(3)
                              .length,
                        ),
                      ),
                    ],

                    // ── Section: Toko Terdekat ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: _SectionHeader(
                          title: '🏪 Toko Terdekat',
                          actionLabel: 'Lihat toko',
                          onTap: () =>
                              Navigator.pushNamed(context, AppRoutes.stores),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: nearbyStores.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Text(
                                  'Toko terdekat akan muncul setelah data toko tersedia.',
                                ),
                              )
                            : SizedBox(
                                height: 230,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: nearbyStores.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 12),
                                  itemBuilder: (context, index) {
                                    final store = nearbyStores[index];
                                    return StoreCard(
                                      store: store,
                                      compact: true,
                                      distanceKm:
                                          promoProvider.distanceToStore(store),
                                      onTap: () => Navigator.pushNamed(
                                        context,
                                        AppRoutes.storeDetail,
                                        arguments: store,
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ),

                    // ── Quick Action Links (redesigned) ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _ActionChip(
                              icon: Icons.account_balance_wallet_outlined,
                              label: 'Topup Coin',
                              onTap: () => Navigator.pushNamed(
                                  context, AppRoutes.wallet),
                            ),
                            _ActionChip(
                              icon: Icons.sports_esports_outlined,
                              label: 'Mini Games',
                              onTap: () => Navigator.pushNamed(
                                  context, AppRoutes.miniGame),
                            ),
                            _ActionChip(
                              icon: Icons.campaign_outlined,
                              label: 'Tampilkan Promo',
                              onTap: () async {
                                await experience.resetEntryDialogs();
                                if (!context.mounted) return;
                                await _showEntryDialogsIfNeeded();
                              },
                            ),
                            _ActionChip(
                              icon: Icons.favorite_border_rounded,
                              label: 'Favorit',
                              onTap: () => Navigator.pushNamed(
                                  context, AppRoutes.favorites),
                            ),
                            _ActionChip(
                              icon: Icons.notifications_none_rounded,
                              label: 'Reminder',
                              onTap: () => Navigator.pushNamed(
                                  context, AppRoutes.reminders),
                            ),
                            _ActionChip(
                              icon: Icons.calculate_outlined,
                              label: 'Kalkulator',
                              onTap: () => Navigator.pushNamed(
                                  context, AppRoutes.calculator),
                            ),
                            _ActionChip(
                              icon: Icons.shopping_cart_outlined,
                              label: 'Belanja',
                              onTap: () => Navigator.pushNamed(
                                  context, AppRoutes.shoppingList),
                            ),
                            _ActionChip(
                              icon: Icons.store_mall_directory_outlined,
                              label: 'Toko',
                              onTap: () => Navigator.pushNamed(
                                  context, AppRoutes.stores),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Bottom padding ──
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 24),
                    ),
                  ],
                ),
    );
  }

  void _showFilterSheet(BuildContext context, PromoProvider promoProvider) {
    final currentCategory = promoProvider.selectedCategory;
    final categories = promoProvider.categories;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Filter Kategori',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: categories.map((cat) {
                    final selected = cat.name == currentCategory;
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_categoryIcons.containsKey(cat.name)) ...[
                            Text(
                              '${_categoryIcons[cat.name]} ',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                          Text(cat.name),
                        ],
                      ),
                      selected: selected,
                      onSelected: (_) {
                        promoProvider.updateSelectedCategory(cat.name);
                        Navigator.pop(sheetContext);
                      },
                      selectedColor:
                          Theme.of(context).colorScheme.primaryContainer,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      promoProvider.updateSelectedCategory('Semua');
                      Navigator.pop(sheetContext);
                    },
                    child: const Text('Reset Filter'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Reusable Widgets ──

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        TextButton(
          onPressed: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(actionLabel),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, size: 18),
            ],
          ),
        ),
      ],
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
      side: BorderSide(
        color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
