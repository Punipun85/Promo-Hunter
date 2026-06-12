import 'package:flutter/material.dart';

import '../models/promo_model.dart';
import '../models/store_model.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/manage_category_screen.dart';
import '../screens/admin/manage_promo_screen.dart';
import '../screens/admin/manage_store_screen.dart';
import '../screens/admin/promo_form_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/calculator/price_calculator_screen.dart';
import '../screens/favorite/favorite_screen.dart';
import '../screens/home/home_shell_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/promo/promo_detail_screen.dart';
import '../screens/promo/promo_list_screen.dart';
import '../screens/reminder/reminder_screen.dart';
import '../screens/shopping_list/shopping_list_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/store/store_list_screen.dart';
import '../screens/store/store_detail_screen.dart';
import '../screens/wallet/wallet_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const promoList = '/promos';
  static const promoDetail = '/promo-detail';
  static const login = '/login';
  static const register = '/register';
  static const favorites = '/favorites';
  static const reminders = '/reminders';
  static const shoppingList = '/shopping-list';
  static const calculator = '/calculator';
  static const stores = '/stores';
  static const storeDetail = '/store-detail';
  static const admin = '/admin';
  static const managePromos = '/admin/promos';
  static const manageStores = '/admin/stores';
  static const manageCategories = '/admin/categories';
  static const promoForm = '/admin/promo-form';
  static const profile = '/profile';
  static const wallet = '/wallet';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeShellScreen());
      case promoList:
        return MaterialPageRoute(builder: (_) => const PromoListScreen());
      case promoDetail:
        return MaterialPageRoute(
          builder: (_) =>
              PromoDetailScreen(promo: settings.arguments as PromoModel),
        );
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case favorites:
        return MaterialPageRoute(builder: (_) => const FavoriteScreen());
      case reminders:
        return MaterialPageRoute(builder: (_) => const ReminderScreen());
      case shoppingList:
        return MaterialPageRoute(builder: (_) => const ShoppingListScreen());
      case calculator:
        return MaterialPageRoute(builder: (_) => const PriceCalculatorScreen());
      case stores:
        return MaterialPageRoute(builder: (_) => const StoreListScreen());
      case storeDetail:
        return MaterialPageRoute(
          builder: (_) => StoreDetailScreen(
            store: settings.arguments as StoreModel,
          ),
        );
      case admin:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
      case managePromos:
        return MaterialPageRoute(builder: (_) => const ManagePromoScreen());
      case manageStores:
        return MaterialPageRoute(builder: (_) => const ManageStoreScreen());
      case manageCategories:
        return MaterialPageRoute(builder: (_) => const ManageCategoryScreen());
      case promoForm:
        return MaterialPageRoute(
          builder: (_) => PromoFormScreen(
            initialPromo: settings.arguments as PromoModel?,
          ),
        );
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case wallet:
        return MaterialPageRoute(builder: (_) => const WalletScreen());
      default:
        return MaterialPageRoute(builder: (_) => const HomeShellScreen());
    }
  }
}
