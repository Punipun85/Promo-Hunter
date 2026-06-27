import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/promo_model.dart';
import '../../models/store_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_experience_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/promo_provider.dart';
import '../../config/app_routes.dart';
import '../../services/location_service.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/promo_card.dart';
import '../../widgets/store_card.dart';
import '../../widgets/coin_banner_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Home Screen — PromoHunter v2 (Modern Startup UI — Target Design Match)
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationService _locationService = const LocationService();

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<StoreModel> _nearbyStores = [];
  bool _isLoadingStores = false;
  bool _isShowingEntryDialog = false;

  // Category icon mapping
  final Map<String, String> _categoryIcons = {
    'Semua': '🔥',
    'Travel': '️',
    'Susu': '',
    'Snack': '🍪',
    'Kesehatan': '💊',
    'Kecantikan': '💄',
    'Fashion': '👗',
    'Elektronik': '📱',
    'Makanan': '🍔',
    'Minuman': '🥤',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNearbyStores();
      _showEntryDialogsIfNeeded();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadNearbyStores() async {
    if (!mounted) return;
    setState(() => _isLoadingStores = true);
    try {
      final stores = context
          .read<PromoProvider>()
          .stores
          .where((store) => store.id != 0)
          .toList();
      if (!mounted) return;
      final userLocation = await _locationService.getCurrentLocation();
      final sorted = List<StoreModel>.from(stores)
        ..sort((a, b) {
          final distA = _calculateDistanceKm(
            userLocation.latitude,
            userLocation.longitude,
            a.latitude,
            a.longitude,
          );
          final distB = _calculateDistanceKm(
            userLocation.latitude,
            userLocation.longitude,
            b.latitude,
            b.longitude,
          );
          return distA.compareTo(distB);
        });
      setState(() {
        _nearbyStores = sorted.take(5).toList();
        _isLoadingStores = false;
      });
    } catch (e) {
      if (!mounted) return;
      final stores = context
          .read<PromoProvider>()
          .stores
          .where((store) => store.id != 0)
          .take(5)
          .toList();
      setState(() {
        _nearbyStores = stores;
        _isLoadingStores = false;
      });
    }
  }

  double _calculateDistanceKm(
    double startLatitude,
    double startLongitude,
    double? endLatitude,
    double? endLongitude,
  ) {
    if (endLatitude == null || endLongitude == null) return double.infinity;
    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(endLatitude - startLatitude);
    final dLon = _degreesToRadians(endLongitude - startLongitude);
    final lat1 = _degreesToRadians(startLatitude);
    final lat2 = _degreesToRadians(endLatitude);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) => degrees * math.pi / 180;

  Future<void> _showEntryDialogsIfNeeded() async {
    final auth = context.read<AuthProvider>();
    final experience = context.read<DashboardExperienceProvider>();
    if (!auth.isLoggedIn ||
        _isShowingEntryDialog ||
        !experience.shouldShowEntryDialogs()) {
      return;
    }

    _isShowingEntryDialog = true;
    final claimReward = !experience.hasClaimedToday;
    final actionLabel = claimReward ? 'Ambil Reward' : 'Lihat Wallet';

    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Selamat datang kembali'),
          content: Text(
            claimReward
                ? 'Reward harian kamu sudah siap. Ambil sekarang untuk menambah coin.'
                : 'Coin dan benefit premium kamu bisa dicek dari wallet.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Nanti'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(actionLabel),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (accepted == true) {
      if (claimReward) {
        final result = await experience.claimDailyReward();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Day ${result.day} memberi ${result.coinsEarned} coin.',
            ),
          ),
        );
      } else {
        Navigator.pushNamed(context, AppRoutes.wallet);
      }
    }

    await experience.markEntryDialogsShown();
    _isShowingEntryDialog = false;
  }

  void _openPromo(PromoModel promo) {
    Navigator.pushNamed(
      context,
      AppRoutes.promoDetail,
      arguments: promo,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TIME-BASED GREETING
  // ═══════════════════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════════════════
  // MAIN BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final promoProvider = context.watch<PromoProvider>();
    final favoriteProvider = context.watch<FavoriteProvider>();
    final experience = context.watch<DashboardExperienceProvider>();
    final nearbyStores = _nearbyStores;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─ Header / App Bar ──
          SliverToBoxAdapter(
            child: _buildHeader(auth),
          ),

          // Reward Balance Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: CoinBannerCard(
                coinBalance: experience.coinBalance,
                onPlayGamesPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.miniGame),
                onViewRewardsPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.wallet),
              ),
            ),
          ),

          // ─ Search Bar ──
          SliverToBoxAdapter(
            child: _buildSearchBar(promoProvider),
          ),

          // ── Stats Row ──
          SliverToBoxAdapter(
            child: _buildStatsRow(promoProvider, nearbyStores),
          ),

          // ── Category Section ──
          SliverToBoxAdapter(
            child: _buildCategorySection(promoProvider),
          ),

          // ── Premium Reward Card ──
          SliverToBoxAdapter(
            child: _buildCategoryPromoSection(
              promoProvider,
              favoriteProvider,
              experience,
              auth,
            ),
          ),

          SliverToBoxAdapter(
            child: _buildPremiumRewardCard(experience, auth),
          ),

          // ── Paling Banyak Dicari ──
          if (promoProvider.popularPromos.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                child: Text(
                  'Paling Banyak Dicari',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildTopSearchCard(
                  promoProvider.popularPromos.first,
                  favoriteProvider,
                  experience,
                  auth,
                ),
              ),
            ),
          ],

          // ── Promo Populer (Horizontal) ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Promo Populer',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E),
                      letterSpacing: -0.3,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.promoList),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Jelajahi',
                          style: TextStyle(
                            color: Color(0xFF0F7B4F),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            size: 18, color: Color(0xFF0F7B4F)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 290,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                clipBehavior: Clip.none,
                itemCount: promoProvider.popularPromos.length,
                itemBuilder: (context, index) {
                  final promo = promoProvider.popularPromos[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < promoProvider.popularPromos.length - 1
                          ? 12
                          : 0,
                    ),
                    child: PromoCard(
                      promo: promo.copyWith(
                        isFavorite: favoriteProvider.isFavorite(promo.id),
                      ),
                      isLocked: experience.isPromoLocked(promo.id),
                      lockLabel: experience.promoLockLabel(promo.id),
                      onTap: () => _openPromo(promo),
                      onFavoriteTap: () {
                        if (!auth.isLoggedIn) {
                          Navigator.pushNamed(context, AppRoutes.login);
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

          // ── Hampir Berakhir ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Hampir Berakhir ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E),
                      letterSpacing: -0.3,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.promoList),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Lihat semua',
                          style: TextStyle(
                            color: Color(0xFF0F7B4F),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            size: 18, color: Color(0xFF0F7B4F)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final promo = promoProvider.endingSoonPromos[index];
                return Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: index == 0 ? 0 : 12,
                  ),
                  child: PromoCard(
                    promo: promo.copyWith(
                      isFavorite: favoriteProvider.isFavorite(promo.id),
                    ),
                    isLocked: experience.isPromoLocked(promo.id),
                    lockLabel: experience.promoLockLabel(promo.id),
                    onTap: () => _openPromo(promo),
                    onFavoriteTap: () {
                      if (!auth.isLoggedIn) {
                        Navigator.pushNamed(context, AppRoutes.login);
                        return;
                      }
                      favoriteProvider.toggleFavorite(
                          auth.currentUser!.id, promo);
                    },
                    variant: PromoCardVariant.list,
                  ),
                );
              },
              childCount: promoProvider.endingSoonPromos.take(3).length,
            ),
          ),

          // ── Rekomendasi ──
          if (promoProvider.recommendedPromos.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rekomendasi Untukmu ✨',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A2E),
                        letterSpacing: -0.3,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.promoList),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Jelajahi',
                            style: TextStyle(
                              color: Color(0xFF0F7B4F),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              size: 18, color: Color(0xFF0F7B4F)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final promo = promoProvider.recommendedPromos[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: index == 0 ? 0 : 12,
                    ),
                    child: PromoCard(
                      promo: promo.copyWith(
                        isFavorite: favoriteProvider.isFavorite(promo.id),
                      ),
                      isLocked: experience.isPromoLocked(promo.id),
                      lockLabel: experience.promoLockLabel(promo.id),
                      onTap: () => _openPromo(promo),
                      onFavoriteTap: () {
                        if (!auth.isLoggedIn) {
                          Navigator.pushNamed(context, AppRoutes.login);
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
                childCount: promoProvider.recommendedPromos.take(3).length,
              ),
            ),
          ],

          // ── Terakhir Dilihat ──
          if (promoProvider.recentlyViewedPromos.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Terakhir Dilihat 👀',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A2E),
                        letterSpacing: -0.3,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.promoList),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Lihat promo',
                            style: TextStyle(
                              color: const Color(0xFF0F7B4F),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              size: 18, color: Color(0xFF0F7B4F)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final promo = promoProvider.recentlyViewedPromos[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: index == 0 ? 0 : 12,
                    ),
                    child: PromoCard(
                      promo: promo.copyWith(
                        isFavorite: favoriteProvider.isFavorite(promo.id),
                      ),
                      isLocked: experience.isPromoLocked(promo.id),
                      lockLabel: experience.promoLockLabel(promo.id),
                      onTap: () => _openPromo(promo),
                      onFavoriteTap: () {
                        if (!auth.isLoggedIn) {
                          Navigator.pushNamed(context, AppRoutes.login);
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
                childCount: promoProvider.recentlyViewedPromos.take(3).length,
              ),
            ),
          ],

          // ── Toko Terdekat ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Toko Terdekat',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E),
                      letterSpacing: -0.3,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.stores),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Lihat toko',
                          style: TextStyle(
                            color: Color(0xFF0F7B4F),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            size: 18, color: Color(0xFF0F7B4F)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 160,
              child: _isLoadingStores
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      clipBehavior: Clip.none,
                      itemCount: nearbyStores.length,
                      itemBuilder: (context, index) {
                        final store = nearbyStores[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            right: index < nearbyStores.length - 1 ? 12 : 0,
                          ),
                          child: StoreCard(
                            store: store,
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.storeDetail,
                              arguments: store,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),

          // ─ Bottom Padding ──
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader(AuthProvider auth) {
    final userName = auth.isLoggedIn && auth.currentUser != null
        ? (auth.currentUser!.name.isNotEmpty
            ? auth.currentUser!.name
            : 'Pemburu Promo')
        : 'Pemburu Promo';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF059669),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF059669).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, $userName!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'PromoHunter',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF065F46),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          // Notification Bell
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.wallet),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: Color(0xFF374151),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HERO CARD (Savings Card)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeroCard(
    DashboardExperienceProvider experience,
    AuthProvider auth,
    PromoProvider promoProvider,
  ) {
    final totalSavings = promoProvider.promos
        .where((promo) => !promo.isExpired)
        .fold<double>(0, (sum, promo) => sum + promo.savingsAmount);
    final formattedSavings = CurrencyFormatter.format(totalSavings);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF064E3B),
              Color(0xFF065F46),
              Color(0xFF059669),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF065F46).withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Decorative circles
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.03),
                ),
              ),
            ),
            // QR Icon (decorative, top right)
            Positioned(
              right: 20,
              top: 20,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.qr_code_2_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          'HEMAT BULAN INI',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Savings amount
                  Text(
                    formattedSavings,
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.0,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Estimasi penghematan terkumpul',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: _HeroButton(
                          icon: Icons.qr_code_scanner_rounded,
                          label: 'Scan',
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRoutes.coinRush),
                          variant: _HeroButtonVariant.dark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _HeroButton(
                          icon: Icons.near_me_rounded,
                          label: 'Terdekat',
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRoutes.stores),
                          variant: _HeroButtonVariant.light,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEARCH BAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSearchBar(PromoProvider promoProvider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Cari promo, merchant...',
                  hintStyle: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Color(0xFF9CA3AF),
                    size: 22,
                  ),
                  prefixIconConstraints: BoxConstraints(
                    minWidth: 52,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    promoProvider.updateSearch(value.trim());
                  }
                },
              ),
            ),
            // Filter button
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _showFilterSheet(context, promoProvider),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: Color(0xFF6B7280),
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATS ROW
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStatsRow(
      PromoProvider promoProvider, List<StoreModel> nearbyStores) {
    final activePromos = promoProvider.promos.where((p) => p.isActive).length;
    final availableStores = nearbyStores.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          // Active Promos Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFA7F3D0),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.confirmation_number_rounded,
                      color: Color(0xFF059669),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$activePromos',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF065F46),
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Text(
                        'PROMO AKTIF',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF059669),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Available Stores Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFBFDBFE),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Color(0xFF2563EB),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$availableStores',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E3A5F),
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Text(
                        'TOKO TERSEDIA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CATEGORY SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCategorySection(PromoProvider promoProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kategori Promo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                  letterSpacing: -0.3,
                ),
              ),
              TextButton(
                onPressed: () => _showFilterSheet(context, promoProvider),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lihat Semua',
                      style: TextStyle(
                        color: Color(0xFF0F7B4F),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 18, color: Color(0xFF0F7B4F)),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.only(left: 20, right: 32),
            children: promoProvider.categories.map((category) {
              return CategoryChip(
                label: category.name,
                icon: _categoryIcons[category.name],
                selected: _normalizeLabel(promoProvider.selectedCategory) ==
                    _normalizeLabel(category.name),
                onTap: () =>
                    promoProvider.updateSelectedCategory(category.name),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PREMIUM REWARD CARD (Simplified to match target design)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildCategoryPromoSection(
    PromoProvider promoProvider,
    FavoriteProvider favoriteProvider,
    DashboardExperienceProvider experience,
    AuthProvider auth,
  ) {
    final selectedCategory = promoProvider.selectedCategory;
    final promos = promoProvider.filteredPromos.take(5).toList();
    if (promos.isEmpty) {
      return const SizedBox.shrink();
    }

    final sectionTitle =
        selectedCategory == 'Semua' ? 'Semua Promo' : 'Promo $selectedCategory';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sectionTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                '${promos.length} item',
                style: const TextStyle(
                  color: Color(0xFF0F7B4F),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 290,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            clipBehavior: Clip.none,
            itemCount: promos.length,
            itemBuilder: (context, index) {
              final promo = promos[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < promos.length - 1 ? 12 : 0,
                ),
                child: PromoCard(
                  promo: promo.copyWith(
                    isFavorite: favoriteProvider.isFavorite(promo.id),
                  ),
                  isLocked: experience.isPromoLocked(promo.id),
                  lockLabel: experience.promoLockLabel(promo.id),
                  onTap: () => _openPromo(promo),
                  onFavoriteTap: () {
                    if (!auth.isLoggedIn) {
                      Navigator.pushNamed(context, AppRoutes.login);
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
      ],
    );
  }

  String _normalizeLabel(String value) {
    return value.trim().toLowerCase();
  }

  Widget _buildPremiumRewardCard(
      DashboardExperienceProvider experience, AuthProvider auth) {
    final isPremium = auth.isLoggedIn && experience.isPremium;
    final streak = experience.claimedDaysInCycle;
    final claimedDays = experience.claimedDaysInCycle;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: const Color(0xFFEEF2FF),
          border: Border.all(
            color: const Color(0xFFC7D2FE),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E7FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isPremium
                          ? Icons.workspace_premium_rounded
                          : Icons.stars_rounded,
                      color: const Color(0xFF4F46E5),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Premium Reward',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E1B4B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Streak indicator
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Current day dot (filled)
                      Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4F46E5),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$claimedDays',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Next day dot (outline)
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFC7D2FE),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${claimedDays + 1}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Streak Day $streak',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Description
              const Text(
                'Nikmati akses eksklusif & kumpulkan koin lebih banyak setiap hari.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4B5563),
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              // Action button
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: isPremium
                      ? () => Navigator.pushNamed(context, AppRoutes.dailySpin)
                      : () => Navigator.pushNamed(context, AppRoutes.wallet),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF065F46),
                          Color(0xFF059669),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF059669).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Aktifkan',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TOP SEARCH CARD (Paling Banyak Dicari)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTopSearchCard(
    PromoModel promo,
    FavoriteProvider favoriteProvider,
    DashboardExperienceProvider experience,
    AuthProvider auth,
  ) {
    return GestureDetector(
      onTap: () => _openPromo(promo),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 72,
                  height: 72,
                  color: const Color(0xFFF3F4F6),
                  child: promo.imageUrl.isNotEmpty
                      ? Image.network(
                          promo.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.image_rounded,
                            color: Color(0xFF9CA3AF),
                          ),
                        )
                      : const Icon(
                          Icons.image_rounded,
                          color: Color(0xFF9CA3AF),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            promo.storeName.isNotEmpty
                                ? promo.storeName
                                : promo.productName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFFA7F3D0),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'VERIFIED',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF059669),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Diskon s/d ${promo.discountPercent.toStringAsFixed(0)}% untuk produk harian',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormatter.short(promo.endDate),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FILTER SHEET
  // ═══════════════════════════════════════════════════════════════════════════

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
                    final selected = _normalizeLabel(cat.name) ==
                        _normalizeLabel(currentCategory);
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

// ═════════════════════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ═════════════════════════════════════════════════════════════════════════════

enum _HeroButtonVariant { dark, light }

class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.variant,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final _HeroButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final isDark = variant == _HeroButtonVariant.dark;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isDark
              ? Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1)
              : null,
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isDark ? Colors.white : const Color(0xFF059669),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF059669),
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
