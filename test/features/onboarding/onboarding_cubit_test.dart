import 'package:flutter_test/flutter_test.dart';
import 'package:nextgig/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('OnboardingCubit', () {
    test('starts unseen on a fresh install', () async {
      SharedPreferences.setMockInitialValues({});
      final cubit = OnboardingCubit(await SharedPreferences.getInstance());

      expect(cubit.hasSeen, isFalse);
      await cubit.close();
    });

    test(
      'markSeen saves the flag so the next launch skips onboarding',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final cubit = OnboardingCubit(prefs);

        await cubit.markSeen();

        expect(cubit.hasSeen, isTrue);
        expect(OnboardingCubit(prefs).hasSeen, isTrue);
        await cubit.close();
      },
    );
  });

  test('OnboardingPageCubit tracks the visible slide', () async {
    final cubit = OnboardingPageCubit();
    expect(cubit.state, 0);

    cubit.show(2);

    expect(cubit.state, 2);
    await cubit.close();
  });
}
