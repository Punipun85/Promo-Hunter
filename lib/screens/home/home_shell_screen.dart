import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/shopping_list_provider.dart';
import '../calculator/price_calculator_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../favorite/favorite_screen.dart';
import '../profile/profile_screen.dart';
import '../promo/promo_list_screen.dart';
import 'home_screen.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _index = 0;
  String? _bootstrappedUserId;
  String? _refreshedUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthProvider>();
    final userId = auth.currentUser?.id;
    if (userId != null && _refreshedUserId != userId) {
      _refreshedUserId = userId;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await context.read<AuthProvider>().refreshProfile();
      });
    }
    if (userId != null && _bootstrappedUserId != userId) {
      _bootstrappedUserId = userId;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final favoriteProvider = context.read<FavoriteProvider>();
        final reminderProvider = context.read<ReminderProvider>();
        final shoppingListProvider = context.read<ShoppingListProvider>();
        await favoriteProvider.bootstrapForUser(userId);
        if (!mounted) return;
        await reminderProvider.bootstrapForUser(userId);
        if (!mounted) return;
        await shoppingListProvider.bootstrap(userId);
      });
    }
    if (userId == null && _bootstrappedUserId != null) {
      _bootstrappedUserId = null;
      _refreshedUserId = null;
      context.read<FavoriteProvider>().clear();
      context.read<ReminderProvider>().clear();
      context.read<ShoppingListProvider>().clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;
    final pages = <Widget>[
      const HomeScreen(),
      const PromoListScreen(),
      const FavoriteScreen(),
      const PriceCalculatorScreen(),
      if (isAdmin) const AdminDashboardScreen(),
      const ProfileScreen(),
    ];
    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Home',
      ),
      const NavigationDestination(
        icon: Icon(Icons.local_offer_outlined),
        selectedIcon: Icon(Icons.local_offer),
        label: 'Promo',
      ),
      const NavigationDestination(
        icon: Icon(Icons.favorite_border),
        selectedIcon: Icon(Icons.favorite),
        label: 'Favorit',
      ),
      const NavigationDestination(
        icon: Icon(Icons.calculate_outlined),
        selectedIcon: Icon(Icons.calculate),
        label: 'Kalkulator',
      ),
      if (isAdmin)
        const NavigationDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Profil',
      ),
    ];

    if (_index >= pages.length) {
      _index = pages.length - 1;
    }

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: destinations,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: const Color(0xFF059669).withValues(alpha: 0.15),
        indicatorColor: const Color(0xFF059669),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        animationDuration: const Duration(milliseconds: 500),
      ),
    );
  }
}


