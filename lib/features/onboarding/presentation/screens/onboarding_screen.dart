import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nextgig/core/constants/app_images.dart';
import 'package:nextgig/core/router/app_routes.dart';
import 'package:nextgig/core/widgets/app_button.dart';
import 'package:nextgig/core/widgets/brand_logo.dart';
import 'package:nextgig/core/widgets/pill.dart';
import 'package:nextgig/features/onboarding/presentation/cubit/onboarding_cubit.dart';

/// Figma frame 2: Onboarding ("Find Your Match"), as three swipeable slides.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingPageCubit(),
      child: const _OnboardingView(),
    );
  }
}

class _Slide {
  const _Slide(this.image, this.icon, this.badges, this.title, this.body);

  /// Photo from assets/images (see AppImages).
  final String image;
  final IconData icon;
  final List<String> badges;
  final String title;
  final String body;
}

const _slides = [
  _Slide(
    AppImages.onboardingMatch,
    Icons.travel_explore,
    ['Design', 'Tutoring', 'Tech'],
    'Find Your Match',
    'Paid gigs in Kigali matched to your skills, from logo design to '
        'tutoring and repairs.',
  ),
  _Slide(
    AppImages.onboardingConfidence,
    Icons.verified_user_outlined,
    ['Verified clients', 'Pay in RWF'],
    'Work With Confidence',
    'See who is hiring, what the work is and exactly what it pays before '
        'you apply.',
  ),
  _Slide(
    AppImages.onboardingMentors,
    Icons.school_outlined,
    ['1-on-1 guidance', 'Real projects'],
    'Grow With Mentors',
    'Many gigs come with an experienced mentor, so every project also '
        'builds your portfolio.',
  ),
];

/// Stateful only to own and dispose the PageController; the current slide
/// lives in [OnboardingPageCubit].
class _OnboardingView extends StatefulWidget {
  const _OnboardingView();

  @override
  State<_OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<_OnboardingView> {
  final _pages = PageController();

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish(String route) async {
    await context.read<OnboardingCubit>().markSeen();
    if (mounted) context.go(route);
  }

  void _next(bool isLast) {
    if (isLast) {
      _finish(AppRoutes.signup);
    } else {
      _pages.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: landscape ? 900 : 520),
            child: BlocBuilder<OnboardingPageCubit, int>(
              builder: (context, index) {
                final isLast = index == _slides.length - 1;
                final nextButton = AppButton(
                  label: isLast ? 'Get Started' : 'Next',
                  onPressed: () => _next(isLast),
                );
                final haveAccount = TextButton(
                  onPressed: () => _finish(AppRoutes.login),
                  child: const Text('I already have an account'),
                );
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                      child: Row(
                        children: [
                          const BrandLogo(size: 32),
                          const SizedBox(width: 8),
                          Text(
                            'NextGig',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const Spacer(),
                          if (!isLast)
                            TextButton(
                              onPressed: () => _finish(AppRoutes.login),
                              child: const Text('Skip'),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _pages,
                        itemCount: _slides.length,
                        onPageChanged: context.read<OnboardingPageCubit>().show,
                        itemBuilder: (context, i) => _SlideView(_slides[i]),
                      ),
                    ),
                    // Page dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _slides.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            height: 8,
                            width: i == index ? 22 : 8,
                            decoration: BoxDecoration(
                              color: i == index
                                  ? scheme.primary
                                  : scheme.outlineVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                    if (landscape)
                      // Short screen: buttons side by side to save height.
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 10, 24, 8),
                        child: Row(
                          children: [
                            Expanded(child: haveAccount),
                            const SizedBox(width: 16),
                            Expanded(child: nextButton),
                          ],
                        ),
                      )
                    else ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                        child: nextButton,
                      ),
                      haveAccount,
                      const SizedBox(height: 8),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView(this.slide);

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    // A rounded photo with the slide's icon as a small badge.
    Widget art(double size) => SizedBox(
      height: size,
      width: size * 0.85,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(size * 0.1),
              child: Image.asset(slide.image, fit: BoxFit.cover),
            ),
          ),
          Positioned(
            right: 10,
            bottom: 10,
            child: Container(
              padding: EdgeInsets.all(size * 0.045),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(size * 0.06),
              ),
              child: Icon(
                slide.icon,
                size: size * 0.1,
                color: scheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );

    Widget text(TextAlign align) => Column(
      crossAxisAlignment: align == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: align == TextAlign.center
              ? WrapAlignment.center
              : WrapAlignment.start,
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final b in slide.badges) Pill(label: b, outlined: true),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          slide.title,
          textAlign: align,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          slide.body,
          textAlign: align,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    // Portrait: picture above text. Landscape (very little height):
    // picture on the left, text on the right, so nothing is pushed off.
    return LayoutBuilder(
      builder: (context, constraints) {
        if (landscape) {
          final size = (constraints.maxHeight * 0.8).clamp(80.0, 220.0);
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 16,
              ),
              child: Row(
                children: [
                  art(size),
                  const SizedBox(width: 32),
                  Expanded(child: text(TextAlign.start)),
                ],
              ),
            ),
          );
        }
        final size = (constraints.maxHeight * 0.5).clamp(120.0, 320.0);
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                art(size),
                const SizedBox(height: 14),
                text(TextAlign.center),
              ],
            ),
          ),
        );
      },
    );
  }
}
