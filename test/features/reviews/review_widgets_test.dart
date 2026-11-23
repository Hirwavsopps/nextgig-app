import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nextgig/features/applications/domain/entities/gig_application.dart';
import 'package:nextgig/features/reviews/domain/entities/review.dart';
import 'package:nextgig/features/reviews/domain/repositories/review_repository.dart';
import 'package:nextgig/features/reviews/domain/usecases/review_usecases.dart';
import 'package:nextgig/features/reviews/presentation/cubit/review_form_cubit.dart';
import 'package:nextgig/features/reviews/presentation/screens/review_form_screen.dart';
import 'package:nextgig/features/reviews/presentation/widgets/profile_reviews_section.dart';

class MockReviewRepository extends Mock implements ReviewRepository {}

const completed = GigApplication(
  id: 'app1',
  gigId: 'gig1',
  gigTitle: 'Salon landing page',
  applicantId: 'aline',
  applicantName: 'Aline',
  posterId: 'eric',
  status: ApplicationStatus.completed,
);

void main() {
  late MockReviewRepository repo;
  late StreamController<Review?> existing;

  setUp(() {
    repo = MockReviewRepository();
    existing = StreamController<Review?>();
    when(() => repo.watchForApplication('app1'))
        .thenAnswer((_) => existing.stream);
    when(
      () => repo.add(
        applicationId: any(named: 'applicationId'),
        gigId: any(named: 'gigId'),
        reviewerId: any(named: 'reviewerId'),
        revieweeId: any(named: 'revieweeId'),
        rating: any(named: 'rating'),
        comment: any(named: 'comment'),
      ),
    ).thenAnswer((_) async {});
  });

  // Not awaited: close() never completes on a stream nobody listened to.
  tearDown(() {
    existing.close();
  });

  Future<void> pumpForm(WidgetTester tester, {String viewerId = 'eric'}) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('home')),
          routes: [
            GoRoute(
              path: 'review',
              builder: (context, state) => BlocProvider(
                create: (_) =>
                    ReviewFormCubit(repo, SubmitReview(repo))
                      ..load(application: completed, viewerId: viewerId),
                child: const ReviewFormScreen(application: completed),
              ),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    // No review saved yet; emit before settling so the spinner goes away.
    existing.add(null);
    router.push('/review');
    await tester.pumpAndSettle();
  }

  testWidgets('the client rates and reviews a completed gig', (tester) async {
    await pumpForm(tester);

    expect(find.text('How did Aline do?'), findsOneWidget);
    // Submit stays disabled until a star is chosen.
    final submit = find.widgetWithText(FilledButton, 'Submit review');
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('star-4')));
    await tester.pump();
    expect(find.text('Very good'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('review-comment')),
      'Clean code and on time.',
    );
    await tester.tap(submit);
    await tester.pumpAndSettle();

    verify(
      () => repo.add(
        applicationId: 'app1',
        gigId: 'gig1',
        reviewerId: 'eric',
        revieweeId: 'aline',
        rating: 4,
        comment: 'Clean code and on time.',
      ),
    ).called(1);
    // The screen closes after saving.
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('a too-short review shows a validation message', (tester) async {
    await pumpForm(tester);

    await tester.tap(find.byKey(const ValueKey('star-5')));
    await tester.pump();
    await tester.enterText(find.byKey(const ValueKey('review-comment')), 'ok');
    await tester.tap(find.widgetWithText(FilledButton, 'Submit review'));
    await tester.pump();

    expect(
      find.text(
        'Write at least ${ReviewPolicy.minComment} characters about '
        'the work.',
      ),
      findsOneWidget,
    );
    verifyNever(
      () => repo.add(
        applicationId: any(named: 'applicationId'),
        gigId: any(named: 'gigId'),
        reviewerId: any(named: 'reviewerId'),
        revieweeId: any(named: 'revieweeId'),
        rating: any(named: 'rating'),
        comment: any(named: 'comment'),
      ),
    );
  });

  testWidgets('someone who was not the client cannot see the form', (
    tester,
  ) async {
    await pumpForm(tester, viewerId: 'stranger');

    expect(find.text(ReviewEligibility.notClient.message), findsOneWidget);
    expect(find.byKey(const ValueKey('review-comment')), findsNothing);
  });

  testWidgets('profile section shows the average, count and comments', (
    tester,
  ) async {
    Review review(String id, int rating, String comment) => Review(
      id: id,
      gigId: 'g',
      applicationId: id,
      reviewerId: 'eric',
      reviewerName: 'Eric Murenzi',
      revieweeId: 'aline',
      rating: rating,
      comment: comment,
      createdAt: DateTime(2026, 11, 12),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProfileReviewsSection(
              title: 'Reviews',
              reviews: [
                review('a', 5, 'Excellent landing page.'),
                review('b', 4, 'Good communication.'),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('4.5'), findsOneWidget);
    expect(find.text('2 reviews'), findsOneWidget);
    expect(find.text('Excellent landing page.'), findsOneWidget);
    expect(find.text('Eric Murenzi'), findsNWidgets(2));
    expect(find.text('12 Nov 2026'), findsNWidgets(2));
  });

  testWidgets('profile section has an empty state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProfileReviewsSection(title: 'Reviews', reviews: []),
        ),
      ),
    );
    expect(find.textContaining('No reviews yet'), findsOneWidget);
  });
}
