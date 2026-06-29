import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../config/app_routes.dart';
import '../../models/category_model.dart';
import '../../models/promo_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_experience_provider.dart';
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
    final experience = context.watch<DashboardExperienceProvider>();
    if (!auth.isAdmin) {
      return const Scaffold(
        body: EmptyState(
          title: 'Akses ditolak',
          subtitle: 'Halaman ini hanya untuk admin.',
          icon: Icons.lock_outline,
        ),
      );
    }

    final realStores =
        promoProvider.stores.where((store) => store.id != 0).toList();
    final totalPromos = promoProvider.promos.length;
    final activePromos = promoProvider.promos
        .where((promo) => !promo.isExpired)
        .toList()
      ..sort((a, b) => a.endDate.compareTo(b.endDate));
    final expiredPromos = promoProvider.promos
        .where((promo) => promo.isExpired)
        .toList()
      ..sort((a, b) => b.endDate.compareTo(a.endDate));
    final endingSoonPromos = activePromos
        .where((promo) => promo.isEndingSoon)
        .toList()
      ..sort((a, b) => a.endDate.compareTo(b.endDate));
    final adminCategories = promoProvider.categories
        .where((category) => category.name != 'Semua')
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final totalCategories = adminCategories.length;
    final List<PromoModel> bestDiscountPromos = [...promoProvider.promos]
      ..sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
    final List<PromoModel> newestPromos = [...promoProvider.promos]
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    final totalPotentialSavings = activePromos.fold<double>(
      0,
      (total, promo) => total + promo.savingsAmount,
    );
    final pendingPayments = experience.pendingPaymentTransactions.length;
    final approvedPayments = experience.paymentTransactions
        .where((transaction) => transaction.status == PaymentStatus.approved)
        .length;
    final rejectedPayments = experience.paymentTransactions
        .where((transaction) => transaction.status == PaymentStatus.rejected)
        .length;
    final approvedRevenue = experience.paymentTransactions
        .where((transaction) => transaction.status == PaymentStatus.approved)
        .fold<int>(0, (total, transaction) => total + transaction.price);
    final promoCountByStore = <String, int>{};
    final promoCountByCategory = <String, int>{};
    for (final promo in activePromos) {
      promoCountByStore[promo.storeName] =
          (promoCountByStore[promo.storeName] ?? 0) + 1;
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
                    _HeroPill(
                      icon: Icons.receipt_long_outlined,
                      label: '$pendingPayments payment pending',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 360;
              return GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                crossAxisCount: 2,
                childAspectRatio: isCompact ? 0.95 : 1.2,
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
              );
            },
          ),
          const SizedBox(height: 20),
          _PromoMonitorSection(
            title: 'Promo Hampir Berakhir',
            subtitle:
                'Prioritas dicek agar tidak ada promo kedaluwarsa diam-diam.',
            promos: endingSoonPromos,
            emptyText: 'Belum ada promo yang hampir berakhir.',
            badgeColor: const Color(0xFFF59E0B),
            onManage: () =>
                Navigator.pushNamed(context, AppRoutes.managePromos),
            onEdit: (promo) => Navigator.pushNamed(
              context,
              AppRoutes.promoForm,
              arguments: promo,
            ),
          ),
          const SizedBox(height: 16),
          _PromoMonitorSection(
            title: 'Promo Aktif',
            subtitle: 'Daftar promo yang sedang tampil ke user.',
            promos: activePromos,
            emptyText: 'Belum ada promo aktif.',
            badgeColor: const Color(0xFF0F9D58),
            onManage: () =>
                Navigator.pushNamed(context, AppRoutes.managePromos),
            onEdit: (promo) => Navigator.pushNamed(
              context,
              AppRoutes.promoForm,
              arguments: promo,
            ),
          ),
          const SizedBox(height: 16),
          _PromoMonitorSection(
            title: 'Promo Expired',
            subtitle:
                'Promo yang sudah lewat masa berlaku dan perlu diarsipkan/diedit.',
            promos: expiredPromos,
            emptyText: 'Tidak ada promo expired. Rapi sekali.',
            badgeColor: const Color(0xFFDC2626),
            onManage: () =>
                Navigator.pushNamed(context, AppRoutes.managePromos),
            onEdit: (promo) => Navigator.pushNamed(
              context,
              AppRoutes.promoForm,
              arguments: promo,
            ),
          ),
          const SizedBox(height: 16),
          _CategoryMonitorSection(
            categories: adminCategories,
            promoCountByCategory: promoCountByCategory,
            onManage: () =>
                Navigator.pushNamed(context, AppRoutes.manageCategories),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 360;
              if (isCompact) {
                return Column(
                  children: [
                    _InsightCard(
                      title: 'Toko Teramai',
                      value: topStore?.key ?? 'Belum ada',
                      subtitle: topStore == null
                          ? 'Tambahkan promo untuk melihat insight.'
                          : '${topStore.value} promo aktif saat ini',
                      icon: Icons.store_mall_directory_outlined,
                    ),
                    const SizedBox(height: 12),
                    _InsightCard(
                      title: 'Kategori Populer',
                      value: topCategory?.key ?? 'Belum ada',
                      subtitle: topCategory == null
                          ? 'Belum ada kategori aktif.'
                          : '${topCategory.value} promo aktif saat ini',
                      icon: Icons.sell_outlined,
                    ),
                  ],
                );
              }
              return Row(
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
              );
            },
          ),
          const SizedBox(height: 20),
          if (bestDiscountPromos.isNotEmpty)
            _PromoHighlightCard(
              title: 'Diskon Terbesar',
              promo: bestDiscountPromos.first,
            ),
          if (bestDiscountPromos.isNotEmpty) const SizedBox(height: 12),
          if (newestPromos.isNotEmpty)
            _PromoHighlightCard(
              title: 'Promo Terbaru',
              promo: newestPromos.first,
            ),
          const SizedBox(height: 20),
          _PaymentSummarySection(
            pending: pendingPayments,
            approved: approvedPayments,
            rejected: rejectedPayments,
            approvedRevenue: approvedRevenue,
            onOpen: () =>
                Navigator.pushNamed(context, AppRoutes.paymentVerification),
          ),
          const SizedBox(height: 20),
          Text(
            'Aksi cepat admin',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.managePromos),
              icon: const Icon(Icons.local_offer_outlined),
              label: const Text('Kelola Promo'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () => Share.share(
                _buildAdminReport(
                  totalPromos: totalPromos,
                  activePromos: activePromos.length,
                  expiredPromos: expiredPromos.length,
                  endingSoonPromos: endingSoonPromos.length,
                  totalStores: realStores.length,
                  totalCategories: totalCategories,
                  pendingPayments: pendingPayments,
                  approvedPayments: approvedPayments,
                  rejectedPayments: rejectedPayments,
                  approvedRevenue: approvedRevenue,
                  topStore: topStore,
                  topCategory: topCategory,
                ),
              ),
              icon: const Icon(Icons.ios_share_outlined),
              label: const Text('Export Laporan Admin'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.paymentVerification),
              icon: const Icon(Icons.fact_check_outlined),
              label: Text(
                pendingPayments == 0
                    ? 'Verifikasi Pembayaran'
                    : 'Verifikasi Pembayaran ($pendingPayments)',
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.manageStores),
              icon: const Icon(Icons.storefront_outlined),
              label: const Text('Kelola Toko'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.manageCategories),
              icon: const Icon(Icons.category_outlined),
              label: const Text('Kelola Kategori'),
            ),
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

  String _buildAdminReport({
    required int totalPromos,
    required int activePromos,
    required int expiredPromos,
    required int endingSoonPromos,
    required int totalStores,
    required int totalCategories,
    required int pendingPayments,
    required int approvedPayments,
    required int rejectedPayments,
    required int approvedRevenue,
    required MapEntry<String, int>? topStore,
    required MapEntry<String, int>? topCategory,
  }) {
    return '''
Laporan Admin PromoHunter

Katalog:
- Total promo: $totalPromos
- Promo aktif: $activePromos
- Promo expired: $expiredPromos
- Hampir berakhir: $endingSoonPromos
- Toko aktif: $totalStores
- Kategori: $totalCategories
- Toko teramai: ${topStore == null ? 'Belum ada' : '${topStore.key} (${topStore.value} promo)'}
- Kategori populer: ${topCategory == null ? 'Belum ada' : '${topCategory.key} (${topCategory.value} promo)'}

Pembayaran:
- Menunggu verifikasi: $pendingPayments
- Berhasil: $approvedPayments
- Ditolak: $rejectedPayments
- Estimasi pemasukan: ${CurrencyFormatter.format(approvedRevenue)}
''';
  }
}

class _PaymentSummarySection extends StatelessWidget {
  const _PaymentSummarySection({
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.approvedRevenue,
    required this.onOpen,
  });

  final int pending;
  final int approved;
  final int rejected;
  final int approvedRevenue;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isCompact) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      color: Color(0xFFB45309),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ringkasan Pembayaran',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton(onPressed: onOpen, child: const Text('Verifikasi')),
              ] else
                Row(
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      color: Color(0xFFB45309),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ringkasan Pembayaran',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    TextButton(
                      onPressed: onOpen,
                      child: const Text('Verifikasi'),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniBadge(label: '$pending pending'),
                  _MiniBadge(label: '$approved berhasil'),
                  _MiniBadge(label: '$rejected ditolak'),
                  _MiniBadge(
                    label:
                        'Revenue ${CurrencyFormatter.format(approvedRevenue)}',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PromoMonitorSection extends StatelessWidget {
  const _PromoMonitorSection({
    required this.title,
    required this.subtitle,
    required this.promos,
    required this.emptyText,
    required this.badgeColor,
    required this.onManage,
    required this.onEdit,
  });

  final String title;
  final String subtitle;
  final List<PromoModel> promos;
  final String emptyText;
  final Color badgeColor;
  final VoidCallback onManage;
  final ValueChanged<PromoModel> onEdit;

  @override
  Widget build(BuildContext context) {
    final visiblePromos = promos.take(5).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
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
              if (isCompact) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF64748B),
                          ),
                    ),
                    const SizedBox(height: 10),
                    _CountBadge(
                      value: promos.length.toString(),
                      color: badgeColor,
                    ),
                  ],
                ),
              ] else
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFF64748B),
                                    ),
                          ),
                        ],
                      ),
                    ),
                    _CountBadge(
                      value: promos.length.toString(),
                      color: badgeColor,
                    ),
                  ],
                ),
              const SizedBox(height: 14),
              if (visiblePromos.isEmpty)
                Text(
                  emptyText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                )
              else
                ...visiblePromos.map(
                  (promo) => _AdminPromoTile(
                    promo: promo,
                    color: badgeColor,
                    onEdit: () => onEdit(promo),
                  ),
                ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onManage,
                  icon: const Icon(Icons.manage_search_outlined),
                  label: Text(
                    promos.length > visiblePromos.length
                        ? 'Lihat semua ${promos.length} promo'
                        : 'Buka kelola promo',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminPromoTile extends StatelessWidget {
  const _AdminPromoTile({
    required this.promo,
    required this.color,
    required this.onEdit,
  });

  final PromoModel promo;
  final Color color;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
          ),
          child: isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.local_offer_outlined,
                            color: color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                promo.productName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${promo.storeName} - ${promo.categoryName}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: const Color(0xFF64748B),
                                    ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Sampai ${DateFormatter.short(promo.endDate)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: color,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        tooltip: 'Edit promo',
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.local_offer_outlined,
                        color: color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            promo.productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${promo.storeName} - ${promo.categoryName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFF64748B),
                                    ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Sampai ${DateFormatter.short(promo.endDate)}',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit promo',
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _CategoryMonitorSection extends StatelessWidget {
  const _CategoryMonitorSection({
    required this.categories,
    required this.promoCountByCategory,
    required this.onManage,
  });

  final List<CategoryModel> categories;
  final Map<String, int> promoCountByCategory;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Kategori Promo',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              _CountBadge(
                value: categories.length.toString(),
                color: const Color(0xFF2563EB),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Pantau kategori yang tersedia dan jumlah promo aktif di dalamnya.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF64748B),
                ),
          ),
          const SizedBox(height: 14),
          if (categories.isEmpty)
            const Text('Belum ada kategori. Tambahkan kategori dulu.')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((category) {
                final count = promoCountByCategory[category.name] ?? 0;
                return Chip(
                  avatar: const Icon(Icons.category_outlined, size: 18),
                  label: Text('${category.name} ($count)'),
                );
              }).toList(),
            ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onManage,
              icon: const Icon(Icons.category_outlined),
              label: const Text('Kelola kategori'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.value,
    required this.color,
  });

  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: Container(
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
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                    ),
              ),
            ),
          ],
        ),
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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF4FF),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
              ),
        ),
      ),
    );
  }
}
