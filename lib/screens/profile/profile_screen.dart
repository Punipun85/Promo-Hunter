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

/// ------------------------------------------------------------
/// PromoHunter - Profile Screen (Redesign)
/// UI-only refresh: same providers, same navigation, same logic.
/// Modern, clean, mobile-first, startup-style visual language.
/// ------------------------------------------------------------
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) {
      return const _GuestProfileView();
    }
    return const _SignedInProfileView();
  }
}

// ============================================================
// LOGGED-IN PROFILE
// ============================================================
class _SignedInProfileView extends StatelessWidget {
  const _SignedInProfileView();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser!;
    final favoriteProvider = context.watch<FavoriteProvider>();
    final reminderProvider = context.watch<ReminderProvider>();
    final shoppingListProvider = context.watch<ShoppingListProvider>();
    final promoProvider = context.watch<PromoProvider>();
    final experience = context.watch<DashboardExperienceProvider>();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final recentlyViewed = promoProvider.recentlyViewedPromos.take(3).toList();
    final recommended = promoProvider.recommendedPromos.take(3).toList();

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _ProfileHeaderSliver(user: user, auth: auth),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                // ---------- Stats ----------
                const _SectionLabel('Ringkasan Aktivitas'),
                const SizedBox(height: 12),
                _StatGrid(
                  favoriteProvider: favoriteProvider,
                  reminderProvider: reminderProvider,
                  shoppingListProvider: shoppingListProvider,
                  experience: experience,
                ),

                const SizedBox(height: 24),
                // ---------- Quick Actions ----------
                const _SectionLabel('Aksi Cepat'),
                const SizedBox(height: 12),
                _QuickActionsGrid(),

                const SizedBox(height: 24),
                // ---------- Account details ----------
                const _SectionLabel('Informasi Akun'),
                const SizedBox(height: 12),
                _AccountInfoCard(user: user, auth: auth),

                if (auth.isAdmin) ...[
                  const SizedBox(height: 24),
                  const _SectionLabel('Admin Tools'),
                  const SizedBox(height: 12),
                  const _AdminToolsCard(),
                ],

                const SizedBox(height: 24),
                // ---------- Recently viewed ----------
                const _SectionLabel('Terakhir Dilihat'),
                const SizedBox(height: 12),
                if (recentlyViewed.isEmpty)
                  const _InlineEmpty(
                    icon: Icons.history_rounded,
                    title: 'Belum ada aktivitas',
                    message:
                        'Promo yang baru kamu buka akan muncul di sini agar mudah ditemukan lagi.',
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

                const SizedBox(height: 24),
                // ---------- Recommendations ----------
                const _SectionLabel('Rekomendasi Untuk Kamu'),
                const SizedBox(height: 12),
                if (recommended.isEmpty)
                  const _InlineEmpty(
                    icon: Icons.auto_awesome_outlined,
                    title: 'Rekomendasi belum tersedia',
                    message:
                        'Buka beberapa promo atau simpan favorit agar rekomendasi makin personal.',
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

                const SizedBox(height: 24),
                // ---------- Logout ----------
                _LogoutButton(
                  onLogout: () async {
                    await auth.logout();
                    if (!context.mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.home,
                      (_) => false,
                    );
                  },
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'PromoHunter v1.0 • Dibuat untuk pemburu promo.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HEADER (collapsing app bar with gradient)
// ============================================================
class _ProfileHeaderSliver extends StatelessWidget {
  const _ProfileHeaderSliver({required this.user, required this.auth});

  final dynamic user;
  final AuthProvider auth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAdmin = auth.isAdmin;
    final initials = (user.name as String).isNotEmpty
        ? (user.name as String).trim().substring(0, 1).toUpperCase()
        : '?';

    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: 220,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
        background: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF22C55E), Color(0xFF2170E4)],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF22C55E).withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.45),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          initials,
                          style: theme.textTheme.headlineSmall?.copyWith(
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
                              user.name as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.email as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.88),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isAdmin
                                  ? Icons.admin_panel_settings_rounded
                                  : Icons.verified_user_rounded,
                              size: 14,
                              color: isAdmin
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF22C55E),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isAdmin ? 'Admin' : 'User',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: isAdmin
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF0F766E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Halo, ${(user.name as String).split(' ').first} 👋',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SECTION LABEL
// ============================================================
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ============================================================
// STAT GRID
// ============================================================
class _StatGrid extends StatelessWidget {
  const _StatGrid({
    required this.favoriteProvider,
    required this.reminderProvider,
    required this.shoppingListProvider,
    required this.experience,
  });

  final FavoriteProvider favoriteProvider;
  final ReminderProvider reminderProvider;
  final ShoppingListProvider shoppingListProvider;
  final DashboardExperienceProvider experience;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: width,
              child: _StatCard(
                label: 'Favorit',
                value: favoriteProvider.favoriteIds.length.toString(),
                icon: Icons.favorite_rounded,
                color: const Color(0xFFDC2626),
              ),
            ),
            SizedBox(
              width: width,
              child: _StatCard(
                label: 'Reminder',
                value: reminderProvider.reminders.length.toString(),
                icon: Icons.notifications_active_rounded,
                color: const Color(0xFFF59E0B),
              ),
            ),
            SizedBox(
              width: width,
              child: _StatCard(
                label: 'Belanja',
                value: shoppingListProvider.items.length.toString(),
                icon: Icons.shopping_cart_rounded,
                color: const Color(0xFF0F9D58),
              ),
            ),
            SizedBox(
              width: width,
              child: _StatCard(
                label: 'Coin',
                value: '${experience.coinBalance}',
                icon: Icons.toll_rounded,
                color: const Color(0xFF2563EB),
              ),
            ),
          ],
        );
      },
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              Icon(
                Icons.trending_up_rounded,
                size: 16,
                color: Colors.green.shade400,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// QUICK ACTIONS
// ============================================================
class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = <_QuickActionItem>[
      _QuickActionItem(
        icon: Icons.favorite_border_rounded,
        label: 'Favorit',
        color: const Color(0xFFDC2626),
        onTap: () => Navigator.pushNamed(context, AppRoutes.favorites),
      ),
      _QuickActionItem(
        icon: Icons.notifications_none_rounded,
        label: 'Reminder',
        color: const Color(0xFFF59E0B),
        onTap: () => Navigator.pushNamed(context, AppRoutes.reminders),
      ),
      _QuickActionItem(
        icon: Icons.shopping_cart_outlined,
        label: 'Belanja',
        color: const Color(0xFF0F9D58),
        onTap: () => Navigator.pushNamed(context, AppRoutes.shoppingList),
      ),
      _QuickActionItem(
        icon: Icons.account_balance_wallet_outlined,
        label: 'Topup Coin',
        color: const Color(0xFF2170E4),
        onTap: () => Navigator.pushNamed(context, AppRoutes.calculator),
      ),
      _QuickActionItem(
        icon: Icons.storefront_outlined,
        label: 'Toko',
        color: const Color(0xFF7C3AED),
        onTap: () => Navigator.pushNamed(context, AppRoutes.stores),
      ),
      _QuickActionItem(
        icon: Icons.account_balance_wallet_outlined,
        label: 'Topup',
        color: const Color(0xFF0EA5E9),
        onTap: () => Navigator.pushNamed(context, AppRoutes.wallet),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 24) / 4;
        return Wrap(
          spacing: 12,
          runSpacing: 14,
          children: actions
              .map(
                (action) => SizedBox(
                  width: width,
                  child: _QuickActionTile(item: action),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _QuickActionItem {
  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.item});
  final _QuickActionItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(item.icon, size: 24, color: item.color),
            ),
            const SizedBox(height: 6),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ACCOUNT INFO CARD
// ============================================================
class _AccountInfoCard extends StatelessWidget {
  const _AccountInfoCard({required this.user, required this.auth});

  final dynamic user;
  final AuthProvider auth;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
          const Divider(height: 1, indent: 56, endIndent: 20),
          _AccountRow(
            icon: Icons.email_outlined,
            title: 'Email',
            value: user.email as String,
          ),
          const Divider(height: 1, indent: 56, endIndent: 20),
          _AccountRow(
            icon: Icons.person_outline_rounded,
            title: 'Nama',
            value: user.name as String,
          ),
        ],
      ),
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ADMIN TOOLS CARD
// ============================================================
class _AdminToolsCard extends StatelessWidget {
  const _AdminToolsCard();

  @override
  Widget build(BuildContext context) {
    final tiles = <_AdminTool>[
      _AdminTool(
        icon: Icons.dashboard_rounded,
        label: 'Dashboard',
        color: const Color(0xFFDC2626),
        onTap: () => Navigator.pushNamed(context, AppRoutes.admin),
      ),
      _AdminTool(
        icon: Icons.local_offer_rounded,
        label: 'Kelola Promo',
        color: const Color(0xFFF59E0B),
        onTap: () => Navigator.pushNamed(context, AppRoutes.managePromos),
      ),
      _AdminTool(
        icon: Icons.storefront_rounded,
        label: 'Kelola Toko',
        color: const Color(0xFF2170E4),
        onTap: () => Navigator.pushNamed(context, AppRoutes.manageStores),
      ),
      _AdminTool(
        icon: Icons.category_rounded,
        label: 'Kategori',
        color: const Color(0xFF7C3AED),
        onTap: () => Navigator.pushNamed(context, AppRoutes.manageCategories),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFEE2E2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: tiles
            .map(
              (tool) => SizedBox(
                width: (MediaQuery.of(context).size.width - 40 - 12 - 32) / 2,
                child: _AdminToolTile(tool: tool),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _AdminTool {
  const _AdminTool({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

class _AdminToolTile extends StatelessWidget {
  const _AdminToolTile({required this.tool});
  final _AdminTool tool;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: tool.onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: tool.color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(tool.icon, color: tool.color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tool.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: tool.color,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: tool.color,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// INLINE EMPTY STATE
// ============================================================
class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF64748B),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// LOGOUT BUTTON
// ============================================================
class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onLogout});

  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          await onLogout();
        },
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text('Keluar'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFDC2626),
          side: const BorderSide(color: Color(0xFFFECACA)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

// ============================================================
// GUEST PROFILE
// ============================================================
class _GuestProfileView extends StatelessWidget {
  const _GuestProfileView();

  @override
  Widget build(BuildContext context) {
    final promoProvider = context.watch<PromoProvider>();
    final experience = context.watch<DashboardExperienceProvider>();
    final theme = Theme.of(context);

    final activePromoCount = promoProvider.filteredPromos.length;
    final storeCount =
        promoProvider.stores.where((store) => store.id != 0).length;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          physics: const BouncingScrollPhysics(),
          children: [
            // ---------- Hero header ----------
            _GuestHeroCard(
              promoCount: activePromoCount,
              storeCount: storeCount,
              coinBalance: experience.coinBalance,
            ),

            const SizedBox(height: 16),
            // ---------- Auth CTAs ----------
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.login),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Masuk'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.register),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Daftar'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const _SectionLabel('Benefit setelah login'),
            const SizedBox(height: 12),
            const _GuestBenefitsGrid(),

            const SizedBox(height: 24),
            const _PremiumUpsellCard(),
            const SizedBox(height: 16),
            Text(
              'Daftar gratis. Promo umum tetap bisa kamu lihat tanpa langganan.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestHeroCard extends StatelessWidget {
  const _GuestHeroCard({
    required this.promoCount,
    required this.storeCount,
    required this.coinBalance,
  });

  final int promoCount;
  final int storeCount;
  final int coinBalance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF22C55E), Color(0xFF2170E4)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.person_add_alt_1_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Akun hemat kamu belum aktif',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Masuk untuk menyimpan promo favorit, klaim daily coin, dan buka promo early access tanpa ribet.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _HeroPill(
                icon: Icons.local_offer_rounded,
                label: '$promoCount promo',
              ),
              const SizedBox(width: 8),
              _HeroPill(
                icon: Icons.storefront_rounded,
                label: '$storeCount toko',
              ),
              const SizedBox(width: 8),
              _HeroPill(
                icon: Icons.toll_rounded,
                label: '$coinBalance coin',
              ),
            ],
          ),
        ],
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestBenefitsGrid extends StatelessWidget {
  const _GuestBenefitsGrid();

  @override
  Widget build(BuildContext context) {
    final items = <_GuestBenefit>[
      const _GuestBenefit(
        icon: Icons.favorite_border_rounded,
        title: 'Favorit',
        subtitle: 'Simpan promo yang ingin kamu incar.',
        color: Color(0xFFDC2626),
      ),
      const _GuestBenefit(
        icon: Icons.notifications_none_rounded,
        title: 'Reminder',
        subtitle: 'Pengingat sebelum promo berakhir.',
        color: Color(0xFFF59E0B),
      ),
      const _GuestBenefit(
        icon: Icons.calendar_month_rounded,
        title: 'Daily Coin',
        subtitle: 'Klaim coin harian untuk buka promo.',
        color: Color(0xFF2563EB),
      ),
      const _GuestBenefit(
        icon: Icons.lock_open_rounded,
        title: 'Early Access',
        subtitle: 'Buka promo terkunci pakai coin.',
        color: Color(0xFF0F9D58),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items
              .map(
                (benefit) => SizedBox(
                  width: width,
                  child: _GuestBenefitCard(benefit: benefit),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _GuestBenefit {
  const _GuestBenefit({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
}

class _GuestBenefitCard extends StatelessWidget {
  const _GuestBenefitCard({required this.benefit});
  final _GuestBenefit benefit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: benefit.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(benefit.icon, color: benefit.color, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            benefit.title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            benefit.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF64748B),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumUpsellCard extends StatelessWidget {
  const _PremiumUpsellCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF7E0), Color(0xFFFFE9B0)],
        ),
        borderRadius: BorderRadius.circular(22),
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
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFFB45309),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Gratis pakai coin, Premium tanpa menunggu',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF7C2D12),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'User gratis bisa menunggu 6 jam atau membuka promo terkunci dengan ${DashboardExperienceProvider.unlockCost} coin. Premium mulai Rp9.000.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF7C2D12),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.wallet),
              icon: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 18,
              ),
              label: const Text('Lihat Topup & Premium'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF7C2D12),
                side: const BorderSide(color: Color(0xFFFDE68A)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
