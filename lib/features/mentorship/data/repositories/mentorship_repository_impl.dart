import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nextgig/features/mentorship/domain/entities/mentorship.dart';
import 'package:nextgig/features/mentorship/domain/repositories/mentorship_repository.dart';

/// Firestore implementation of [MentorshipRepository].
class MentorshipRepositoryImpl implements MentorshipRepository {
  MentorshipRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('mentorshipRequests');

  /// The where() on talentId matches the security rule, which only lets
  /// you read your own requests. Sorted on the phone (no index needed).
  @override
  Stream<List<MentorshipRequest>> watchMyRequests(String talentId) {
    return _requests.where('talentId', isEqualTo: talentId).snapshots().map((
      snap,
    ) {
      final list = snap.docs.map((doc) {
        final d = doc.data();
        final created = d['createdAt'];
        return MentorshipRequest(
          id: doc.id,
          talentId: d['talentId'] as String? ?? '',
          mentorName: d['mentorName'] as String? ?? '',
          gigId: d['gigId'] as String? ?? '',
          gigTitle: d['gigTitle'] as String? ?? '',
          message: d['message'] as String? ?? '',
          status: d['status'] as String? ?? MentorshipStatus.pending,
          createdAt: created is Timestamp ? created.toDate() : null,
        );
      }).toList();
      list.sort(
        (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
          a.createdAt ?? DateTime.now(),
        ),
      );
      return list;
    });
  }

  @override
  Future<void> sendRequest({
    required String talentId,
    required String talentName,
    required String mentorName,
    required String gigId,
    required String gigTitle,
    required String message,
  }) {
    return _requests.add({
      'talentId': talentId,
      'talentName': talentName,
      'mentorName': mentorName,
      'gigId': gigId,
      'gigTitle': gigTitle,
      'message': message.trim(),
      'status': MentorshipStatus.pending,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> cancelRequest(String requestId) {
    return _requests.doc(requestId).update({
      'status': MentorshipStatus.cancelled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteRequest(String requestId) =>
      _requests.doc(requestId).delete();
}
