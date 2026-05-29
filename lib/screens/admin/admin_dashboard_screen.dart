import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../models/promo_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/promo_provider.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/empty_state.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final promoProvider = context.watch<PromoProvider>();
    if (!auth.isAdmin) {
      return const Scaffold(
        body: EmptyState(
          title: 'Akses ditolak',
          subtitle: 'Halaman ini hanya untuk admin.',
          icon: Icons.lock_outline,
        ),
      );
    }

    final realStores = promoProvider.stores.where((store) => store.id != 0).toList();
    final totalPromos = promoProvider.promos.length;
    final activePromos =
        promoProvider.promos.where((promo) => !promo.isExpired).toList();
    final expiredPromos = promoProvider.promos.where((promo) => promo.isExpired).toList();
    final endingSoonPromos =
        activePromos.where((promo) => promo.isEndingSoon).toList();
    final totalCategories = promoProvider.categories.length;
    final List<PromoModel> bestDiscountPromos = [...promoProvider.promos]
      ..sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
    final List<PromoModel> newestPromos = [...promoProvider.promos]
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    final totalPotentialSavings = activePromos.fold<double>(
      0,
      (total, promo) => total + promo.savingsAmount,
    );
    final promoCountByStore = <String, int>{};
    final promoCountByCategory = <String, int>{};
    for (final promo in activePromos) {
      promoCountByStore[promo.storeName] = (promoCountByStore[promo.storeName] ?? 0) + 1;
      promoCountByCategory[promo.categoryName] =
          (promoCountByCategory[promo.categoryName] ?? 0) + 1;
    }
    final topStore = _topEntry(promoCountByStore);
    final topCategory = _topEntry(promoCountByCategory);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ringkasan katalog PromoHunter',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.86),
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Pantau performa promo, toko, dan kategori dari satu dashboard yang ringkas.',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _HeroPill(
                      icon: Icons.local_offer_outlined,
                      label: '$totalPromos total promo',
                    ),
                    _HeroPill(
                      icon: Icons.storefront_outlined,
                      label: '${realStores.length} toko aktif',
                    ),
                    _HeroPill(
                      icon: Icons.savings_outlined,
                      label: CurrencyFormatter.format(totalPotentialSavings),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _StatCard(
                label: 'Promo Aktif',
                value: activePromos.length.toString(),
                icon: Icons.check_circle_outline,
                color: const Color(0xFF0F9D58),
              ),
              _StatCard(
                label: 'Promo Expired',
                value: expiredPromos.length.toString(),
                icon: Icons.history_toggle_off_rounded,
                color: const Color(0xFFDC2626),
              ),
              _StatCard(
                label: 'Hampir Berakhir',
                value: endingSoonPromos.length.toString(),
                icon: Icons.timer_outlined,
                color: const Color(0xFFF59E0B),
              ),
              _StatCard(
                label: 'Total Kategori',
                value: totalCategories.toString(),
                icon: Icons.category_outlined,
                color: const Color(0xFF2563EB),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _InsightCard(
                  title: 'Toko Teramai',
                  value: topStore?.key ?? 'Belum ada',
                  subtitle: topStore == null
                      ? 'Tambahkan promo untuk melihat insight.'
                      : '${topStore.value} promo aktif saat ini',
                  icon: Icons.store_mall_directory_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InsightCard(
                  title: 'Kategori Populer',
                  value: topCategory?.key ?? 'Belum ada',
                  subtitle: topCategory == null
                      ? 'Belum ada kategori aktif.'
                      : '${topCategory.value} promo aktif saat ini',
                  icon: Icons.sell_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (bestDiscountPromos.isNotEmpty)
            _PromoHighlightCard(
              title: 'Diskon Terbesar',
              promo: bestDiscountPromos.first,
            ),
          if (bestDiscountPromos.isNotEmpty)
            const SizedBox(height: 12),
          if (newestPromos.isNotEmpty)
            _PromoHighlightCard(
              title: 'Promo Terbaru',
              promo: newestPromos.first,
            ),
          const SizedBox(height: 20),
          Text(
            'Aksi cepat admin',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.managePromos),
            icon: const Icon(Icons.local_offer_outlined),
            label: const Text('Kelola Promo'),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.manageStores),
            icon: const Icon(Icons.storefront_outlined),
            label: const Text('Kelola Toko'),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.manageCategories),
            icon: const Icon(Icons.category_outlined),
            label: const Text('Kelola Kategori'),
          ),
        ],
      ),
    );
  }

  MapEntry<String, int>? _topEntry(Map<String, int> items) {
    if (items.isEmpty) return null;
    final sorted = items.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first;
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF64748B),
                ),
          ),
        ],
      ),
    );
  }
}

class _PromoHighlightCard extends StatelessWidget {
  const _PromoHighlightCard({
    required this.title,
    required this.promo,
  });

  final String title;
  final PromoModel promo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Text(
            promo.productName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '${promo.storeName} • ${promo.categoryName}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniBadge(
                label: 'Diskon ${promo.discountPercent.toStringAsFixed(0)}%',
              ),
              _MiniBadge(
                label: 'Hemat ${CurrencyFormatter.format(promo.savingsAmount)}',
              ),
              _MiniBadge(
                label: 'Sampai ${DateFormatter.short(promo.endDate)}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
            ),
      ),
    );
  }
}
