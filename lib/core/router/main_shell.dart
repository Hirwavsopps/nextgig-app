import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nextgig/core/l10n/app_strings.dart';
import 'package:nextgig/core/settings/settings_cubit.dart';

/// Bottom navigation shell (Home / Gigs / Mentors / Messages / Profile),
/// matching the Figma prototype. Each tab keeps its own navigation state.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final language = context.watch<SettingsCubit>().state.language;
    String t(String key) => AppStrings.text(language, key);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: t('nav_home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.work_outline),
            selectedIcon: const Icon(Icons.work),
            label: t('nav_gigs'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.school_outlined),
            selectedIcon: const Icon(Icons.school),
            label: t('nav_mentors'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline),
            selectedIcon: const Icon(Icons.chat_bubble),
            label: t('nav_messages'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: t('nav_profile'),
          ),
        ],
      ),
    );
  }
}
