import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:nextgig/features/verification/data/models/verification_request_model.dart';
import 'package:nextgig/features/verification/domain/entities/evidence.dart';
import 'package:nextgig/features/verification/domain/entities/reviewer.dart';
import 'package:nextgig/features/verification/domain/entities/verification_request.dart';
import 'package:nextgig/features/verification/domain/entities/verification_status.dart';
import 'package:nextgig/features/verification/domain/usecases/verification_usecases.dart';

/// All Firestore and Storage calls for skill verification.
///
/// Firestore layout:
/// - verificationRequests/{requestId}: one evidence submission
/// - reviewers/{uid}: who may decide (read-only for the app)
/// - users/{uid}/skills/{skillId}: status fields shown on the profile
/// - users/{uid}/skills/{skillId}/endorsements/{reviewerUid}: one per reviewer
///
/// Storage: verifications/{uid}/{requestId}/{fileName}
class VerificationRemoteDataSource {
  VerificationRemoteDataSource(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('verificationRequests');

  DocumentReference<Map<String, dynamic>> _skill(String uid, String skillId) =>
      _firestore.collection('users').doc(uid).collection('skills').doc(skillId);

  Future<EvidenceFile?> pickEvidence() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: EvidencePolicy.allowedExtensions,
    );
    if (result.isEmpty) return null;
    final file = result.single;
    final path = file.path;
    if (path == null) {
      throw const VerificationException('Could not read the selected file.');
    }
    final size = await file.length() ?? await File(path).length();
    return EvidenceFile(name: file.name, localPath: path, sizeBytes: size);
  }

  Future<String> submit({
    required String userId,
    required String userName,
    required String skillId,
    required String skillName,
    required EvidenceFile file,
    required EvidenceType evidenceType,
    required String note,
    void Function(double progress)? onProgress,
  }) async {
    // The id is made first so the Storage path and the document match.
    final requestRef = _requests.doc();
    final fileName = EvidencePolicy.safeFileName(file.name);
    final path = 'verifications/$userId/${requestRef.id}/$fileName';
    final contentType = EvidencePolicy.contentTypeFor(file.extension);
    final ref = _storage.ref(path);

    final task = ref.putFile(
      File(file.localPath),
      SettableMetadata(contentType: contentType),
    );
    final progress = task.snapshotEvents.listen((snapshot) {
      if (snapshot.totalBytes > 0) {
        onProgress?.call(snapshot.bytesTransferred / snapshot.totalBytes);
      }
    }, onError: (_) {});
    try {
      await task;
    } finally {
      await progress.cancel();
    }
    final url = await ref.getDownloadURL();

    final batch = _firestore.batch()
      ..set(
        requestRef,
        VerificationRequestModel.newRequest(
          userId: userId,
          userName: userName,
          skillId: skillId,
          skillName: skillName,
          evidenceUrl: url,
          evidenceFileName: file.name,
          evidencePath: path,
          evidenceContentType: contentType,
          evidenceType: evidenceType,
          note: note,
        ),
      )
      ..update(_skill(userId, skillId), {
        'verificationStatus': VerificationStatus.pending.name,
        'verificationId': requestRef.id,
      });
    try {
      await batch.commit();
    } catch (_) {
      // Do not leave an orphaned file behind if the rules said no.
      try {
        await ref.delete();
      } catch (_) {}
      rethrow;
    }
    onProgress?.call(1);
    return requestRef.id;
  }

  Stream<List<VerificationRequest>> watchForSkill(
    String userId,
    String skillId,
  ) {
    return _requests
        .where('userId', isEqualTo: userId)
        .where('skillId', isEqualTo: skillId)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map(_map);
  }

  Stream<VerificationRequest?> watchRequest(String requestId) {
    return _requests
        .doc(requestId)
        .snapshots()
        .map(
          (doc) => doc.exists ? VerificationRequestModel.fromDoc(doc) : null,
        );
  }

  Stream<List<VerificationRequest>> watchPending() {
    return _requests
        .where('status', isEqualTo: VerificationStatus.pending.name)
        .orderBy('submittedAt')
        .snapshots()
        .map(_map);
  }

  Stream<List<VerificationRequest>> watchReviewedBy(String reviewerId) {
    return _requests
        .where('reviewerId', isEqualTo: reviewerId)
        .orderBy('reviewedAt', descending: true)
        .limit(50)
        .snapshots()
        .map(_map);
  }

  Stream<Reviewer?> watchReviewer(String uid) {
    return _firestore
        .collection('reviewers')
        .doc(uid)
        .snapshots()
        .map(VerificationRequestModel.reviewerFromDoc);
  }

  Future<void> decide({
    required VerificationRequest request,
    required Reviewer reviewer,
    required bool approve,
    required String comment,
  }) async {
    final status = approve
        ? VerificationStatus.verified
        : VerificationStatus.rejected;
    final skillRef = _skill(request.userId, request.skillId);
    final batch = _firestore.batch()
      ..update(_requests.doc(request.id), {
        'status': status.name,
        'reviewerId': reviewer.uid,
        'reviewerName': reviewer.name,
        'reviewerRelationship': reviewer.relationship,
        'reviewerComment': comment,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    if (approve) {
      // The reviewer's uid is the document id: one endorsement per person.
      final endorsementRef = skillRef
          .collection('endorsements')
          .doc(reviewer.uid);
      if ((await endorsementRef.get()).exists) {
        throw const VerificationException(
          'You have already endorsed this skill.',
        );
      }
      batch
        ..set(endorsementRef, {
          'endorserId': reviewer.uid,
          'endorserName': reviewer.name,
          'relationship': reviewer.relationship,
          'note': comment,
          'requestId': request.id,
          'createdAt': FieldValue.serverTimestamp(),
        })
        ..update(skillRef, {
          'verified': true,
          'verificationStatus': status.name,
          'verifiedAt': FieldValue.serverTimestamp(),
          'verifiedById': reviewer.uid,
          'verifiedByName': reviewer.name,
          'verifiedByRelationship': reviewer.relationship,
        });
    } else {
      batch.update(skillRef, {'verificationStatus': status.name});
    }
    await batch.commit();
  }

  List<VerificationRequest> _map(QuerySnapshot<Map<String, dynamic>> snap) =>
      snap.docs.map(VerificationRequestModel.fromDoc).toList();
}
