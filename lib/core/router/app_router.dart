import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nextgig/core/di/injection.dart';
import 'package:nextgig/core/router/app_routes.dart';
import 'package:nextgig/core/router/auth_refresh_notifier.dart';
import 'package:nextgig/core/router/main_shell.dart';
import 'package:nextgig/core/widgets/placeholder_screen.dart';
import 'package:nextgig/features/auth/presentation/cubit/auth_cubit.dart';
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

/// App navigation with an auth redirect.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.home,
  refreshListenable: AuthRefreshNotifier(sl<AuthCubit>().stream),
  redirect: (context, state) {
    final auth = sl<AuthCubit>().state;
    if (!auth.initialized) return null;
    final onAuthPage =
        state.matchedLocation == AppRoutes.login ||
        state.matchedLocation == AppRoutes.signup;
    if (!auth.isAuthenticated && !onAuthPage) return AppRoutes.login;
    if (auth.isAuthenticated && onAuthPage) return AppRoutes.home;
    return null;
  },
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
