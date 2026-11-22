import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState extends Equatable {
  const SettingsState({this.preferredCategory, this.language = 'en'});

  final String? preferredCategory;

  /// `en` or `rw`.
  final String language;

  SettingsState copyWith({
    String? preferredCategory,
    bool clearCategory = false,
    String? language,
  }) {
    return SettingsState(
      preferredCategory: clearCategory
          ? null
          : (preferredCategory ?? this.preferredCategory),
      language: language ?? this.language,
    );
  }

  @override
  List<Object?> get props => [preferredCategory, language];
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(SharedPreferences prefs)
    : _prefs = prefs,
      super(
        SettingsState(
          preferredCategory: prefs.getString(_categoryKey),
          language: prefs.getString(_languageKey) ?? 'en',
        ),
      );

  static const _categoryKey = 'preferred_category';
  static const _languageKey = 'language';

  final SharedPreferences _prefs;

  Future<void> setPreferredCategory(String? category) async {
    if (category == null || category.isEmpty) {
      await _prefs.remove(_categoryKey);
      emit(state.copyWith(clearCategory: true));
      return;
    }
    await _prefs.setString(_categoryKey, category);
    emit(state.copyWith(preferredCategory: category));
  }

  Future<void> setLanguage(String language) async {
    final next = language == 'rw' ? 'rw' : 'en';
    await _prefs.setString(_languageKey, next);
    emit(state.copyWith(language: next));
  }
}
