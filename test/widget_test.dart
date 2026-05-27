import 'package:flutter_test/flutter_test.dart';
import 'package:promohunter/app.dart';

void main() {
  testWidgets('PromoHunter app reaches onboarding', (WidgetTester tester) async {
    await tester.pumpWidget(const PromoHunterApp());
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    expect(find.text('Temukan Promo Terdekat'), findsOneWidget);
  });
}
