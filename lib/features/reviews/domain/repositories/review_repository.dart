import 'package:nextgig/features/reviews/domain/entities/review.dart';

abstract class ReviewRepository {
  /// Reviews about [revieweeId], newest first.
  Stream<List<Review>> watchForUser(String revieweeId);

  /// The review for one completed application, or null if none yet.
  Stream<Review?> watchForApplication(String applicationId);

  /// The document id is [applicationId], so each gig is reviewed once.
  Future<void> add({
    required String applicationId,
    required String gigId,
    required String reviewerId,
    required String revieweeId,
    required int rating,
    required String comment,
  });
}
