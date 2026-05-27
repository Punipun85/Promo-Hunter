import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/calculator_provider.dart';
import 'providers/promo_provider.dart';
import 'services/auth_service.dart';
import 'services/category_service.dart';
import 'services/notification_service.dart';
import 'services/promo_service.dart';
import 'services/store_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => PromoService()),
        Provider(create: (_) => StoreService()),
        Provider(create: (_) => CategoryService()),
        ChangeNotifierProvider(
          create: (context) => AuthProvider(context.read<AuthService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => PromoProvider(
            promoService: context.read<PromoService>(),
            categoryService: context.read<CategoryService>(),
            storeService: context.read<StoreService>(),
          )..bootstrap(),
        ),
        ChangeNotifierProvider(create: (_) => CalculatorProvider()),
      ],
      child: const PromoHunterApp(),
    ),
  );
}

