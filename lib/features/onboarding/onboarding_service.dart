import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class _Keys {
  static const box = 'app_flags';
  static const onboardingDone = 'onboarding_done_v1';
}

final onboardingDoneProvider = FutureProvider<bool>((ref) async {
  final box = await _openBox();
  return box.get(_Keys.onboardingDone, defaultValue: false) as bool? ?? false;
});

Future<Box> _openBox() async => Hive.isBoxOpen(_Keys.box) ? Hive.box(_Keys.box) : await Hive.openBox(_Keys.box);

final onboardingServiceProvider = Provider<OnboardingService>((ref) => OnboardingService());

class OnboardingService {
  Future<void> setDone([bool value = true]) async {
    final box = await _openBox();
    await box.put(_Keys.onboardingDone, value);
  }
}
