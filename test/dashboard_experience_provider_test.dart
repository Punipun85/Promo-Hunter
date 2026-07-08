import 'package:flutter_test/flutter_test.dart';
import 'package:promohunter/providers/dashboard_experience_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('daily claim can only be claimed once per day', () async {
    final provider = DashboardExperienceProvider();

    final first = await provider.claimDailyReward();
    final second = await provider.claimDailyReward();

    expect(first.day, 1);
    expect(first.coinsEarned, 5);
    expect(second.day, 1);
    expect(second.coinsEarned, 0);
  });

  test('daily claim resets to day 1 after day 7 on next day', () async {
    final provider = DashboardExperienceProvider();
    provider.claimedDaysInCycle = 7;
    provider.lastClaimedAt = DateTime.now().subtract(const Duration(days: 1));

    final result = await provider.claimDailyReward();

    expect(result.day, 1);
    expect(result.coinsEarned, 5);
    expect(provider.claimedDaysInCycle, 1);
  });

  test('entry dialogs session flag can be cleared for next app entry',
      () async {
    final provider = DashboardExperienceProvider();
    provider.isReady = true;

    expect(provider.shouldShowEntryDialogs(), isTrue);

    await provider.markEntryDialogsShown();
    expect(provider.shouldShowEntryDialogs(), isFalse);

    provider.clearEntryDialogsSession();
    expect(provider.shouldShowEntryDialogs(), isTrue);
  });
}
