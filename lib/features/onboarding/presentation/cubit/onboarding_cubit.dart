import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers whether this phone has already seen the onboarding slides.
///
/// Stored on the device (SharedPreferences), not in Firestore: it is about
/// this installation, not the user's account, and it is needed before anyone
/// has signed in.
class OnboardingCubit extends Cubit<bool> {
  OnboardingCubit(this._prefs) : super(_prefs.getBool(_key) ?? false);

  static const String _key = 'onboarding_seen';
  final SharedPreferences _prefs;

  bool get hasSeen => state;

  Future<void> markSeen() async {
    await _prefs.setBool(_key, true);
    emit(true);
  }
}

/// Which onboarding slide is showing, so the page dots and buttons rebuild
/// from a Cubit instead of setState.
class OnboardingPageCubit extends Cubit<int> {
  OnboardingPageCubit() : super(0);

  void show(int index) => emit(index);
}
