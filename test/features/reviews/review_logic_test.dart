import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nextgig/features/applications/domain/entities/gig_application.dart';
import 'package:nextgig/features/reviews/domain/entities/rating_summary.dart';
import 'package:nextgig/features/reviews/domain/entities/review.dart';
import 'package:nextgig/features/reviews/domain/repositories/review_repository.dart';
import 'package:nextgig/features/reviews/domain/usecases/review_usecases.dart';

class MockReviewRepository extends Mock implements ReviewRepository {}

Review review(int rating) => Review(
  id: 'r$rating',
  gigId: 'g',
  applicationId: 'a',
  reviewerId: 'eric',
  revieweeId: 'aline',
  rating: rating,
  comment: 'Good work overall.',
);

GigApplication application({
  ApplicationStatus status = ApplicationStatus.completed,
}) => GigApplication(
  id: 'app1',
  gigId: 'gig1',
  gigTitle: 'Landing page',
  applicantId: 'aline',
  applicantName: 'Aline',
  posterId: 'eric',
  status: status,
);

void main() {
  group('RatingSummary', () {
    test('averages the ratings', () {
      final summary = RatingSummary.fromReviews([
        review(5),
        review(4),
        review(4),
        review(2),
      ]);
      expect(summary.count, 4);
      expect(summary.average, closeTo(3.75, 1e-9));
      expect(summary.averageLabel, '3.8');
    });

    test('counts each star level', () {
      final summary = RatingSummary.fromReviews([
        review(5),
        review(5),
        review(1),
      ]);
      expect(summary.countFor(5), 2);
      expect(summary.countFor(1), 1);
      expect(summary.countFor(3), 0);
      expect(summary.shareFor(5), closeTo(2 / 3, 1e-9));
    });

    test('is empty with no reviews instead of dividing by zero', () {
      final summary = RatingSummary.fromReviews(const []);
      expect(summary.isEmpty, isTrue);
      expect(summary.average, 0);
      expect(summary.shareFor(5), 0);
    });

    test('ignores ratings outside 1 to 5', () {
      final summary = RatingSummary.fromReviews([
        review(5),
        review(0),
        review(9),
      ]);
      expect(summary.count, 1);
      expect(summary.average, 5);
    });

    test('updates when a new review arrives', () {
      final before = RatingSummary.fromReviews([review(5)]);
      final after = RatingSummary.fromReviews([review(5), review(3)]);
      expect(before.average, 5);
      expect(after.average, 4);
      expect(after.count, before.count + 1);
    });
  });

  group('checkReviewEligibility', () {
    test('the client of a completed gig may review', () {
      expect(
        checkReviewEligibility(
          application: application(),
          viewerId: 'eric',
          alreadyReviewed: false,
        ),
        ReviewEligibility.eligible,
      );
    });

    test('someone who was not the client may not', () {
      expect(
        checkReviewEligibility(
          application: application(),
          viewerId: 'stranger',
          alreadyReviewed: false,
        ),
        ReviewEligibility.notClient,
      );
    });

    test('the talent cannot review themselves', () {
      expect(
        checkReviewEligibility(
          application: application(),
          viewerId: 'aline',
          alreadyReviewed: false,
        ),
        ReviewEligibility.selfReview,
      );
    });

    test('the gig must be completed', () {
      for (final status in ApplicationStatus.values) {
        if (status == ApplicationStatus.completed) continue;
        expect(
          checkReviewEligibility(
            application: application(status: status),
            viewerId: 'eric',
            alreadyReviewed: false,
          ),
          ReviewEligibility.notCompleted,
          reason: status.name,
        );
      }
    });

    test('a second review of the same gig is refused', () {
      expect(
        checkReviewEligibility(
          application: application(),
          viewerId: 'eric',
          alreadyReviewed: true,
        ),
        ReviewEligibility.alreadyReviewed,
      );
    });
  });

  group('ReviewPolicy', () {
    test('ratings must be 1 to 5', () {
      expect(ReviewPolicy.validateRating(0), isNotNull);
      expect(ReviewPolicy.validateRating(6), isNotNull);
      for (var rating = 1; rating <= 5; rating++) {
        expect(ReviewPolicy.validateRating(rating), isNull);
      }
    });

    test('comments must be 10 to 500 characters after trimming', () {
      expect(ReviewPolicy.validateComment('   short   '), isNotNull);
      expect(ReviewPolicy.validateComment('Great work!'), isNull);
      expect(ReviewPolicy.validateComment('x' * 500), isNull);
      expect(ReviewPolicy.validateComment('x' * 501), isNotNull);
    });
  });

  group('SubmitReview', () {
    late MockReviewRepository repo;

    setUp(() {
      repo = MockReviewRepository();
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

    test('saves a valid review against the application', () async {
      await SubmitReview(repo)(
        application: application(),
        reviewerId: 'eric',
        alreadyReviewed: false,
        rating: 4,
        comment: '  Delivered on time.  ',
      );
      verify(
        () => repo.add(
          applicationId: 'app1',
          gigId: 'gig1',
          reviewerId: 'eric',
          revieweeId: 'aline',
          rating: 4,
          comment: 'Delivered on time.',
        ),
      ).called(1);
    });

    test('refuses ineligible reviewers without writing', () {
      expect(
        () => SubmitReview(repo)(
          application: application(status: ApplicationStatus.hired),
          reviewerId: 'eric',
          alreadyReviewed: false,
          rating: 5,
          comment: 'Delivered on time.',
        ),
        throwsA(isA<ReviewException>()),
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
  });
}
