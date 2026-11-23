import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nextgig/features/applications/domain/entities/gig_application.dart';

class ApplicationRepository {
  ApplicationRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _apps =>
      _firestore.collection('applications');

  Stream<List<GigApplication>> watchByApplicant(String uid) {
    return _apps
        .where('applicantId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_map);
  }

  Stream<List<GigApplication>> watchForPoster(String gigId, String posterId) {
    return _apps
        .where('gigId', isEqualTo: gigId)
        .where('posterId', isEqualTo: posterId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_map);
  }

  /// The signed-in applicant's own row on this gig. No order: one row is enough.
  Stream<List<GigApplication>> watchMine(String gigId, String applicantId) {
    return _apps
        .where('gigId', isEqualTo: gigId)
        .where('applicantId', isEqualTo: applicantId)
        .snapshots()
        .map(_map);
  }

  Future<void> apply({
    required String gigId,
    required String gigTitle,
    required String applicantId,
    required String applicantName,
    required String posterId,
  }) async {
    final existing = await _apps
        .where('gigId', isEqualTo: gigId)
        .where('applicantId', isEqualTo: applicantId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      throw StateError('You already applied to this gig.');
    }
    await _apps.add({
      'gigId': gigId,
      'gigTitle': gigTitle,
      'applicantId': applicantId,
      'applicantName': applicantName,
      'posterId': posterId,
      'status': ApplicationStatus.applied.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setStatus(String applicationId, ApplicationStatus status) {
    return _apps.doc(applicationId).update({'status': status.name});
  }

  List<GigApplication> _map(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      final created = data['createdAt'];
      return GigApplication(
        id: doc.id,
        gigId: data['gigId'] as String? ?? '',
        gigTitle: data['gigTitle'] as String? ?? '',
        applicantId: data['applicantId'] as String? ?? '',
        applicantName: data['applicantName'] as String? ?? '',
        posterId: data['posterId'] as String? ?? '',
        status: parseApplicationStatus(data['status'] as String?),
        createdAt: created is Timestamp ? created.toDate() : null,
      );
    }).toList();
  }
}
