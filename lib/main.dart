import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/supabase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/calculator_provider.dart';
import 'providers/favorite_provider.dart';
import 'providers/promo_provider.dart';
import 'providers/reminder_provider.dart';
import 'providers/shopping_list_provider.dart';
import 'services/auth_service.dart';
import 'services/category_service.dart';
import 'services/favorite_service.dart';
import 'services/notification_service.dart';
import 'services/promo_service.dart';
import 'services/reminder_service.dart';
import 'services/shopping_list_service.dart';
import 'services/store_service.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'id_ID';
  await initializeDateFormatting('id_ID');
  await NotificationService.instance.initialize();
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => PromoService()),
        Provider(create: (_) => StoreService()),
        Provider(create: (_) => CategoryService()),
        Provider(create: (_) => FavoriteService()),
        Provider(create: (_) => ReminderService()),
        Provider(create: (_) => ShoppingListService()),
        Provider(create: (_) => const SupabaseService()),
        ChangeNotifierProvider(
          create: (context) => AuthProvider(context.read<AuthService>())
            ..bootstrap(),
        ),
        ChangeNotifierProvider(
          create: (context) => PromoProvider(
            promoService: context.read<PromoService>(),
            categoryService: context.read<CategoryService>(),
            storeService: context.read<StoreService>(),
          )..bootstrap(),
        ),
        ChangeNotifierProvider(
          create: (context) => FavoriteProvider(
            context.read<FavoriteService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ReminderProvider(
            context.read<ReminderService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ShoppingListProvider(
            context.read<ShoppingListService>(),
          )..bootstrap(),
        ),
        ChangeNotifierProvider(create: (_) => CalculatorProvider()),
      ],
      child: const PromoHunterApp(),
    ),
  );
}
