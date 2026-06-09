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
    WidgetsBinding.instance.addPostFrameCallback((_) => _showEntryDialogsIfNeeded());
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

    final premiumAccepted = await _showPremiumDialog();
    if (!mounted) return;
    if (premiumAccepted == true) {
      await experience.enablePremium();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Member Premium aktif. Nikmati benefit promo eksklusif.'),
        ),
      );
    }

    final claimedDay = await _showDailyRewardDialog();
    if (!mounted) return;
    if (claimedDay != null) {
      final message = claimedDay == 7
          ? 'Hari ke-7 berhasil diklaim. Reward mingguan kamu lengkap.'
          : 'Daily reward hari ke-$claimedDay berhasil diklaim.';
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: const Text('Promo Bagus Hari Ini'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Nanti'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Lihat Promo'),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: const Text('Langganan Member Premium'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buka benefit tambahan untuk pengalaman berburu promo yang lebih maksimal.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 14),
              const _BenefitRow(
                icon: Icons.bolt_outlined,
                text: 'Akses promo unggulan lebih cepat',
              ),
              const SizedBox(height: 8),
              const _BenefitRow(
                icon: Icons.workspace_premium_outlined,
                text: 'Badge member premium di akun',
              ),
              const SizedBox(height: 8),
              const _BenefitRow(
                icon: Icons.auto_awesome_outlined,
                text: 'Prioritas insight promo dan reward harian',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Lewati'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Aktifkan'),
            ),
          ],
        );
      },
    );
  }

  Future<int?> _showDailyRewardDialog() {
    final experience = context.read<DashboardExperienceProvider>();
    return showDialog<int?>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final activeDay = experience.nextDailyDay;
        final claimedToday = experience.hasClaimedToday;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: const Text('7 Day Daily'),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Nanti'),
            ),
            FilledButton(
              onPressed: claimedToday
                  ? null
                  : () async {
                      final day = await experience.claimDailyReward();
                      if (!context.mounted) return;
                      Navigator.pop(context, day);
                    },
              child: Text(claimedToday ? 'Sudah Diklaim' : 'Claim Hari Ini'),
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
    final nearbyStores =
        promoProvider.stores.where((store) => store.id != 0).take(3).toList();

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
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
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
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                        style: Theme.of(context).textTheme.bodySmall,
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                        style: Theme.of(context).textTheme.bodySmall,
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
                    Row(
                      children: [
                        Expanded(
                          child: _PremiumCard(
                            isPremium: experience.isPremium,
                            onActivate: experience.isPremium
                                ? null
                                : () async {
                                    await experience.enablePremium();
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Member Premium aktif untuk akun ini.',
                                        ),
                                      ),
                                    );
                                  },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DailyCard(
                            currentDay: experience.nextDailyDay,
                            claimedToday: experience.hasClaimedToday,
                            onClaim: experience.hasClaimedToday
                                ? null
                                : () async {
                                    final day =
                                        await experience.claimDailyReward();
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Reward harian hari ke-$day berhasil diklaim.',
                                        ),
                                      ),
                                    );
                                  },
                          ),
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
                            selected: promoProvider.selectedCategory == category.name,
                            onTap: () =>
                                promoProvider.updateSelectedCategory(category.name),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _SectionHeader(
                      title: 'Promo Populer',
                      actionLabel: 'Jelajahi',
                      onTap: () => Navigator.pushNamed(context, AppRoutes.promoList),
                    ),
                    const SizedBox(height: 12),
                    ...promoProvider.popularPromos.take(3).map(
                      (promo) => PromoCard(
                        promo: promo.copyWith(
                          isFavorite: favoriteProvider.isFavorite(promo.id),
                        ),
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.promoDetail,
                          arguments: promo,
                        ),
                        onFavoriteTap: () {
                          if (!auth.isLoggedIn) {
                            Navigator.pushNamed(context, AppRoutes.login);
                            return;
                          }
                          favoriteProvider.toggleFavorite(auth.currentUser!.id, promo);
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SectionHeader(
                      title: 'Promo Hampir Berakhir',
                      actionLabel: 'Lihat semua',
                      onTap: () => Navigator.pushNamed(context, AppRoutes.promoList),
                    ),
                    const SizedBox(height: 12),
                    ...promoProvider.endingSoonPromos.take(3).map(
                      (promo) => PromoCard(
                        promo: promo.copyWith(
                          isFavorite: favoriteProvider.isFavorite(promo.id),
                        ),
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.promoDetail,
                          arguments: promo,
                        ),
                        onFavoriteTap: () {
                          if (!auth.isLoggedIn) {
                            Navigator.pushNamed(context, AppRoutes.login);
                            return;
                          }
                          favoriteProvider.toggleFavorite(auth.currentUser!.id, promo);
                        },
                      ),
                    ),
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
                            isFavorite: favoriteProvider.isFavorite(promo.id),
                          ),
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.promoDetail,
                            arguments: promo,
                          ),
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
                      onTap: () => Navigator.pushNamed(context, AppRoutes.stores),
                    ),
                    const SizedBox(height: 12),
                    if (nearbyStores.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).colorScheme.surfaceContainerHighest,
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
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final store = nearbyStores[index];
                            return StoreCard(
                              store: store,
                              compact: true,
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
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRoutes.calculator),
                          icon: const Icon(Icons.calculate_outlined),
                          label: const Text('Kalkulator'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRoutes.shoppingList),
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
    required this.onActivate,
  });

  final bool isPremium;
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
            color: isPremium ? const Color(0xFF0F9D58) : const Color(0xFFB45309),
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
                : 'Aktifkan untuk akses promo unggulan dan reward prioritas.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: onActivate == null
                ? null
                : () async {
                    await onActivate!();
                  },
            child: Text(isPremium ? 'Sudah Aktif' : 'Aktifkan'),
          ),
        ],
      ),
    );
  }
}

class _DailyCard extends StatelessWidget {
  const _DailyCard({
    required this.currentDay,
    required this.claimedToday,
    required this.onClaim,
  });

  final int currentDay;
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
                ? 'Reward hari ini sudah diklaim.'
                : 'Hari berikutnya yang bisa kamu klaim: Day $currentDay.',
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
