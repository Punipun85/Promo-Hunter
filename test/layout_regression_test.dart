import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:promohunter/models/profile_model.dart';
import 'package:promohunter/models/store_model.dart';
import 'package:promohunter/providers/auth_provider.dart';
import 'package:promohunter/providers/calculator_provider.dart';
import 'package:promohunter/providers/dashboard_experience_provider.dart';
import 'package:promohunter/providers/favorite_provider.dart';
import 'package:promohunter/providers/promo_provider.dart';
import 'package:promohunter/providers/reminder_provider.dart';
import 'package:promohunter/providers/shopping_list_provider.dart';
import 'package:promohunter/screens/admin/admin_dashboard_screen.dart';
import 'package:promohunter/screens/admin/manage_category_screen.dart';
import 'package:promohunter/screens/admin/manage_promo_screen.dart';
import 'package:promohunter/screens/admin/manage_store_screen.dart';
import 'package:promohunter/screens/admin/payment_verification_screen.dart';
import 'package:promohunter/screens/auth/login_screen.dart';
import 'package:promohunter/screens/auth/register_screen.dart';
import 'package:promohunter/screens/calculator/price_calculator_screen.dart';
import 'package:promohunter/screens/favorite/favorite_screen.dart';
import 'package:promohunter/screens/home/home_screen.dart';
import 'package:promohunter/screens/notification/notification_screen.dart';
import 'package:promohunter/screens/promo/promo_list_screen.dart';
import 'package:promohunter/screens/profile/profile_screen.dart';
import 'package:promohunter/screens/reminder/reminder_screen.dart';
import 'package:promohunter/screens/shopping_list/shopping_list_screen.dart';
import 'package:promohunter/screens/store/store_detail_screen.dart';
import 'package:promohunter/screens/store/store_list_screen.dart';
import 'package:promohunter/screens/wallet/wallet_screen.dart';
import 'package:promohunter/services/category_service.dart';
import 'package:promohunter/services/auth_service.dart';
import 'package:promohunter/services/favorite_service.dart';
import 'package:promohunter/services/promo_service.dart';
import 'package:promohunter/services/reminder_service.dart';
import 'package:promohunter/services/shopping_list_service.dart';
import 'package:promohunter/services/store_service.dart';

void main() {
  Widget testShell(
    Widget child, {
    AuthProvider? authProvider,
    PromoProvider? promoProvider,
    FavoriteProvider? favoriteProvider,
    ReminderProvider? reminderProvider,
    ShoppingListProvider? shoppingListProvider,
    DashboardExperienceProvider? dashboardExperienceProvider,
    CalculatorProvider? calculatorProvider,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => authProvider ?? AuthProvider(AuthService()),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              promoProvider ??
              (PromoProvider(
                promoService: PromoService(),
                categoryService: CategoryService(),
                storeService: StoreService(),
              )..bootstrap()),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              favoriteProvider ?? FavoriteProvider(FavoriteService()),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              reminderProvider ?? ReminderProvider(ReminderService()),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              shoppingListProvider ??
              ShoppingListProvider(ShoppingListService()),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              dashboardExperienceProvider ?? DashboardExperienceProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => calculatorProvider ?? CalculatorProvider(),
        ),
      ],
      child: MaterialApp(home: child),
    );
  }

  Future<void> pumpNarrowScreen(
    WidgetTester tester,
    Widget child, {
    AuthProvider? authProvider,
    PromoProvider? promoProvider,
    FavoriteProvider? favoriteProvider,
    ReminderProvider? reminderProvider,
    ShoppingListProvider? shoppingListProvider,
    DashboardExperienceProvider? dashboardExperienceProvider,
    CalculatorProvider? calculatorProvider,
    Size size = const Size(320, 640),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      testShell(
        child,
        authProvider: authProvider,
        promoProvider: promoProvider,
        favoriteProvider: favoriteProvider,
        reminderProvider: reminderProvider,
        shoppingListProvider: shoppingListProvider,
        dashboardExperienceProvider: dashboardExperienceProvider,
        calculatorProvider: calculatorProvider,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    final error = tester.takeException();
    if (error != null) {
      // ignore: avoid_print
      print(error);
    }
    expect(error, isNull);
  }

  testWidgets('wallet screen renders on narrow mobile viewport',
      (tester) async {
    await pumpNarrowScreen(tester, const WalletScreen());

    expect(find.text('Topup & Langganan'), findsOneWidget);
  });

  testWidgets('home screen renders on narrow mobile viewport', (tester) async {
    await pumpNarrowScreen(tester, const HomeScreen());

    expect(find.text('PromoHunter'), findsOneWidget);
  });

  testWidgets('promo list renders on narrow mobile viewport', (tester) async {
    await pumpNarrowScreen(tester, const PromoListScreen());

    expect(find.text('Daftar Promo'), findsOneWidget);
  });

  testWidgets('store list renders on narrow mobile viewport', (tester) async {
    await pumpNarrowScreen(tester, const StoreListScreen());

    expect(find.text('Daftar Toko'), findsOneWidget);
  });

  testWidgets('store detail renders on narrow mobile viewport', (tester) async {
    const store = StoreModel(
      id: 999,
      name: 'OpenStreetMap Test Store',
      address: 'Jl. Test No. 1, Surakarta',
      city: 'Surakarta',
      googleMapsUrl:
          'https://www.openstreetmap.org/?mlat=-7.56655&mlon=110.80890#map=17/-7.56655/110.80890',
      openingHours: '08.00 - 22.00',
      latitude: -7.56655,
      longitude: 110.80890,
      activePromoCount: 2,
    );

    await pumpNarrowScreen(tester, const StoreDetailScreen(store: store));

    expect(find.text('OpenStreetMap Test Store'), findsAtLeastNWidgets(1));
  });

  testWidgets('guest profile renders on narrow mobile viewport',
      (tester) async {
    await pumpNarrowScreen(tester, const ProfileScreen());

    expect(find.text('Masuk'), findsOneWidget);
  });

  testWidgets('login screen renders on narrow mobile viewport', (tester) async {
    await pumpNarrowScreen(tester, const LoginScreen());

    expect(find.text('Masuk ke PromoHunter'), findsOneWidget);
  });

  testWidgets('favorite screen renders on narrow mobile viewport',
      (tester) async {
    await pumpNarrowScreen(tester, const FavoriteScreen());

    expect(find.text('Promo Favorit'), findsOneWidget);
  });

  testWidgets('reminder screen renders on narrow mobile viewport',
      (tester) async {
    await pumpNarrowScreen(tester, const ReminderScreen());

    expect(find.text('Reminder Promo'), findsOneWidget);
  });

  testWidgets('shopping list screen renders on narrow mobile viewport',
      (tester) async {
    await pumpNarrowScreen(tester, const ShoppingListScreen());

    expect(find.text('Daftar Belanja'), findsOneWidget);
  });

  testWidgets('register screen renders on narrow mobile viewport', (
    tester,
  ) async {
    await pumpNarrowScreen(tester, const RegisterScreen());

    expect(find.text('Buat akun baru'), findsOneWidget);
  });

  testWidgets('signed-in profile renders on narrow mobile viewport', (
    tester,
  ) async {
    final authProvider = AuthProvider(AuthService())
      ..currentUser = const ProfileModel(
        id: 'user-1',
        name: 'Samuel PromoHunter',
        email: 'samuel@example.com',
        role: 'user',
      );

    await pumpNarrowScreen(
      tester,
      const ProfileScreen(),
      authProvider: authProvider,
    );

    expect(find.text('Ringkasan Aktivitas'), findsOneWidget);
  });

  testWidgets('notification screen renders on narrow mobile viewport',
      (tester) async {
    await pumpNarrowScreen(tester, const NotificationScreen());

    expect(find.text('Notifikasi'), findsOneWidget);
  });

  testWidgets('price calculator renders on narrow mobile viewport',
      (tester) async {
    await pumpNarrowScreen(tester, const PriceCalculatorScreen());

    expect(find.text('Kalkulator Harga'), findsOneWidget);
  });

  testWidgets('admin dashboard renders on narrow mobile viewport', (
    tester,
  ) async {
    final authProvider = AuthProvider(AuthService())
      ..currentUser = const ProfileModel(
        id: 'admin-1',
        name: 'Admin PromoHunter',
        email: 'admin@example.com',
        role: 'admin',
      );

    await pumpNarrowScreen(
      tester,
      const AdminDashboardScreen(),
      authProvider: authProvider,
    );

    expect(find.text('Admin Dashboard'), findsOneWidget);
  });

  testWidgets('manage promo renders on narrow mobile viewport', (tester) async {
    await pumpNarrowScreen(tester, const ManagePromoScreen());

    expect(find.text('Kelola Promo'), findsOneWidget);
  });

  testWidgets('manage store renders on narrow mobile viewport', (tester) async {
    await pumpNarrowScreen(tester, const ManageStoreScreen());

    expect(find.text('Kelola Toko'), findsOneWidget);
  });

  testWidgets('manage category renders on narrow mobile viewport',
      (tester) async {
    await pumpNarrowScreen(tester, const ManageCategoryScreen());

    expect(find.text('Kelola Kategori'), findsOneWidget);
  });

  testWidgets('payment verification renders on narrow mobile viewport',
      (tester) async {
    final authProvider = AuthProvider(AuthService())
      ..currentUser = const ProfileModel(
        id: 'admin-2',
        name: 'Admin Payment',
        email: 'admin.payment@example.com',
        role: 'admin',
      );

    await pumpNarrowScreen(
      tester,
      const PaymentVerificationScreen(),
      authProvider: authProvider,
    );

    expect(find.text('Verifikasi Pembayaran'), findsOneWidget);
  });
}
