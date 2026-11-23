import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nextgig/core/di/injection.dart';
import 'package:nextgig/core/router/app_router.dart';
import 'package:nextgig/core/theme/app_theme.dart';
import 'package:nextgig/core/settings/settings_cubit.dart';
import 'package:nextgig/core/theme/theme_cubit.dart';
import 'package:nextgig/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:nextgig/features/gigs/presentation/cubit/bookmarks_cubit.dart';
import 'package:nextgig/features/notifications/presentation/cubit/notifications_cubit.dart';

class NextGigApp extends StatelessWidget {
  const NextGigApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>.value(value: sl<ThemeCubit>()),
        BlocProvider<SettingsCubit>.value(value: sl<SettingsCubit>()),
        BlocProvider<BookmarksCubit>.value(value: sl<BookmarksCubit>()),
        BlocProvider<AuthCubit>.value(value: sl<AuthCubit>()),
        BlocProvider<NotificationsCubit>.value(
          value: sl<NotificationsCubit>(),
        ),
      ],
      child: _NotificationsAuthSync(
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
      ),
    );
  }
}

class _NotificationsAuthSync extends StatefulWidget {
  const _NotificationsAuthSync({required this.child});

  final Widget child;

  @override
  State<_NotificationsAuthSync> createState() => _NotificationsAuthSyncState();
}

class _NotificationsAuthSyncState extends State<_NotificationsAuthSync> {
  StreamSubscription<User?>? _sub;

  @override
  void initState() {
    super.initState();
    final notifications = sl<NotificationsCubit>();
    _sub = sl<FirebaseAuth>().authStateChanges().listen((user) {
      if (user != null) {
        notifications.start();
      } else {
        notifications.stop();
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}