import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nextgig/features/reviews/domain/entities/review.dart';

class ReviewRepository {
  ReviewRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _reviews =>
      _firestore.collection('reviews');

  Stream<List<Review>> watchForUser(String revieweeId) {
    return _reviews
        .where('revieweeId', isEqualTo: revieweeId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            final created = data['createdAt'];
            return Review(
              id: doc.id,
              gigId: data['gigId'] as String? ?? '',
              applicationId: data['applicationId'] as String? ?? '',
              reviewerId: data['reviewerId'] as String? ?? '',
              revieweeId: data['revieweeId'] as String? ?? '',
              rating: (data['rating'] as num?)?.toInt() ?? 0,
              comment: data['comment'] as String? ?? '',
              createdAt: created is Timestamp ? created.toDate() : null,
            );
          }).toList(),
        );
  }

  /// Document id is the application id, so a gig can be reviewed once.
  Future<void> add({
    required String applicationId,
    required String gigId,
    required String reviewerId,
    required String revieweeId,
    required int rating,
    required String comment,
  }) {
    return _reviews.doc(applicationId).set({
      'gigId': gigId,
      'applicationId': applicationId,
      'reviewerId': reviewerId,
      'revieweeId': revieweeId,
      'rating': rating,
      'comment': comment.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
