import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:nextgig/core/constants/app_images.dart';
import 'package:nextgig/core/router/app_routes.dart';
import 'package:nextgig/core/widgets/gig_image.dart';

/// Figma frame 1: Splash.
///
/// Shows the brand briefly, then asks for /home. The router's redirect
/// decides where the user really goes: onboarding (first launch), login
/// (signed out) or home (signed in). The splash itself has no logic.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..forward();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) context.go(AppRoutes.home);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const white = Colors.white;

    // Full-screen photo of Kigali at sunset, darkened so the white text
    // stays readable. Same look in light and dark mode.
    return Scaffold(
      backgroundColor: Colors.black,
      body: PhotoBackdrop(
        asset: AppImages.kigaliSkyline,
        darkness: 0.75,
        child: SafeArea(
          child: FadeTransition(
            opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut),
            child: Center(
              // Scrolls in landscape, where the screen is short.
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: white,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        'N',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'NextGig',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Young talent. Next gigs.',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Skills, verified work and mentors in one place.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: white.withValues(alpha: 0.6)),
                      ),
                      child: const Text(
                        'KIGALI, RWANDA',
                        style: TextStyle(
                          color: white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
