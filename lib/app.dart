import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

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
      builder: (context, child) {
        return UpgradeAlert(
          upgrader: Upgrader(
            countryCode: 'ID',
            languageCode: 'id',
            debugDisplayOnce: const bool.fromEnvironment(
              'SHOW_UPGRADE_PROMPT',
            ),
            durationUntilAlertAgain: const Duration(days: 1),
            messages: PromoHunterUpgradeMessages(),
          ),
          showIgnore: false,
          showReleaseNotes: false,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

class PromoHunterUpgradeMessages extends UpgraderMessages {
  PromoHunterUpgradeMessages() : super(code: 'id');

  @override
  String? message(UpgraderMessage messageKey) {
    switch (messageKey) {
      case UpgraderMessage.title:
        return 'Update PromoHunter tersedia';
      case UpgraderMessage.body:
        return 'Versi baru {{appName}} sudah tersedia. Kamu memakai versi {{currentInstalledVersion}}, sedangkan versi terbaru adalah {{currentAppStoreVersion}}.';
      case UpgraderMessage.prompt:
        return 'Update sekarang agar fitur promo, coin, dan premium tetap berjalan optimal.';
      case UpgraderMessage.buttonTitleLater:
        return 'Nanti';
      case UpgraderMessage.buttonTitleUpdate:
        return 'Update';
      case UpgraderMessage.buttonTitleIgnore:
        return 'Abaikan';
      case UpgraderMessage.releaseNotes:
        return 'Catatan update';
    }
  }
}
