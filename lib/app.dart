import 'package:flutter/material.dart';

import 'config/app_routes.dart';
import 'config/app_theme.dart';

class PromoHunterApp extends StatelessWidget {
  const PromoHunterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PromoHunter',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}

