import 'package:nextgig/features/applications/domain/entities/gig_application.dart';
import 'package:nextgig/features/reviews/domain/repositories/review_repository.dart';

enum ReviewEligibility {
  eligible,
  notClient,
  selfReview,
  notCompleted,
  alreadyReviewed;

  String get message => switch (this) {
    eligible => '',
    notClient => 'Only the client who hired this talent can review the gig.',
    selfReview => 'You cannot review yourself.',
    notCompleted => 'You can leave a review once the gig is completed.',
    alreadyReviewed => 'You have already reviewed this gig.',
  };
}

/// Who may review: the poster of the gig, about the applicant they hired,
/// once the application is completed, and only once. firestore.rules checks
/// the same things on the server.
ReviewEligibility checkReviewEligibility({
  required GigApplication application,
  required String viewerId,
  required bool alreadyReviewed,
}) {
  if (application.applicantId == viewerId) return ReviewEligibility.selfReview;
  if (application.posterId != viewerId) return ReviewEligibility.notClient;
  if (application.status != ApplicationStatus.completed) {
    return ReviewEligibility.notCompleted;
  }
  if (alreadyReviewed) return ReviewEligibility.alreadyReviewed;
  return ReviewEligibility.eligible;
}

class ReviewPolicy {
  const ReviewPolicy._();

  static const int minComment = 10;
  static const int maxComment = 500;

  static String? validateRating(int rating) =>
      rating < 1 || rating > 5 ? 'Choose a rating from 1 to 5 stars.' : null;

  static String? validateComment(String comment) {
    final length = comment.trim().length;
    if (length < minComment) {
      return 'Write at least $minComment characters about the work.';
    }
    if (length > maxComment) {
      return 'Keep the review under $maxComment characters.';
    }
    return null;
  }
}

class ReviewException implements Exception {
  const ReviewException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SubmitReview {
  const SubmitReview(this._repo);

  final ReviewRepository _repo;

  Future<void> call({
    required GigApplication application,
    required String reviewerId,
    required bool alreadyReviewed,
    required int rating,
    required String comment,
  }) {
    final eligibility = checkReviewEligibility(
      application: application,
      viewerId: reviewerId,
      alreadyReviewed: alreadyReviewed,
    );
    if (eligibility != ReviewEligibility.eligible) {
      throw ReviewException(eligibility.message);
    }
    final problem =
        ReviewPolicy.validateRating(rating) ??
        ReviewPolicy.validateComment(comment);
    if (problem != null) throw ReviewException(problem);
    return _repo.add(
      applicationId: application.id,
      gigId: application.gigId,
      reviewerId: reviewerId,
      revieweeId: application.applicantId,
      rating: rating,
      comment: comment.trim(),
    );
  }
}
