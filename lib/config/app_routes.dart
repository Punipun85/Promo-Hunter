import 'package:flutter/material.dart';

import '../models/promo_model.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/calculator/price_calculator_screen.dart';
import '../screens/favorite/favorite_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/promo/promo_detail_screen.dart';
import '../screens/promo/promo_list_screen.dart';
import '../screens/reminder/reminder_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/store/store_list_screen.dart';

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
  static const calculator = '/calculator';
  static const stores = '/stores';
  static const admin = '/admin';
  static const profile = '/profile';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
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
      case calculator:
        return MaterialPageRoute(builder: (_) => const PriceCalculatorScreen());
      case stores:
        return MaterialPageRoute(builder: (_) => const StoreListScreen());
      case admin:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      default:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
    }
  }
}

