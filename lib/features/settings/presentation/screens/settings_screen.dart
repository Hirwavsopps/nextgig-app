import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nextgig/core/constants/app_constants.dart';
import 'package:nextgig/core/l10n/app_strings.dart';
import 'package:nextgig/core/settings/settings_cubit.dart';
import 'package:nextgig/core/theme/theme_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final language = context.watch<SettingsCubit>().state.language;
    String t(String key) => AppStrings.text(language, key);
    return Scaffold(
      appBar: AppBar(title: Text(t('settings'))),
      body: ListView(
        children: [
          ListTile(title: Text(t('theme'))),
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, mode) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('System'),
                    ),
                    ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                  ],
                  selected: {mode},
                  onSelectionChanged: (selected) =>
                      context.read<ThemeCubit>().setMode(selected.first),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          ListTile(title: Text(t('language'))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'en', label: Text('English')),
                ButtonSegment(value: 'rw', label: Text('Kinyarwanda')),
              ],
              selected: {language},
              onSelectionChanged: (selected) =>
                  context.read<SettingsCubit>().setLanguage(selected.first),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(title: Text(t('preferred_category'))),
          BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, settings) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonFormField<String?>(
                  initialValue: settings.preferredCategory,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Any'),
                    ),
                    for (final category in AppConstants.gigCategories)
                      DropdownMenuItem(value: category, child: Text(category)),
                  ],
                  onChanged: context.read<SettingsCubit>().setPreferredCategory,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
