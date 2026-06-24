import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:promohunter/providers/auth_provider.dart';
import 'package:promohunter/providers/dashboard_experience_provider.dart';
import 'package:promohunter/providers/favorite_provider.dart';
import 'package:promohunter/providers/promo_provider.dart';
import 'package:promohunter/screens/home/home_screen.dart';
import 'package:promohunter/screens/promo/promo_list_screen.dart';
import 'package:promohunter/screens/profile/profile_screen.dart';
import 'package:promohunter/screens/store/store_list_screen.dart';
import 'package:promohunter/screens/wallet/wallet_screen.dart';
import 'package:promohunter/services/category_service.dart';
import 'package:promohunter/services/auth_service.dart';
import 'package:promohunter/services/favorite_service.dart';
import 'package:promohunter/services/promo_service.dart';
import 'package:promohunter/services/store_service.dart';

void main() {
  Widget testShell(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(AuthService()),
        ),
        ChangeNotifierProvider(
          create: (_) => PromoProvider(
            promoService: PromoService(),
            categoryService: CategoryService(),
            storeService: StoreService(),
          )..bootstrap(),
        ),
        ChangeNotifierProvider(
          create: (_) => FavoriteProvider(FavoriteService()),
        ),
        ChangeNotifierProvider(
          create: (_) => DashboardExperienceProvider(),
        ),
      ],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('wallet screen renders on narrow mobile viewport', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(testShell(const WalletScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Topup & Langganan'), findsOneWidget);
  });

  testWidgets('home screen renders on narrow mobile viewport', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(testShell(const HomeScreen()));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('PromoHunter'), findsOneWidget);
  });

  testWidgets('promo list renders on narrow mobile viewport', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(testShell(const PromoListScreen()));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Daftar Promo'), findsOneWidget);
  });

  testWidgets('store list renders on narrow mobile viewport', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(testShell(const StoreListScreen()));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Daftar Toko'), findsOneWidget);
  });

  testWidgets('guest profile renders on narrow mobile viewport', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(testShell(const ProfileScreen()));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Masuk'), findsOneWidget);
  });
}
