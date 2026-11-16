#!/usr/bin/env python3
"""
NextGig project scaffolder (Clean Architecture + BLoC/Cubit + get_it + go_router).

Run it from the ROOT of your Flutter project (the folder that contains pubspec.yaml),
after `flutter create .` and `flutter pub add ...`:

    python scaffold_nextgig.py              # create everything, never overwrite your files
    python scaffold_nextgig.py --dry-run    # show what would happen
    python scaffold_nextgig.py --force      # overwrite files that already exist
    python scaffold_nextgig.py --structure-only   # ONLY empty folders/files to fill in
                                                  # (no code, main.dart left untouched)

It generates: theme, router (bottom-nav shell), dependency injection, shared widgets,
the complete gig feed feature (domain / data / presentation), bookmarks cubit,
theme cubit (SharedPreferences), placeholder screens for the other members' features,
unit + widget tests, README, docs/ERD.md and a PR template.

Flutter's default counter app files (lib/main.dart, test/widget_test.dart, README.md)
are replaced automatically, because they would break the build / tests.
"""

import argparse
import re
import sys
from pathlib import Path

# --------------------------------------------------------------------------------------
# Files that `flutter create` generates and that we must replace (only if still default)
# --------------------------------------------------------------------------------------
OVERWRITE_IF_DEFAULT = {
    "lib/main.dart": "MyHomePage",
    "README.md": "A new Flutter project",
}
DELETE_IF_DEFAULT = {
    "test/widget_test.dart": "MyApp",
}

REQUIRED_PACKAGES = [
    "flutter_bloc",
    "equatable",
    "get_it",
    "go_router",
    "firebase_core",
    "firebase_auth",
    "cloud_firestore",
    "google_sign_in",
    "shared_preferences",
    "bloc_test",
    "mocktail",
]

# Feature folders owned by other members: created with data/domain/presentation sub-folders
OTHER_FEATURES = [
    "auth",
    "profile",
    "verification",
    "postings",
    "mentorship",
    "messages",
    "matching",
    "earnings",
    "settings",
]
LAYERS = ["data", "domain", "presentation"]

FILES = {}

# --------------------------------------------------------------------------------------
# lib/ entry points
# --------------------------------------------------------------------------------------
FILES["lib/main.dart"] = r"""import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:nextgig/app.dart';
import 'package:nextgig/core/di/injection.dart';
import 'package:nextgig/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await configureDependencies();

  // DEV ONLY: to fill Firestore with sample gigs, import
  // 'package:nextgig/core/utils/seed_gigs.dart' and run this ONCE, then delete it.
  // await seedSampleGigs(FirebaseFirestore.instance);

  runApp(const NextGigApp());
}
"""

FILES["lib/app.dart"] = r"""import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nextgig/core/di/injection.dart';
import 'package:nextgig/core/router/app_router.dart';
import 'package:nextgig/core/theme/app_theme.dart';
import 'package:nextgig/core/theme/theme_cubit.dart';
import 'package:nextgig/features/gigs/presentation/cubit/bookmarks_cubit.dart';

class NextGigApp extends StatelessWidget {
  const NextGigApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>.value(value: sl<ThemeCubit>()),
        BlocProvider<BookmarksCubit>.value(value: sl<BookmarksCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: 'NextGig',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}
"""

# --------------------------------------------------------------------------------------
# core/
# --------------------------------------------------------------------------------------
FILES["lib/core/di/injection.dart"] = r"""import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:nextgig/core/theme/theme_cubit.dart';
import 'package:nextgig/features/gigs/data/datasources/gig_remote_data_source.dart';
import 'package:nextgig/features/gigs/data/repositories/gig_repository_impl.dart';
import 'package:nextgig/features/gigs/domain/repositories/gig_repository.dart';
import 'package:nextgig/features/gigs/domain/usecases/watch_gigs.dart';
import 'package:nextgig/features/gigs/presentation/cubit/bookmarks_cubit.dart';
import 'package:nextgig/features/gigs/presentation/cubit/gig_feed_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service locator. Every member registers their own feature's dependencies here
/// (or in a `registerXFeature()` function called from [configureDependencies]).
final GetIt sl = GetIt.instance;

Future<void> configureDependencies() async {
  // External
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

  // Core / app-wide state
  sl.registerLazySingleton<ThemeCubit>(() => ThemeCubit(sl()));
  sl.registerLazySingleton<BookmarksCubit>(() => BookmarksCubit());

  // Feature: gigs
  sl.registerLazySingleton<GigRemoteDataSource>(
    () => GigRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<GigRepository>(() => GigRepositoryImpl(sl()));
  sl.registerLazySingleton<WatchGigs>(() => WatchGigs(sl()));
  sl.registerFactory<GigFeedCubit>(() => GigFeedCubit(sl()));
}
"""

FILES["lib/core/constants/app_constants.dart"] = r"""/// App-wide constants. Keep category / neighborhood names identical to the
/// values stored in Firestore (see docs/ERD.md).
class AppConstants {
  const AppConstants._();

  static const List<String> gigCategories = [
    'Tech',
    'Design',
    'Tutoring',
    'Photography',
    'Repair',
    'Writing',
    'Delivery',
  ];

  static const List<String> neighborhoods = [
    'Kimironko',
    'Remera',
    'Nyamirambo',
    'Kicukiro',
    'Gikondo',
    'Kacyiru',
    'Nyarutarama',
  ];

  /// Upper bound of the pay filter slider, in RWF.
  static const double maxPayFilter = 200000;
}
"""

FILES["lib/core/utils/formatters.dart"] = r"""/// Formats an amount as Rwandan francs, e.g. 25000 -> "25,000 RWF".
String formatRwf(int amount) {
  final digits = amount.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final fromEnd = digits.length - i;
    buffer.write(digits[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) {
      buffer.write(',');
    }
  }
  return '${buffer.toString()} RWF';
}
"""

FILES["lib/core/utils/seed_gigs.dart"] = r"""import 'package:cloud_firestore/cloud_firestore.dart';

/// DEV ONLY. Writes sample gigs to Firestore so the feed is not empty.
/// Works while Firestore is in test mode (or your rules allow the write).
/// Call it once from main.dart, then remove the call.
Future<void> seedSampleGigs(FirebaseFirestore firestore) async {
  final samples = <Map<String, Object?>>[
    {
      'title': 'Build a landing page for a salon',
      'description':
          'Simple 3-section responsive page with contact form and gallery.',
      'category': 'Tech',
      'neighborhood': 'Kimironko',
      'pay': 60000,
      'requiredSkills': ['HTML', 'CSS', 'Figma'],
      'posterName': 'Aline Salon',
      'posterId': 'seed-user',
    },
    {
      'title': 'Logo and brand colors for a coffee stand',
      'description': 'Need a logo, color palette and one social media template.',
      'category': 'Design',
      'neighborhood': 'Kacyiru',
      'pay': 45000,
      'requiredSkills': ['Illustrator', 'Branding'],
      'posterName': 'Kivu Beans',
      'posterId': 'seed-user',
    },
    {
      'title': 'Math tutor for S3 student',
      'description': 'Two evenings per week for one month, algebra and geometry.',
      'category': 'Tutoring',
      'neighborhood': 'Remera',
      'pay': 30000,
      'requiredSkills': ['Mathematics', 'Teaching'],
      'posterName': 'Mutesi Family',
      'posterId': 'seed-user',
    },
    {
      'title': 'Photos for a clothing collection',
      'description': 'One-day shoot, 20 edited photos for Instagram.',
      'category': 'Photography',
      'neighborhood': 'Nyamirambo',
      'pay': 80000,
      'requiredSkills': ['Photography', 'Lightroom'],
      'posterName': 'Reinna Designs',
      'posterId': 'seed-user',
    },
    {
      'title': 'Fix a laptop that will not boot',
      'description': 'Diagnose and repair, parts paid separately.',
      'category': 'Repair',
      'neighborhood': 'Kicukiro',
      'pay': 20000,
      'requiredSkills': ['Hardware', 'Troubleshooting'],
      'posterName': 'Eric M.',
      'posterId': 'seed-user',
    },
    {
      'title': 'Write product descriptions for an online shop',
      'description': '30 short descriptions in English, some in Kinyarwanda.',
      'category': 'Writing',
      'neighborhood': 'Gikondo',
      'pay': 35000,
      'requiredSkills': ['Copywriting', 'English', 'Kinyarwanda'],
      'posterName': 'Umuco Shop',
      'posterId': 'seed-user',
    },
    {
      'title': 'Flutter intern for a small booking app',
      'description': 'Help build two screens and connect them to Firebase.',
      'category': 'Tech',
      'neighborhood': 'Nyarutarama',
      'pay': 120000,
      'requiredSkills': ['Flutter', 'Firebase', 'Dart'],
      'posterName': 'BookIt Rwanda',
      'posterId': 'seed-user',
    },
    {
      'title': 'Deliver documents across town',
      'description': 'Five stops, motorbike preferred, same-day.',
      'category': 'Delivery',
      'neighborhood': 'Kimironko',
      'pay': 15000,
      'requiredSkills': ['Riding', 'Time management'],
      'posterName': 'Kigali Legal',
      'posterId': 'seed-user',
    },
  ];

  final batch = firestore.batch();
  for (final sample in samples) {
    final ref = firestore.collection('gigs').doc();
    batch.set(ref, {...sample, 'createdAt': FieldValue.serverTimestamp()});
  }
  await batch.commit();
}
"""

FILES["lib/core/theme/app_colors.dart"] = r"""import 'package:flutter/material.dart';

/// Brand colors. Replace these values with the exact hex codes from the
/// Figma file (Inspect panel) so the app matches the prototype.
/// Keep text/background pairs at a contrast ratio of at least 4.5:1.
class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF111111);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color accent = Color(0xFFBF360C);
  static const Color background = Color(0xFFF7F7F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF111111);
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFB00020);
}
"""

FILES["lib/core/theme/app_theme.dart"] = r"""import 'package:flutter/material.dart';
import 'package:nextgig/core/theme/app_colors.dart';

/// Single source of truth for look and feel. Screens must read colors and
/// text styles from Theme.of(context), never hardcode them.
class AppTheme {
  const AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.background,
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFFFFF),
          onPrimary: Color(0xFF111111),
          secondary: Color(0xFFFFAB91),
          surface: Color(0xFF1B1B1B),
          onSurface: Color(0xFFEDEDED),
          error: Color(0xFFCF6679),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
      );
}
"""

FILES["lib/core/theme/theme_cubit.dart"] = r"""import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide theme mode, persisted with SharedPreferences.
/// The settings screen (member 6) calls [setMode].
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(SharedPreferences prefs)
      : _prefs = prefs,
        super(_read(prefs));

  static const String _key = 'theme_mode';
  final SharedPreferences _prefs;

  static ThemeMode _read(SharedPreferences prefs) {
    switch (prefs.getString(_key)) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    await _prefs.setString(_key, mode.name);
    emit(mode);
  }
}
"""

FILES["lib/core/router/app_routes.dart"] = r"""/// Route paths in one place, so nobody types string paths by hand.
class AppRoutes {
  const AppRoutes._();

  static const String login = '/login';
  static const String signup = '/signup';

  static const String home = '/home';
  static const String gigs = '/gigs';
  static const String mentors = '/mentors';
  static const String messages = '/messages';
  static const String profile = '/profile';

  static const String gigDetailPattern = '/gig/:id';
  static String gigDetail(String id) => '/gig/$id';
}
"""

FILES["lib/core/router/app_router.dart"] = r"""import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nextgig/core/router/app_routes.dart';
import 'package:nextgig/core/router/main_shell.dart';
import 'package:nextgig/core/widgets/placeholder_screen.dart';
import 'package:nextgig/features/auth/presentation/screens/login_screen.dart';
import 'package:nextgig/features/auth/presentation/screens/signup_screen.dart';
import 'package:nextgig/features/gigs/domain/entities/gig.dart';
import 'package:nextgig/features/gigs/presentation/screens/gig_detail_screen.dart';
import 'package:nextgig/features/gigs/presentation/screens/gig_feed_screen.dart';
import 'package:nextgig/features/messages/presentation/screens/messages_screen.dart';
import 'package:nextgig/features/mentorship/presentation/screens/mentors_screen.dart';
import 'package:nextgig/features/postings/presentation/screens/postings_screen.dart';
import 'package:nextgig/features/profile/presentation/screens/profile_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

/// App navigation. Member 2 adds the auth redirect here once login works.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.signup,
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: AppRoutes.gigDetailPattern,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final gig = state.extra;
        if (gig is Gig) {
          return GigDetailScreen(gig: gig);
        }
        return const PlaceholderScreen(
          title: 'Gig not found',
          note: 'Open a gig from the feed.',
        );
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const GigFeedScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.gigs,
              builder: (context, state) => const PostingsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.mentors,
              builder: (context, state) => const MentorsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.messages,
              builder: (context, state) => const MessagesScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profile,
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
"""

FILES["lib/core/router/main_shell.dart"] = r"""import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bottom navigation shell (Home / Gigs / Mentors / Messages / Profile),
/// matching the Figma prototype. Each tab keeps its own navigation state.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work),
            label: 'Gigs',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Mentors',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
"""

# ---- shared widgets ----
FILES["lib/core/widgets/placeholder_screen.dart"] = r"""import 'package:flutter/material.dart';

/// Temporary screen for features that are not built yet.
/// Each member replaces the placeholder in their own feature folder.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title, required this.note});

  final String title;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(note, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
"""

FILES["lib/core/widgets/app_button.dart"] = r"""import 'package:flutter/material.dart';

/// Full-width button with a 52px height (above the 48px Material tap target).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.outlined = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    final VoidCallback? handler = isLoading ? null : onPressed;
    final Widget child = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: outlined
          ? OutlinedButton(
              onPressed: handler,
              style: OutlinedButton.styleFrom(shape: shape),
              child: child,
            )
          : FilledButton(
              onPressed: handler,
              style: FilledButton.styleFrom(shape: shape),
              child: child,
            ),
    );
  }
}
"""

FILES["lib/core/widgets/app_text_field.dart"] = r"""import 'package:flutter/material.dart';

/// Shared text field so every form (login, profile, gig posting) looks the same.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.prefixIcon,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }
}
"""

FILES["lib/core/widgets/skill_chip.dart"] = r"""import 'package:flutter/material.dart';
import 'package:nextgig/core/theme/app_colors.dart';

/// Small pill showing a skill. [verified] adds a badge (used by skill verification).
class SkillChip extends StatelessWidget {
  const SkillChip({super.key, required this.label, this.verified = false});

  final String label;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (verified) ...const [
            Icon(Icons.verified, size: 14, color: AppColors.success),
            SizedBox(width: 4),
          ],
          Text(label, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}
"""

FILES["lib/core/widgets/loading_view.dart"] = r"""import 'package:flutter/material.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
"""

FILES["lib/core/widgets/error_view.dart"] = r"""import 'package:flutter/material.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }
}
"""

FILES["lib/core/widgets/empty_view.dart"] = r"""import 'package:flutter/material.dart';

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
"""

FILES["lib/core/widgets/gig_card.dart"] = r"""import 'package:flutter/material.dart';
import 'package:nextgig/core/utils/formatters.dart';
import 'package:nextgig/core/widgets/skill_chip.dart';
import 'package:nextgig/features/gigs/domain/entities/gig.dart';

/// Card used in the gig feed (and reusable for "saved gigs", "my postings", ...).
class GigCard extends StatelessWidget {
  const GigCard({
    super.key,
    required this.gig,
    required this.isBookmarked,
    required this.onTap,
    required this.onBookmarkTap,
  });

  final Gig gig;
  final bool isBookmarked;
  final VoidCallback onTap;
  final VoidCallback onBookmarkTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final secondaryStyle = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      gig.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark gig',
                    onPressed: onBookmarkTap,
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    ),
                  ),
                ],
              ),
              Text('${gig.posterName} - ${gig.category}', style: secondaryStyle),
              const SizedBox(height: 10),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.place_outlined, size: 16),
                      const SizedBox(width: 4),
                      Text(gig.neighborhood, style: secondaryStyle),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.payments_outlined, size: 16),
                      const SizedBox(width: 4),
                      Text(formatRwf(gig.pay), style: secondaryStyle),
                    ],
                  ),
                ],
              ),
              if (gig.requiredSkills.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final skill in gig.requiredSkills.take(3))
                      SkillChip(label: skill),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
"""

# --------------------------------------------------------------------------------------
# features/gigs  (member 1's feature slice)
# --------------------------------------------------------------------------------------
FILES["lib/features/gigs/domain/entities/gig.dart"] = r"""import 'package:equatable/equatable.dart';

/// A paid gig posted by a user. Pure Dart: no Flutter or Firebase imports.
class Gig extends Equatable {
  const Gig({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.neighborhood,
    required this.pay,
    required this.requiredSkills,
    required this.posterName,
    required this.posterId,
    this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final String neighborhood;

  /// Pay in RWF.
  final int pay;
  final List<String> requiredSkills;
  final String posterName;

  /// Firebase Auth uid of the user who posted the gig.
  final String posterId;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        neighborhood,
        pay,
        requiredSkills,
        posterName,
        posterId,
        createdAt,
      ];
}
"""

FILES["lib/features/gigs/domain/entities/gig_filter.dart"] = r"""import 'package:equatable/equatable.dart';
import 'package:nextgig/features/gigs/domain/entities/gig.dart';

/// Search + filter options for the gig feed. [apply] is pure and unit tested.
class GigFilter extends Equatable {
  const GigFilter({
    this.query = '',
    this.category,
    this.neighborhood,
    this.minPay,
    this.maxPay,
  });

  final String query;
  final String? category;
  final String? neighborhood;
  final int? minPay;
  final int? maxPay;

  bool get isActive =>
      query.isNotEmpty ||
      category != null ||
      neighborhood != null ||
      minPay != null ||
      maxPay != null;

  GigFilter copyWith({
    String? query,
    String? category,
    String? neighborhood,
    int? minPay,
    int? maxPay,
    bool clearCategory = false,
    bool clearNeighborhood = false,
    bool clearPay = false,
  }) {
    return GigFilter(
      query: query ?? this.query,
      category: clearCategory ? null : (category ?? this.category),
      neighborhood:
          clearNeighborhood ? null : (neighborhood ?? this.neighborhood),
      minPay: clearPay ? null : (minPay ?? this.minPay),
      maxPay: clearPay ? null : (maxPay ?? this.maxPay),
    );
  }

  /// Returns the gigs that match every active option.
  /// Filtering happens in memory, so no composite Firestore index is needed.
  List<Gig> apply(List<Gig> gigs) {
    final text = query.trim().toLowerCase();
    final selectedCategory = category;
    final selectedNeighborhood = neighborhood;
    final lowest = minPay;
    final highest = maxPay;

    return gigs.where((gig) {
      if (selectedCategory != null && gig.category != selectedCategory) {
        return false;
      }
      if (selectedNeighborhood != null &&
          gig.neighborhood != selectedNeighborhood) {
        return false;
      }
      if (lowest != null && gig.pay < lowest) {
        return false;
      }
      if (highest != null && gig.pay > highest) {
        return false;
      }
      if (text.isEmpty) {
        return true;
      }
      final haystack =
          '${gig.title} ${gig.description} ${gig.requiredSkills.join(' ')}'
              .toLowerCase();
      return haystack.contains(text);
    }).toList();
  }

  @override
  List<Object?> get props => [query, category, neighborhood, minPay, maxPay];
}
"""

FILES["lib/features/gigs/domain/repositories/gig_repository.dart"] = r"""import 'package:nextgig/features/gigs/domain/entities/gig.dart';

/// Contract the presentation layer depends on. The data layer implements it.
abstract class GigRepository {
  /// Live list of gigs, newest first. Emits again whenever Firestore changes.
  Stream<List<Gig>> watchGigs();
}
"""

FILES["lib/features/gigs/domain/usecases/watch_gigs.dart"] = r"""import 'package:nextgig/features/gigs/domain/entities/gig.dart';
import 'package:nextgig/features/gigs/domain/repositories/gig_repository.dart';

class WatchGigs {
  const WatchGigs(this._repository);

  final GigRepository _repository;

  Stream<List<Gig>> call() => _repository.watchGigs();
}
"""

FILES["lib/features/gigs/data/models/gig_model.dart"] = r"""import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nextgig/features/gigs/domain/entities/gig.dart';

/// Firestore representation of a [Gig]. Field names must match docs/ERD.md.
class GigModel extends Gig {
  const GigModel({
    required super.id,
    required super.title,
    required super.description,
    required super.category,
    required super.neighborhood,
    required super.pay,
    required super.requiredSkills,
    required super.posterName,
    required super.posterId,
    super.createdAt,
  });

  factory GigModel.fromMap(String id, Map<String, dynamic> map) {
    final created = map['createdAt'];
    return GigModel(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'Other',
      neighborhood: map['neighborhood'] as String? ?? '',
      pay: (map['pay'] as num?)?.toInt() ?? 0,
      requiredSkills: List<String>.from(
        map['requiredSkills'] as List<dynamic>? ?? const <String>[],
      ),
      posterName: map['posterName'] as String? ?? 'Anonymous',
      posterId: map['posterId'] as String? ?? '',
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'neighborhood': neighborhood,
      'pay': pay,
      'requiredSkills': requiredSkills,
      'posterName': posterName,
      'posterId': posterId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
"""

FILES["lib/features/gigs/data/datasources/gig_remote_data_source.dart"] = r"""import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nextgig/features/gigs/data/models/gig_model.dart';

abstract class GigRemoteDataSource {
  Stream<List<GigModel>> watchGigs();
}

class GigRemoteDataSourceImpl implements GigRemoteDataSource {
  GigRemoteDataSourceImpl(this._firestore);

  final FirebaseFirestore _firestore;

  /// Note: documents without a `createdAt` field are excluded by orderBy.
  @override
  Stream<List<GigModel>> watchGigs() {
    return _firestore
        .collection('gigs')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GigModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }
}
"""

FILES["lib/features/gigs/data/repositories/gig_repository_impl.dart"] = r"""import 'package:nextgig/features/gigs/data/datasources/gig_remote_data_source.dart';
import 'package:nextgig/features/gigs/domain/entities/gig.dart';
import 'package:nextgig/features/gigs/domain/repositories/gig_repository.dart';

class GigRepositoryImpl implements GigRepository {
  GigRepositoryImpl(this._remote);

  final GigRemoteDataSource _remote;

  @override
  Stream<List<Gig>> watchGigs() => _remote.watchGigs();
}
"""

FILES["lib/features/gigs/presentation/cubit/gig_feed_state.dart"] = r"""import 'package:equatable/equatable.dart';
import 'package:nextgig/features/gigs/domain/entities/gig.dart';
import 'package:nextgig/features/gigs/domain/entities/gig_filter.dart';

enum GigFeedStatus { initial, loading, loaded, failure }

class GigFeedState extends Equatable {
  const GigFeedState({
    this.status = GigFeedStatus.initial,
    this.allGigs = const [],
    this.filter = const GigFilter(),
    this.errorMessage,
  });

  final GigFeedStatus status;
  final List<Gig> allGigs;
  final GigFilter filter;
  final String? errorMessage;

  /// Gigs after search and filters are applied.
  List<Gig> get visibleGigs => filter.apply(allGigs);

  GigFeedState copyWith({
    GigFeedStatus? status,
    List<Gig>? allGigs,
    GigFilter? filter,
    String? errorMessage,
  }) {
    return GigFeedState(
      status: status ?? this.status,
      allGigs: allGigs ?? this.allGigs,
      filter: filter ?? this.filter,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, allGigs, filter, errorMessage];
}
"""

FILES["lib/features/gigs/presentation/cubit/gig_feed_cubit.dart"] = r"""import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nextgig/features/gigs/domain/entities/gig.dart';
import 'package:nextgig/features/gigs/domain/entities/gig_filter.dart';
import 'package:nextgig/features/gigs/domain/usecases/watch_gigs.dart';
import 'package:nextgig/features/gigs/presentation/cubit/gig_feed_state.dart';

/// Holds the live gig list plus the active search/filter.
/// Because it listens to a Firestore stream, new gigs appear without a refresh.
class GigFeedCubit extends Cubit<GigFeedState> {
  GigFeedCubit(this._watchGigs) : super(const GigFeedState());

  final WatchGigs _watchGigs;
  StreamSubscription<List<Gig>>? _subscription;

  void start() {
    emit(state.copyWith(status: GigFeedStatus.loading));
    _subscription?.cancel();
    _subscription = _watchGigs().listen(
      (gigs) => emit(
        state.copyWith(status: GigFeedStatus.loaded, allGigs: gigs),
      ),
      onError: (Object error) => emit(
        state.copyWith(
          status: GigFeedStatus.failure,
          errorMessage: 'Could not load gigs. Please try again.',
        ),
      ),
    );
  }

  void search(String query) {
    emit(state.copyWith(filter: state.filter.copyWith(query: query)));
  }

  void updateFilter(GigFilter filter) {
    emit(state.copyWith(filter: filter));
  }

  void clearFilters() {
    emit(state.copyWith(filter: const GigFilter()));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
"""

FILES["lib/features/gigs/presentation/cubit/bookmarks_cubit.dart"] = r"""import 'package:flutter_bloc/flutter_bloc.dart';

/// Ids of bookmarked gigs. App-wide, so the heart on a gig card AND the
/// saved-count badge in the app bar update from the same state change
/// (this is the "one state update touching two widgets" demo).
class BookmarksCubit extends Cubit<Set<String>> {
  BookmarksCubit() : super(const <String>{});

  void toggle(String gigId) {
    final updated = Set<String>.of(state);
    if (!updated.remove(gigId)) {
      updated.add(gigId);
    }
    emit(updated);
  }
}
"""

FILES["lib/features/gigs/presentation/screens/gig_feed_screen.dart"] = r"""import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nextgig/core/di/injection.dart';
import 'package:nextgig/core/router/app_routes.dart';
import 'package:nextgig/core/widgets/empty_view.dart';
import 'package:nextgig/core/widgets/error_view.dart';
import 'package:nextgig/core/widgets/gig_card.dart';
import 'package:nextgig/core/widgets/loading_view.dart';
import 'package:nextgig/features/gigs/presentation/cubit/bookmarks_cubit.dart';
import 'package:nextgig/features/gigs/presentation/cubit/gig_feed_cubit.dart';
import 'package:nextgig/features/gigs/presentation/cubit/gig_feed_state.dart';
import 'package:nextgig/features/gigs/presentation/widgets/filter_sheet.dart';

class GigFeedScreen extends StatelessWidget {
  const GigFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GigFeedCubit>(
      create: (_) => sl<GigFeedCubit>()..start(),
      child: const _GigFeedView(),
    );
  }
}

class _GigFeedView extends StatelessWidget {
  const _GigFeedView();

  void _openFilters(BuildContext context) {
    final cubit = context.read<GigFeedCubit>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => BlocProvider<GigFeedCubit>.value(
        value: cubit,
        child: const FilterSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gigs near you'),
        actions: [
          BlocBuilder<BookmarksCubit, Set<String>>(
            builder: (context, saved) {
              return IconButton(
                tooltip: 'Saved gigs',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${saved.length} saved gigs')),
                  );
                },
                icon: Badge(
                  isLabelVisible: saved.isNotEmpty,
                  label: Text('${saved.length}'),
                  child: const Icon(Icons.bookmarks_outlined),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) =>
                        context.read<GigFeedCubit>().search(value),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search gigs or skills',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                BlocBuilder<GigFeedCubit, GigFeedState>(
                  buildWhen: (previous, current) =>
                      previous.filter.isActive != current.filter.isActive,
                  builder: (context, state) {
                    return IconButton.filledTonal(
                      tooltip: 'Filters',
                      onPressed: () => _openFilters(context),
                      icon: Badge(
                        isLabelVisible: state.filter.isActive,
                        child: const Icon(Icons.tune),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<GigFeedCubit, GigFeedState>(
              builder: (context, state) {
                if (state.status == GigFeedStatus.failure) {
                  return ErrorView(
                    message: state.errorMessage ?? 'Something went wrong.',
                    onRetry: () => context.read<GigFeedCubit>().start(),
                  );
                }
                if (state.status != GigFeedStatus.loaded) {
                  return const LoadingView();
                }
                final gigs = state.visibleGigs;
                if (gigs.isEmpty) {
                  return EmptyView(
                    message: state.filter.isActive
                        ? 'No gigs match your search or filters.'
                        : 'No gigs posted yet.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: gigs.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final gig = gigs[index];
                    return BlocBuilder<BookmarksCubit, Set<String>>(
                      builder: (context, saved) {
                        return GigCard(
                          gig: gig,
                          isBookmarked: saved.contains(gig.id),
                          onTap: () => context.push(
                            AppRoutes.gigDetail(gig.id),
                            extra: gig,
                          ),
                          onBookmarkTap: () =>
                              context.read<BookmarksCubit>().toggle(gig.id),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
"""

FILES["lib/features/gigs/presentation/widgets/filter_sheet.dart"] = r"""import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nextgig/core/constants/app_constants.dart';
import 'package:nextgig/core/utils/formatters.dart';
import 'package:nextgig/core/widgets/app_button.dart';
import 'package:nextgig/features/gigs/presentation/cubit/gig_feed_cubit.dart';
import 'package:nextgig/features/gigs/presentation/cubit/gig_feed_state.dart';

/// Bottom sheet with category, neighborhood and pay-range filters.
/// Every change goes straight to [GigFeedCubit], so the list updates live.
class FilterSheet extends StatelessWidget {
  const FilterSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<GigFeedCubit, GigFeedState>(
      builder: (context, state) {
        final cubit = context.read<GigFeedCubit>();
        final filter = state.filter;
        final range = RangeValues(
          (filter.minPay ?? 0).toDouble(),
          (filter.maxPay ?? AppConstants.maxPayFilter.toInt()).toDouble(),
        );

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Filters', style: textTheme.titleLarge)),
                    TextButton(
                      onPressed: cubit.clearFilters,
                      child: const Text('Clear all'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Category', style: textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final category in AppConstants.gigCategories)
                      ChoiceChip(
                        label: Text(category),
                        selected: filter.category == category,
                        onSelected: (selected) => cubit.updateFilter(
                          selected
                              ? filter.copyWith(category: category)
                              : filter.copyWith(clearCategory: true),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Neighborhood', style: textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final area in AppConstants.neighborhoods)
                      ChoiceChip(
                        label: Text(area),
                        selected: filter.neighborhood == area,
                        onSelected: (selected) => cubit.updateFilter(
                          selected
                              ? filter.copyWith(neighborhood: area)
                              : filter.copyWith(clearNeighborhood: true),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Pay: ${formatRwf(range.start.round())} - ${formatRwf(range.end.round())}',
                  style: textTheme.titleSmall,
                ),
                RangeSlider(
                  values: range,
                  min: 0,
                  max: AppConstants.maxPayFilter,
                  divisions: 40,
                  labels: RangeLabels(
                    formatRwf(range.start.round()),
                    formatRwf(range.end.round()),
                  ),
                  onChanged: (values) {
                    final isFullRange = values.start == 0 &&
                        values.end == AppConstants.maxPayFilter;
                    cubit.updateFilter(
                      isFullRange
                          ? filter.copyWith(clearPay: true)
                          : filter.copyWith(
                              minPay: values.start.round(),
                              maxPay: values.end.round(),
                            ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                AppButton(
                  label: 'Show results',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
"""

FILES["lib/features/gigs/presentation/screens/gig_detail_screen.dart"] = r"""import 'package:flutter/material.dart';
import 'package:nextgig/core/utils/formatters.dart';
import 'package:nextgig/core/widgets/app_button.dart';
import 'package:nextgig/core/widgets/skill_chip.dart';
import 'package:nextgig/features/gigs/domain/entities/gig.dart';

/// Gig detail. The Apply button is wired up by member 5 (applications).
class GigDetailScreen extends StatelessWidget {
  const GigDetailScreen({super.key, required this.gig});

  final Gig gig;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Gig details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(gig.title, style: textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text('Posted by ${gig.posterName}', style: textTheme.bodyMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.payments_outlined, size: 18),
                  label: Text(formatRwf(gig.pay)),
                ),
                Chip(
                  avatar: const Icon(Icons.place_outlined, size: 18),
                  label: Text(gig.neighborhood),
                ),
                Chip(label: Text(gig.category)),
              ],
            ),
            const SizedBox(height: 24),
            Text('About this gig', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(gig.description, style: textTheme.bodyLarge),
            const SizedBox(height: 24),
            Text('Skills needed', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final skill in gig.requiredSkills) SkillChip(label: skill),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AppButton(
            label: 'Apply for this gig',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Applications are coming soon.')),
              );
            },
          ),
        ),
      ),
    );
  }
}
"""

# --------------------------------------------------------------------------------------
# Placeholder screens for the other members' features
# --------------------------------------------------------------------------------------
def placeholder_screen(class_name, title, note):
    return (
        "import 'package:flutter/material.dart';\n"
        "import 'package:nextgig/core/widgets/placeholder_screen.dart';\n"
        "\n"
        "/// TODO: replace this placeholder with the real screen.\n"
        "class %s extends StatelessWidget {\n"
        "  const %s({super.key});\n"
        "\n"
        "  @override\n"
        "  Widget build(BuildContext context) {\n"
        "    return const PlaceholderScreen(\n"
        "      title: '%s',\n"
        "      note: '%s',\n"
        "    );\n"
        "  }\n"
        "}\n" % (class_name, class_name, title, note)
    )


FILES["lib/features/auth/presentation/screens/login_screen.dart"] = placeholder_screen(
    "LoginScreen", "Log in", "Login screen - owned by the authentication member."
)
FILES["lib/features/auth/presentation/screens/signup_screen.dart"] = placeholder_screen(
    "SignupScreen", "Sign up", "Sign up and role onboarding - owned by the authentication member."
)
FILES["lib/features/postings/presentation/screens/postings_screen.dart"] = placeholder_screen(
    "PostingsScreen", "Gigs", "Gig postings and applications - owned by the postings member."
)
FILES["lib/features/mentorship/presentation/screens/mentors_screen.dart"] = placeholder_screen(
    "MentorsScreen", "Mentors", "Mentor directory and endorsements."
)
FILES["lib/features/messages/presentation/screens/messages_screen.dart"] = placeholder_screen(
    "MessagesScreen", "Messages", "Messages between users."
)
FILES["lib/features/profile/presentation/screens/profile_screen.dart"] = placeholder_screen(
    "ProfileScreen", "Profile", "Skill profile and settings - owned by the profile member."
)

# --------------------------------------------------------------------------------------
# Tests (unit + widget)
# --------------------------------------------------------------------------------------
FILES["test/features/gigs/gig_filter_test.dart"] = r"""import 'package:flutter_test/flutter_test.dart';
import 'package:nextgig/features/gigs/domain/entities/gig.dart';
import 'package:nextgig/features/gigs/domain/entities/gig_filter.dart';

Gig _gig({
  required String id,
  String title = 'Sample gig',
  String category = 'Tech',
  String neighborhood = 'Kimironko',
  int pay = 50000,
  List<String> skills = const ['Flutter'],
}) {
  return Gig(
    id: id,
    title: title,
    description: 'Description',
    category: category,
    neighborhood: neighborhood,
    pay: pay,
    requiredSkills: skills,
    posterName: 'Poster',
    posterId: 'user-1',
  );
}

void main() {
  final gigs = [
    _gig(id: '1', title: 'Landing page', category: 'Tech', pay: 60000),
    _gig(
      id: '2',
      title: 'Logo design',
      category: 'Design',
      neighborhood: 'Remera',
      pay: 30000,
      skills: ['Illustrator'],
    ),
    _gig(
      id: '3',
      title: 'Math tutor',
      category: 'Tutoring',
      neighborhood: 'Remera',
      pay: 20000,
      skills: ['Mathematics'],
    ),
  ];

  test('an empty filter returns every gig', () {
    expect(const GigFilter().apply(gigs), gigs);
    expect(const GigFilter().isActive, isFalse);
  });

  test('filters by category', () {
    final result = const GigFilter(category: 'Design').apply(gigs);
    expect(result.map((g) => g.id), ['2']);
  });

  test('filters by neighborhood and pay range together', () {
    final result = const GigFilter(
      neighborhood: 'Remera',
      minPay: 25000,
      maxPay: 40000,
    ).apply(gigs);
    expect(result.map((g) => g.id), ['2']);
  });

  test('search matches title and required skills, ignoring case', () {
    expect(const GigFilter(query: 'LANDING').apply(gigs).map((g) => g.id), ['1']);
    expect(
      const GigFilter(query: 'mathematics').apply(gigs).map((g) => g.id),
      ['3'],
    );
  });
}
"""

FILES["test/features/gigs/gig_feed_cubit_test.dart"] = r"""import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nextgig/features/gigs/domain/entities/gig.dart';
import 'package:nextgig/features/gigs/domain/entities/gig_filter.dart';
import 'package:nextgig/features/gigs/domain/repositories/gig_repository.dart';
import 'package:nextgig/features/gigs/domain/usecases/watch_gigs.dart';
import 'package:nextgig/features/gigs/presentation/cubit/gig_feed_cubit.dart';
import 'package:nextgig/features/gigs/presentation/cubit/gig_feed_state.dart';

class MockGigRepository extends Mock implements GigRepository {}

void main() {
  late MockGigRepository repository;

  const gigs = [
    Gig(
      id: '1',
      title: 'Landing page',
      description: 'Build a page',
      category: 'Tech',
      neighborhood: 'Kimironko',
      pay: 60000,
      requiredSkills: ['HTML'],
      posterName: 'Aline',
      posterId: 'user-1',
    ),
  ];

  setUp(() {
    repository = MockGigRepository();
  });

  blocTest<GigFeedCubit, GigFeedState>(
    'emits loading then loaded when the gig stream emits',
    setUp: () {
      when(() => repository.watchGigs()).thenAnswer((_) => Stream.value(gigs));
    },
    build: () => GigFeedCubit(WatchGigs(repository)),
    act: (cubit) => cubit.start(),
    wait: const Duration(milliseconds: 10),
    expect: () => [
      const GigFeedState(status: GigFeedStatus.loading),
      const GigFeedState(status: GigFeedStatus.loaded, allGigs: gigs),
    ],
  );

  blocTest<GigFeedCubit, GigFeedState>(
    'emits failure when the gig stream errors',
    setUp: () {
      when(() => repository.watchGigs())
          .thenAnswer((_) => Stream<List<Gig>>.error(Exception('offline')));
    },
    build: () => GigFeedCubit(WatchGigs(repository)),
    act: (cubit) => cubit.start(),
    wait: const Duration(milliseconds: 10),
    expect: () => [
      const GigFeedState(status: GigFeedStatus.loading),
      const GigFeedState(
        status: GigFeedStatus.failure,
        errorMessage: 'Could not load gigs. Please try again.',
      ),
    ],
  );

  blocTest<GigFeedCubit, GigFeedState>(
    'search updates the filter query',
    build: () => GigFeedCubit(WatchGigs(repository)),
    act: (cubit) => cubit.search('flutter'),
    expect: () => [
      const GigFeedState(filter: GigFilter(query: 'flutter')),
    ],
  );
}
"""

FILES["test/core/formatters_test.dart"] = r"""import 'package:flutter_test/flutter_test.dart';
import 'package:nextgig/core/utils/formatters.dart';

void main() {
  test('formatRwf adds thousands separators', () {
    expect(formatRwf(0), '0 RWF');
    expect(formatRwf(950), '950 RWF');
    expect(formatRwf(25000), '25,000 RWF');
    expect(formatRwf(1250000), '1,250,000 RWF');
  });
}
"""

FILES["test/core/gig_card_test.dart"] = r"""import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextgig/core/widgets/gig_card.dart';
import 'package:nextgig/features/gigs/domain/entities/gig.dart';

void main() {
  const gig = Gig(
    id: '1',
    title: 'Build a landing page',
    description: 'Simple page',
    category: 'Tech',
    neighborhood: 'Kimironko',
    pay: 25000,
    requiredSkills: ['HTML', 'CSS'],
    posterName: 'Aline Salon',
    posterId: 'user-1',
  );

  testWidgets('GigCard shows gig info and reports bookmark taps', (tester) async {
    var bookmarkTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GigCard(
            gig: gig,
            isBookmarked: false,
            onTap: () {},
            onBookmarkTap: () => bookmarkTaps++,
          ),
        ),
      ),
    );

    expect(find.text('Build a landing page'), findsOneWidget);
    expect(find.text('25,000 RWF'), findsOneWidget);
    expect(find.text('Kimironko'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.bookmark_border));
    expect(bookmarkTaps, 1);
  });
}
"""

# --------------------------------------------------------------------------------------
# Docs and repo files
# --------------------------------------------------------------------------------------
FILES["docs/ERD.md"] = r"""# NextGig data model (Firestore)

Member 3 owns this file. **Field names are frozen once agreed** - the ERD in the report
must match Firestore exactly, so nobody adds fields without updating this file.

## gigs
| Field | Type | Notes |
|---|---|---|
| (doc id) | string | primary key, auto id |
| title | string | |
| description | string | |
| category | string | one of AppConstants.gigCategories |
| neighborhood | string | one of AppConstants.neighborhoods |
| pay | number | RWF |
| requiredSkills | array<string> | |
| posterName | string | |
| posterId | string | FK -> users/{uid} |
| createdAt | timestamp | server timestamp; feed is ordered by it |

## users
TODO (member 3): uid (PK), name, email, role, bio, ...

## applications
TODO (member 5): id (PK), gigId (FK), applicantId (FK), status, createdAt

## skills / endorsements / reviews / earnings
TODO (members 3, 4, 6)
"""

FILES[".github/pull_request_template.md"] = r"""## What does this PR do?

## Feature / rubric item

## Checklist
- [ ] Branch is up to date with `main`
- [ ] `dart format .` and `flutter analyze` are clean
- [ ] State handled with Cubit/Bloc (no setState for app state)
- [ ] Screens match the Figma prototype (checked in portrait and landscape)
- [ ] Tests added or updated
- [ ] Firestore fields match docs/ERD.md
"""

FILES["README.md"] = r"""# NextGig

A mobile app that connects young talent in Kigali with paid gigs, verified skills and mentors.
Built with Flutter, Firebase (Auth + Cloud Firestore) and Cloudinary for images.

## Architecture
- State management: `flutter_bloc` (Cubits)
- Dependency injection: `get_it` (`lib/core/di/injection.dart`)
- Navigation: `go_router` with a bottom-navigation shell
- Clean Architecture per feature: `data/`, `domain/`, `presentation/`

```
lib/
  core/        theme, router, di, shared widgets, utils, constants
  features/    one folder per feature (gigs, auth, profile, ...)
```

## Setup
1. Install Flutter and the Firebase CLI, then run `dart pub global activate flutterfire_cli`.
2. Clone the repo and run `flutter pub get`.
3. `lib/firebase_options.dart` is generated by `flutterfire configure` (commit it so everyone can run the app).
4. Run on an emulator or a physical device: `flutter run`.

## Quality checks
```
dart format .
flutter analyze
flutter test --coverage
```

## Team workflow
- One branch per feature (`feature/auth`, `feature/gig-feed`, ...), merged into `main` by pull request.
- Every PR is reviewed by at least one teammate.
- Commit small and often, with descriptive messages.

## Screenshots
_Add screenshots of each screen here._

## Known limitations and future work
_To be completed._
"""

# --------------------------------------------------------------------------------------
# Script logic
# --------------------------------------------------------------------------------------

def stub_content(rel, original):
    """Content used in --structure-only mode: empty stubs instead of real code."""
    if rel.startswith("test/"):
        return "void main() {}\n"
    if rel.endswith(".dart"):
        return "// TODO: implement\n"
    return original  # docs / README-like files stay useful


def detect_package_name(root):
    pubspec = root / "pubspec.yaml"
    match = re.search(r"^name:\s*([A-Za-z0-9_]+)", pubspec.read_text(encoding="utf-8"), re.M)
    return match.group(1) if match else "nextgig"


def main():
    parser = argparse.ArgumentParser(description="Scaffold the NextGig Flutter project structure.")
    parser.add_argument("--root", default=".", help="Flutter project root (default: current folder)")
    parser.add_argument("--force", action="store_true", help="overwrite files that already exist")
    parser.add_argument("--dry-run", action="store_true", help="print actions without writing anything")
    parser.add_argument("--structure-only", action="store_true",
                        help="create only the folders and empty stub files (no real code)")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    pubspec = root / "pubspec.yaml"
    if not pubspec.exists():
        sys.exit("ERROR: pubspec.yaml not found. Run this from the Flutter project root "
                 "(after `flutter create .`).")

    package = detect_package_name(root)
    pubspec_text = pubspec.read_text(encoding="utf-8")
    missing = [pkg for pkg in REQUIRED_PACKAGES if not re.search(r"^\s+%s:" % pkg, pubspec_text, re.M)]

    created, overwritten, skipped, removed = [], [], [], []

    # 1. Remove Flutter's default counter test (it breaks `flutter test` once main.dart changes)
    for rel, marker in ([] if args.structure_only else DELETE_IF_DEFAULT.items()):
        path = root / rel
        if path.exists() and marker in path.read_text(encoding="utf-8", errors="ignore"):
            removed.append(rel)
            if not args.dry_run:
                path.unlink()

    # 2. Write files
    for rel, content in FILES.items():
        path = root / rel
        if args.structure_only:
            if rel in OVERWRITE_IF_DEFAULT:
                continue  # leave lib/main.dart and README.md exactly as they are
            content = stub_content(rel, content)
        content = content.replace("package:nextgig/", "package:%s/" % package)
        if path.exists():
            existing = path.read_text(encoding="utf-8", errors="ignore")
            marker = OVERWRITE_IF_DEFAULT.get(rel)
            if args.force or (marker and marker in existing):
                overwritten.append(rel)
            else:
                skipped.append(rel)
                continue
        else:
            created.append(rel)
        if not args.dry_run:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8", newline="\n")

    # 3. Empty feature folders for the other members (kept in git with .gitkeep)
    keep_dirs = []
    for feature in OTHER_FEATURES:
        for layer in LAYERS:
            keep_dirs.append("lib/features/%s/%s" % (feature, layer))
    keep_dirs += ["lib/features/gigs/presentation/widgets", "assets/images"]
    for rel in keep_dirs:
        folder = root / rel
        has_files = folder.exists() and any(folder.iterdir())
        if not has_files and not args.dry_run:
            folder.mkdir(parents=True, exist_ok=True)
            (folder / ".gitkeep").write_text("", encoding="utf-8")

    # 4. Report
    prefix = "[dry run] " if args.dry_run else ""
    print("%sPackage name: %s" % (prefix, package))
    print("%sCreated: %d   Overwritten: %d   Skipped (already existed): %d   Removed: %d"
          % (prefix, len(created), len(overwritten), len(skipped), len(removed)))
    for rel in created:
        print("  + " + rel)
    for rel in overwritten:
        print("  ~ " + rel)
    for rel in skipped:
        print("  = " + rel + "  (kept; use --force to overwrite)")
    for rel in removed:
        print("  - " + rel + "  (default counter test)")

    if missing and not args.structure_only:
        print("\nMissing packages in pubspec.yaml: " + ", ".join(missing))
        print("Install them with:")
        print("  flutter pub add " + " ".join(p for p in missing if p not in ("bloc_test", "mocktail")))
        dev = [p for p in missing if p in ("bloc_test", "mocktail")]
        if dev:
            print("  flutter pub add --dev " + " ".join(dev))

    if not args.structure_only and not (root / "lib" / "firebase_options.dart").exists():
        print("\nlib/firebase_options.dart is missing. Run `flutterfire configure` first, "
              "otherwise the app will not compile.")

    if args.structure_only:
        print("\nStructure created. Every .dart file is an empty stub to fill in.")
        print("To get the full starter code later, run again with --force.")
        return
    print("\nNext steps:")
    print("  1. flutter pub get")
    print("  2. dart format .")
    print("  3. dart fix --apply")
    print("  4. flutter analyze        (aim for 0 issues, then screenshot it for the report)")
    print("  5. flutter test")
    print("  6. flutter run            (emulator or physical phone)")


if __name__ == "__main__":
    main()