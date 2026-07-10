import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:promohunter/app.dart';
import 'package:promohunter/providers/auth_provider.dart';
import 'package:promohunter/providers/calculator_provider.dart';
import 'package:promohunter/providers/dashboard_experience_provider.dart';
import 'package:promohunter/providers/favorite_provider.dart';
import 'package:promohunter/providers/promo_provider.dart';
import 'package:promohunter/providers/reminder_provider.dart';
import 'package:promohunter/providers/shopping_list_provider.dart';
import 'package:promohunter/services/auth_service.dart';
import 'package:promohunter/services/category_service.dart';
import 'package:promohunter/services/favorite_service.dart';
import 'package:promohunter/services/promo_service.dart';
import 'package:promohunter/services/reminder_service.dart';
import 'package:promohunter/services/shopping_list_service.dart';
import 'package:promohunter/services/store_service.dart';

void main() {
  testWidgets('PromoHunter app reaches onboarding',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthProvider(AuthService())..bootstrap(),
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
            create: (_) => ReminderProvider(ReminderService()),
          ),
          ChangeNotifierProvider(
            create: (_) => ShoppingListProvider(ShoppingListService()),
          ),
          ChangeNotifierProvider(
            create: (_) => DashboardExperienceProvider()..bootstrap(),
          ),
          ChangeNotifierProvider(create: (_) => CalculatorProvider()),
        ],
        child: const PromoHunterApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Bandingkan Harga Satuan'), findsOneWidget);
  });
}
