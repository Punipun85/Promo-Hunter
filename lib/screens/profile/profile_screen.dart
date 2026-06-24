import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_experience_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/promo_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/shopping_list_provider.dart';
import '../../utils/promo_access_dialog.dart';
import '../../widgets/promo_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) {
      return const _GuestProfileView();
    }

    final user = auth.currentUser!;
    final favoriteProvider = context.watch<FavoriteProvider>();
    final reminderProvider = context.watch<ReminderProvider>();
    final shoppingListProvider = context.watch<ShoppingListProvider>();
    final promoProvider = context.watch<PromoProvider>();
    final experience = context.watch<DashboardExperienceProvider>();
    final recentlyViewed = promoProvider.recentlyViewedPromos.take(3).toList();
    final recommended = promoProvider.recommendedPromos.take(3).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
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
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Text(
                        user.name.substring(0, 1).toUpperCase(),
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.86),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _HeaderBadge(
                      icon: auth.isAdmin
                          ? Icons.admin_panel_settings_outlined
                          : Icons.verified_user_outlined,
                      label: auth.isAdmin ? 'Admin' : 'User',
                    ),
                    _HeaderBadge(
                      icon: Icons.local_offer_outlined,
                      label:
                          '${promoProvider.filteredPromos.length} promo aktif',
                    ),
                    _HeaderBadge(
                      icon: Icons.visibility_outlined,
                      label:
                          '${promoProvider.recentlyViewedPromos.length} terakhir dilihat',
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
            childAspectRatio: 1.18,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _StatCard(
                title: 'Favorit',
                value: favoriteProvider.favoriteIds.length.toString(),
                icon: Icons.favorite_rounded,
                color: const Color(0xFFDC2626),
              ),
              _StatCard(
                title: 'Reminder',
                value: reminderProvider.reminders.length.toString(),
                icon: Icons.notifications_active_outlined,
                color: const Color(0xFFF59E0B),
              ),
              _StatCard(
                title: 'Belanja',
                value: shoppingListProvider.items.length.toString(),
                icon: Icons.shopping_cart_outlined,
                color: const Color(0xFF0F9D58),
              ),
              _StatCard(
                title: 'Coin',
                value: '${experience.coinBalance}',
                icon: Icons.monetization_on_outlined,
                color: const Color(0xFF2563EB),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Aksi Cepat',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuickAction(
                icon: Icons.favorite_border_rounded,
                label: 'Favorit',
                onTap: () => Navigator.pushNamed(context, AppRoutes.favorites),
              ),
              _QuickAction(
                icon: Icons.notifications_none_rounded,
                label: 'Reminder',
                onTap: () => Navigator.pushNamed(context, AppRoutes.reminders),
              ),
              _QuickAction(
                icon: Icons.shopping_cart_outlined,
                label: 'Belanja',
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.shoppingList),
              ),
              _QuickAction(
                icon: Icons.calculate_outlined,
                label: 'Kalkulator',
                onTap: () => Navigator.pushNamed(context, AppRoutes.calculator),
              ),
              _QuickAction(
                icon: Icons.storefront_outlined,
                label: 'Toko',
                onTap: () => Navigator.pushNamed(context, AppRoutes.stores),
              ),
              _QuickAction(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Topup',
                onTap: () => Navigator.pushNamed(context, AppRoutes.wallet),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Terakhir Dilihat',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (recentlyViewed.isNotEmpty)
                Text(
                  '${recentlyViewed.length} promo',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (recentlyViewed.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                'Promo yang baru kamu buka akan muncul di sini agar mudah ditemukan lagi.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            ...recentlyViewed.map(
              (promo) => PromoCard(
                promo: promo.copyWith(
                  isFavorite: favoriteProvider.isFavorite(promo.id),
                ),
                isLocked: experience.isPromoLocked(promo.id),
                lockLabel: experience.promoLockLabel(promo.id),
                onTap: () => openPromoWithAccessGuard(context, promo),
                onFavoriteTap: () => favoriteProvider.toggleFavorite(
                  user.id,
                  promo,
                ),
              ),
            ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rekomendasi Untuk Kamu',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (recommended.isNotEmpty)
                Text(
                  '${recommended.length} promo',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (recommended.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                'Buka beberapa promo atau simpan favorit agar rekomendasi makin personal.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            ...recommended.map(
              (promo) => PromoCard(
                promo: promo.copyWith(
                  isFavorite: favoriteProvider.isFavorite(promo.id),
                ),
                isLocked: experience.isPromoLocked(promo.id),
                lockLabel: experience.promoLockLabel(promo.id),
                onTap: () => openPromoWithAccessGuard(context, promo),
                onFavoriteTap: () => favoriteProvider.toggleFavorite(
                  user.id,
                  promo,
                ),
              ),
            ),
          const SizedBox(height: 20),
          if (auth.isAdmin) ...[
            Text(
              'Admin Tools',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.admin),
              icon: const Icon(Icons.admin_panel_settings_outlined),
              label: const Text('Buka Admin Dashboard'),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.managePromos),
              icon: const Icon(Icons.local_offer_outlined),
              label: const Text('Kelola Promo'),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.manageStores),
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
            const SizedBox(height: 20),
          ],
          Text(
            'Akun',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Container(
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
              children: [
                _AccountRow(
                  icon: Icons.badge_outlined,
                  title: 'Role akun',
                  value: auth.isAdmin ? 'Admin' : 'User',
                ),
                const SizedBox(height: 12),
                _AccountRow(
                  icon: Icons.email_outlined,
                  title: 'Email',
                  value: user.email,
                ),
                const SizedBox(height: 12),
                _AccountRow(
                  icon: Icons.person_outline_rounded,
                  title: 'Nama',
                  value: user.name,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              await auth.logout();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.home,
                (_) => false,
              );
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _GuestProfileView extends StatelessWidget {
  const _GuestProfileView();

  @override
  Widget build(BuildContext context) {
    final promoProvider = context.watch<PromoProvider>();
    final experience = context.watch<DashboardExperienceProvider>();
    final activePromoCount = promoProvider.filteredPromos.length;
    final storeCount =
        promoProvider.stores.where((store) => store.id != 0).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Akun hemat kamu belum aktif',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Masuk untuk menyimpan promo favorit, klaim daily coin, dan buka promo early access tanpa ribet.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _GuestHeroBadge(
                      icon: Icons.local_offer_outlined,
                      label: '$activePromoCount promo',
                    ),
                    _GuestHeroBadge(
                      icon: Icons.storefront_outlined,
                      label: '$storeCount toko',
                    ),
                    _GuestHeroBadge(
                      icon: Icons.monetization_on_outlined,
                      label: '${experience.coinBalance} coin',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.login),
                  child: const Text('Masuk'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.register),
                  child: const Text('Daftar'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'Benefit setelah login',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: 2,
            childAspectRatio: 1.05,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: const [
              _GuestBenefitCard(
                icon: Icons.favorite_border_rounded,
                title: 'Favorit',
                subtitle: 'Simpan promo yang ingin kamu incar.',
                color: Color(0xFFDC2626),
              ),
              _GuestBenefitCard(
                icon: Icons.notifications_none_rounded,
                title: 'Reminder',
                subtitle: 'Dapatkan pengingat sebelum promo habis.',
                color: Color(0xFFF59E0B),
              ),
              _GuestBenefitCard(
                icon: Icons.calendar_month_outlined,
                title: 'Daily Coin',
                subtitle: 'Klaim coin harian untuk buka promo.',
                color: Color(0xFF2563EB),
              ),
              _GuestBenefitCard(
                icon: Icons.lock_open_outlined,
                title: 'Early Access',
                subtitle: 'Buka promo terkunci pakai coin.',
                color: Color(0xFF0F9D58),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_outlined,
                        color: Color(0xFFB45309),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Gratis pakai coin, Premium tanpa menunggu',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'User gratis bisa menunggu 6 jam atau membuka promo terkunci dengan ${DashboardExperienceProvider.unlockCost} coin. Premium mulai Rp9.000.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.wallet),
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  label: const Text('Lihat Topup & Premium'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Daftar gratis. Kamu tetap bisa melihat promo umum tanpa langganan.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF64748B),
                ),
          ),
        ],
      ),
    );
  }
}

class _GuestHeroBadge extends StatelessWidget {
  const _GuestHeroBadge({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
        ],
      ),
    );
  }
}

class _GuestBenefitCard extends StatelessWidget {
  const _GuestBenefitCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF64748B),
                ),
          ),
        ],
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
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
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
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
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF64748B),
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
