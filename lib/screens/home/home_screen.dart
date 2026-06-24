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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isShowingEntryDialogs = false;

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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final favoriteProvider = context.watch<FavoriteProvider>();
    final promoProvider = context.watch<PromoProvider>();
    final experience = context.watch<DashboardExperienceProvider>();
    final nearbyStores = promoProvider.sortedStores.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              auth.isLoggedIn
                  ? 'Halo, ${auth.currentUser?.name.split(' ').first ?? 'Teman'}'
                  : 'Halo, pemburu promo',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text('PromoHunter', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
            icon: const Icon(Icons.person_outline_rounded),
          ),
        ],
      ),
      body: promoProvider.isLoading
          ? const LoadingWidget(message: 'Sedang memuat promo pilihan...')
          : promoProvider.errorMessage != null
              ? ErrorState(
                  title: 'Gagal memuat beranda',
                  message: promoProvider.errorMessage!,
                  onRetry: () => context.read<PromoProvider>().bootstrap(),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x10000000),
                            blurRadius: 24,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0A8),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Diskon pilihan hari ini',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: const Color(0xFF7C5A00),
                                  ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Cari promo apa hari ini?',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pantau diskon, bandingkan harga, dan belanja lebih hemat dari satu dashboard yang rapi.',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: const Color(0xFF64748B),
                                    ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF4FF),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${promoProvider.popularPromos.length}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primaryContainer,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'promo aktif',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0F7FF),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${nearbyStores.length}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondaryContainer,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'toko siap dikunjungi',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final premiumCard = _PremiumCard(
                          isPremium: experience.isPremium,
                          coinBalance: experience.coinBalance,
                          onActivate: experience.isPremium
                              ? null
                              : () async => Navigator.pushNamed(
                                    context,
                                    AppRoutes.wallet,
                                  ),
                        );
                        final dailyCard = _DailyCard(
                          currentDay: experience.nextDailyDay,
                          coinBalance: experience.coinBalance,
                          claimedToday: experience.hasClaimedToday,
                          onClaim: experience.hasClaimedToday
                              ? null
                              : () async {
                                  final result =
                                      await experience.claimDailyReward();
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Day ${result.day} memberi ${result.coinsEarned} coin.',
                                      ),
                                    ),
                                  );
                                },
                        );

                        if (constraints.maxWidth < 520) {
                          return Column(
                            children: [
                              premiumCard,
                              const SizedBox(height: 12),
                              dailyCard,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: premiumCard),
                            const SizedBox(width: 12),
                            Expanded(child: dailyCard),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            AppRoutes.wallet,
                          ),
                          icon:
                              const Icon(Icons.account_balance_wallet_outlined),
                          label: const Text('Topup Coin'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            AppRoutes.miniGame,
                          ),
                          icon: const Icon(Icons.sports_esports_outlined),
                          label: const Text('Mini Games'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await experience.resetEntryDialogs();
                            if (!context.mounted) return;
                            await _showEntryDialogsIfNeeded();
                          },
                          icon: const Icon(Icons.campaign_outlined),
                          label: const Text('Tampilkan Popup Promo'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      onChanged: promoProvider.updateSearch,
                      decoration: const InputDecoration(
                        hintText: 'Cari minyak, beras, susu...',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 42,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: promoProvider.categories.map((category) {
                          return CategoryChip(
                            label: category.name,
                            selected:
                                promoProvider.selectedCategory == category.name,
                            onTap: () => promoProvider
                                .updateSelectedCategory(category.name),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _SectionHeader(
                      title: 'Promo Populer',
                      actionLabel: 'Jelajahi',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.promoList),
                    ),
                    const SizedBox(height: 12),
                    ...promoProvider.popularPromos.take(3).map(
                          (promo) => PromoCard(
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
                          ),
                        ),
                    const SizedBox(height: 8),
                    _SectionHeader(
                      title: 'Promo Hampir Berakhir',
                      actionLabel: 'Lihat semua',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.promoList),
                    ),
                    const SizedBox(height: 12),
                    ...promoProvider.endingSoonPromos.take(3).map(
                          (promo) => PromoCard(
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
                          ),
                        ),
                    if (promoProvider.recommendedPromos.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _SectionHeader(
                        title: 'Rekomendasi Untuk Kamu',
                        actionLabel: 'Jelajahi',
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.promoList),
                      ),
                      const SizedBox(height: 12),
                      ...promoProvider.recommendedPromos.take(3).map(
                            (promo) => PromoCard(
                              promo: promo.copyWith(
                                isFavorite:
                                    favoriteProvider.isFavorite(promo.id),
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
                            ),
                          ),
                    ],
                    if (promoProvider.recentlyViewedPromos.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _SectionHeader(
                        title: 'Terakhir Dilihat',
                        actionLabel: 'Lihat promo',
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.promoList),
                      ),
                      const SizedBox(height: 12),
                      ...promoProvider.recentlyViewedPromos.take(3).map(
                            (promo) => PromoCard(
                              promo: promo.copyWith(
                                isFavorite:
                                    favoriteProvider.isFavorite(promo.id),
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
                            ),
                          ),
                    ],
                    const SizedBox(height: 8),
                    _SectionHeader(
                      title: 'Toko Terdekat',
                      actionLabel: 'Lihat toko',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.stores),
                    ),
                    const SizedBox(height: 12),
                    if (nearbyStores.isEmpty)
                      Container(
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
                    else
                      SizedBox(
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
                              distanceKm: promoProvider.distanceToStore(store),
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.storeDetail,
                                arguments: store,
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRoutes.favorites),
                          icon: const Icon(Icons.favorite_border_rounded),
                          label: const Text('Favorit'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRoutes.reminders),
                          icon: const Icon(Icons.notifications_none_rounded),
                          label: const Text('Reminder'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.pushNamed(
                              context, AppRoutes.calculator),
                          icon: const Icon(Icons.calculate_outlined),
                          label: const Text('Kalkulator'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.pushNamed(
                              context, AppRoutes.shoppingList),
                          icon: const Icon(Icons.shopping_cart_outlined),
                          label: const Text('Belanja'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRoutes.stores),
                          icon: const Icon(Icons.store_mall_directory_outlined),
                          label: const Text('Toko'),
                        ),
                      ],
                    ),
                  ],
                ),
    );
  }
}

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
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        TextButton(onPressed: onTap, child: Text(actionLabel)),
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

class _PremiumCard extends StatelessWidget {
  const _PremiumCard({
    required this.isPremium,
    required this.coinBalance,
    required this.onActivate,
  });

  final bool isPremium;
  final int coinBalance;
  final Future<void> Function()? onActivate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPremium ? const Color(0xFFE8F7EE) : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isPremium
                ? Icons.workspace_premium_rounded
                : Icons.workspace_premium_outlined,
            color:
                isPremium ? const Color(0xFF0F9D58) : const Color(0xFFB45309),
          ),
          const SizedBox(height: 12),
          Text(
            isPremium ? 'Premium Aktif' : 'Member Premium',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            isPremium
                ? 'Akun kamu sudah menikmati benefit member.'
                : 'Akses promo baru tanpa menunggu. Coin kamu: $coinBalance.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: onActivate == null
                ? null
                : () async {
                    await onActivate!();
                  },
            child: Text(isPremium ? 'Sudah Aktif' : 'Lihat Harga'),
          ),
        ],
      ),
    );
  }
}

class _DailyCard extends StatelessWidget {
  const _DailyCard({
    required this.currentDay,
    required this.coinBalance,
    required this.claimedToday,
    required this.onClaim,
  });

  final int currentDay;
  final int coinBalance;
  final bool claimedToday;
  final Future<void> Function()? onClaim;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.calendar_month_outlined,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 12),
          Text(
            '7 Day Daily',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            claimedToday
                ? 'Reward hari ini sudah diklaim. Saldo: $coinBalance coin.'
                : 'Claim Day $currentDay untuk menambah coin unlock promo.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: onClaim == null
                ? null
                : () async {
                    await onClaim!();
                  },
            child: Text(claimedToday ? 'Sudah Klaim' : 'Claim Day $currentDay'),
          ),
        ],
      ),
    );
  }
}
