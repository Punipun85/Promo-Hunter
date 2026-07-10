import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/shopping_list_provider.dart';
import '../admin/admin_dashboard_screen.dart';
import '../favorite/favorite_screen.dart';
import '../profile/profile_screen.dart';
import '../promo/promo_list_screen.dart';
import '../wallet/wallet_screen.dart';
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<FavoriteProvider>().clear();
        context.read<ReminderProvider>().clear();
        context.read<ShoppingListProvider>().clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;
    final pages = isAdmin ? _adminPages : _userPages;
    final destinations = isAdmin ? _adminDestinations : _userDestinations;

    if (_index >= pages.length) {
      _index = pages.length - 1;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _showExitConfirmation(context);
        if (shouldExit && context.mounted) {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
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
      ),
    );
  }

  static const List<Widget> _userPages = <Widget>[
    HomeScreen(),
    PromoListScreen(),
    FavoriteScreen(),
    WalletScreen(),
    ProfileScreen(),
  ];

  static const List<Widget> _adminPages = <Widget>[
    AdminDashboardScreen(),
    ProfileScreen(),
  ];

  static const List<NavigationDestination> _userDestinations =
      <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.local_offer_outlined),
      selectedIcon: Icon(Icons.local_offer),
      label: 'Promo',
    ),
    NavigationDestination(
      icon: Icon(Icons.favorite_border),
      selectedIcon: Icon(Icons.favorite),
      label: 'Favorit',
    ),
    NavigationDestination(
      icon: Icon(Icons.account_balance_wallet_outlined),
      selectedIcon: Icon(Icons.account_balance_wallet),
      label: 'Topup',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Profil',
    ),
  ];

  static const List<NavigationDestination> _adminDestinations =
      <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.admin_panel_settings_outlined),
      selectedIcon: Icon(Icons.admin_panel_settings),
      label: 'Admin',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Profil',
    ),
  ];

  Future<bool> _showExitConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Keluar aplikasi?'),
          content: const Text(
            'Apakah Anda ingin keluar dari aplikasi PromoHunter?',
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Batal'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Keluar'),
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
