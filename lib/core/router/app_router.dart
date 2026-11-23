import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nextgig/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:nextgig/core/di/injection.dart';
import 'package:nextgig/core/router/app_routes.dart';
import 'package:nextgig/core/router/auth_refresh_notifier.dart';
import 'package:nextgig/core/router/main_shell.dart';
import 'package:nextgig/core/widgets/placeholder_screen.dart';
import 'package:nextgig/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:nextgig/features/auth/presentation/screens/login_screen.dart';
import 'package:nextgig/features/auth/presentation/screens/signup_screen.dart';
import 'package:nextgig/features/gigs/domain/entities/gig.dart';
import 'package:nextgig/features/earnings/presentation/screens/earnings_screen.dart';
import 'package:nextgig/features/gigs/presentation/screens/gig_detail_screen.dart';
import 'package:nextgig/features/gigs/presentation/screens/gig_feed_screen.dart';
import 'package:nextgig/features/gigs/presentation/screens/saved_gigs_screen.dart';
import 'package:nextgig/features/messages/presentation/screens/chat_screen.dart';
import 'package:nextgig/features/messages/presentation/screens/messages_screen.dart';
import 'package:nextgig/features/mentorship/presentation/screens/mentors_screen.dart';
import 'package:nextgig/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:nextgig/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:nextgig/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:nextgig/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:nextgig/features/postings/presentation/screens/gig_form_screen.dart';
import 'package:nextgig/features/postings/presentation/screens/postings_screen.dart';
import 'package:nextgig/features/profile/domain/entities/skill.dart';
import 'package:nextgig/features/profile/domain/entities/user_profile.dart';
import 'package:nextgig/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:nextgig/features/profile/presentation/screens/profile_screen.dart';
import 'package:nextgig/features/profile/presentation/screens/skill_form_screen.dart';
import 'package:nextgig/features/settings/presentation/screens/settings_screen.dart';
import 'package:nextgig/features/applications/domain/entities/gig_application.dart';
import 'package:nextgig/features/reviews/presentation/cubit/review_form_cubit.dart';
import 'package:nextgig/features/reviews/presentation/screens/review_form_screen.dart';
import 'package:nextgig/features/verification/presentation/cubit/evidence_upload_cubit.dart';
import 'package:nextgig/features/verification/presentation/cubit/skill_verification_cubit.dart';
import 'package:nextgig/features/verification/presentation/cubit/verification_decision_cubit.dart';
import 'package:nextgig/features/verification/presentation/cubit/verification_queue_cubit.dart';
import 'package:nextgig/features/verification/presentation/screens/evidence_upload_screen.dart';
import 'package:nextgig/features/verification/presentation/screens/review_request_screen.dart';
import 'package:nextgig/features/verification/presentation/screens/skill_verification_screen.dart';
import 'package:nextgig/features/verification/presentation/screens/verification_detail_screen.dart';
import 'package:nextgig/features/verification/presentation/screens/verification_queue_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

/// App navigation with an auth redirect.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  refreshListenable: AuthRefreshNotifier(sl<AuthCubit>().stream),
  redirect: (context, state) {
    // The splash always shows first, then asks for /home.
    if (state.matchedLocation == AppRoutes.splash) return null;
    // First launch on this phone: onboarding before anything else.
    final onOnboarding = state.matchedLocation == AppRoutes.onboarding;
    if (!sl<OnboardingCubit>().hasSeen) {
      return onOnboarding ? null : AppRoutes.onboarding;
    }
    if (onOnboarding) return AppRoutes.home;

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
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => BlocProvider<OnboardingCubit>.value(
        value: sl<OnboardingCubit>(),
        child: const OnboardingScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.signup,
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: AppRoutes.userPattern,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          ProfileScreen(uid: state.pathParameters['uid']),
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
    GoRoute(
      path: AppRoutes.saved,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SavedGigsScreen(),
    ),
    GoRoute(
      path: AppRoutes.chatPattern,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final title = state.extra;
        return ChatScreen(
          conversationId: state.pathParameters['id'] ?? '',
          title: title is String ? title : null,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.verification,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => BlocProvider(
        create: (_) => sl<ProfileCubit>()..watch(_signedInUid()),
        child: const SkillVerificationScreen(),
      ),
      routes: [
        GoRoute(
          path: 'queue',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => BlocProvider(
            create: (_) => sl<VerificationQueueCubit>()..watch(_signedInUid()),
            child: const VerificationQueueScreen(),
          ),
        ),
        GoRoute(
          path: 'request/:id',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => BlocProvider(
            create: (_) => sl<VerificationDecisionCubit>()
              ..watch(
                requestId: state.pathParameters['id'] ?? '',
                viewerId: _signedInUid(),
              ),
            child: const ReviewRequestScreen(),
          ),
        ),
        GoRoute(
          path: 'skill/:skillId',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => BlocProvider(
            create: (_) => sl<SkillVerificationCubit>()
              ..watch(_signedInUid(), state.pathParameters['skillId'] ?? ''),
            child: const VerificationDetailScreen(),
          ),
          routes: [
            GoRoute(
              path: 'upload',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) {
                final skill = state.extra;
                if (skill is! Skill) {
                  return const PlaceholderScreen(
                    title: 'Upload evidence',
                    note: 'Open a skill from Skill verification.',
                  );
                }
                return BlocProvider(
                  create: (_) => sl<EvidenceUploadCubit>(),
                  child: EvidenceUploadScreen(skill: skill),
                );
              },
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.reviewFormPattern,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final application = state.extra;
        if (application is! GigApplication) {
          return const PlaceholderScreen(
            title: 'Review',
            note: 'Open a completed gig to leave a review.',
          );
        }
        return BlocProvider(
          create: (_) =>
              sl<ReviewFormCubit>()
                ..load(application: application, viewerId: _signedInUid()),
          child: ReviewFormScreen(application: application),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.notifications,
      builder: (context, state) => const NotificationsScreen(),
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
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (context, state) {
                    final gig = state.extra;
                    return GigFormScreen(gig: gig is Gig ? gig : null);
                  },
                ),
              ],
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
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (context, state) {
                    final profile = state.extra;
                    if (profile is! UserProfile) {
                      return const PlaceholderScreen(
                        title: 'Profile',
                        note: 'Open edit from your profile.',
                      );
                    }
                    final uid = sl<AuthCubit>().state.user?.uid ?? profile.uid;
                    return BlocProvider(
                      create: (_) => sl<ProfileCubit>()..watch(uid),
                      child: EditProfileScreen(profile: profile),
                    );
                  },
                ),
                GoRoute(
                  path: 'settings',
                  builder: (context, state) => const SettingsScreen(),
                ),
                GoRoute(
                  path: 'earnings',
                  builder: (context, state) => EarningsScreen(
                    initialGigTitle:
                        state.uri.queryParameters['gigTitle'] ?? '',
                    initialGigId: state.uri.queryParameters['gigId'] ?? '',
                  ),
                ),
                GoRoute(
                  path: 'skill',
                  builder: (context, state) {
                    final extra = state.extra;
                    final uid = sl<AuthCubit>().state.user?.uid ?? '';
                    return BlocProvider(
                      create: (_) => sl<ProfileCubit>()..watch(uid),
                      child: SkillFormScreen(
                        uid: uid,
                        skill: extra is Skill ? extra : null,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

String _signedInUid() => sl<AuthCubit>().state.user?.uid ?? '';
