import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nextgig/features/reviews/domain/entities/review.dart';
import 'package:nextgig/features/reviews/domain/repositories/review_repository.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  ReviewRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _reviews =>
      _firestore.collection('reviews');

  @override
  Stream<List<Review>> watchForUser(String revieweeId) {
    return _reviews
        .where('revieweeId', isEqualTo: revieweeId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromDoc).toList());
  }

  @override
  Stream<Review?> watchForApplication(String applicationId) {
    return _reviews
        .doc(applicationId)
        .snapshots()
        .map((doc) => doc.exists ? _fromDoc(doc) : null);
  }

  /// Document id is the application id, so a gig can be reviewed once.
  /// The reviewer's name is copied from their profile so the student's page
  /// does not have to read every client's profile; the rules check it.
  @override
  Future<void> add({
    required String applicationId,
    required String gigId,
    required String reviewerId,
    required String revieweeId,
    required int rating,
    required String comment,
  }) async {
    final reviewer = await _firestore.collection('users').doc(reviewerId).get();
    await _reviews.doc(applicationId).set({
      'gigId': gigId,
      'applicationId': applicationId,
      'reviewerId': reviewerId,
      'reviewerName': reviewer.data()?['name'] as String? ?? '',
      'revieweeId': revieweeId,
      'rating': rating,
      'comment': comment.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Review _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final created = data['createdAt'];
    return Review(
      id: doc.id,
      gigId: data['gigId'] as String? ?? '',
      applicationId: data['applicationId'] as String? ?? '',
      reviewerId: data['reviewerId'] as String? ?? '',
      reviewerName: data['reviewerName'] as String? ?? '',
      revieweeId: data['revieweeId'] as String? ?? '',
      rating: (data['rating'] as num?)?.toInt() ?? 0,
      comment: data['comment'] as String? ?? '',
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }
}
