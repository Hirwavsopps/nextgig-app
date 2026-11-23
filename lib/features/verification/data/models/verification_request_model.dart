import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nextgig/features/verification/domain/entities/evidence.dart';
import 'package:nextgig/features/verification/domain/entities/reviewer.dart';
import 'package:nextgig/features/verification/domain/entities/verification_request.dart';
import 'package:nextgig/features/verification/domain/entities/verification_status.dart';

DateTime? _date(Object? value) => value is Timestamp ? value.toDate() : null;

class VerificationRequestModel {
  const VerificationRequestModel._();

  static VerificationRequest fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return VerificationRequest(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      skillId: data['skillId'] as String? ?? '',
      skillName: data['skillName'] as String? ?? '',
      evidenceUrl: data['evidenceUrl'] as String? ?? '',
      evidenceFileName: data['evidenceFileName'] as String? ?? '',
      evidencePath: data['evidencePath'] as String? ?? '',
      evidenceContentType: data['evidenceContentType'] as String? ?? '',
      evidenceType: EvidenceType.parse(data['evidenceType'] as String?),
      note: data['note'] as String? ?? '',
      status: VerificationStatus.parse(data['status'] as String?),
      submittedAt: _date(data['submittedAt']),
      reviewerId: data['reviewerId'] as String?,
      reviewerName: data['reviewerName'] as String? ?? '',
      reviewerRelationship: data['reviewerRelationship'] as String? ?? '',
      reviewerComment: data['reviewerComment'] as String? ?? '',
      reviewedAt: _date(data['reviewedAt']),
    );
  }

  /// The document a new submission is created with. firestore.rules accepts
  /// exactly these keys.
  static Map<String, dynamic> newRequest({
    required String userId,
    required String userName,
    required String skillId,
    required String skillName,
    required String evidenceUrl,
    required String evidenceFileName,
    required String evidencePath,
    required String evidenceContentType,
    required EvidenceType evidenceType,
    required String note,
  }) => {
    'userId': userId,
    'userName': userName,
    'skillId': skillId,
    'skillName': skillName,
    'evidenceUrl': evidenceUrl,
    'evidenceFileName': evidenceFileName,
    'evidencePath': evidencePath,
    'evidenceContentType': evidenceContentType,
    'evidenceType': evidenceType.name,
    'note': note,
    'status': VerificationStatus.pending.name,
    'submittedAt': FieldValue.serverTimestamp(),
    'reviewerId': null,
    'reviewerName': '',
    'reviewerRelationship': '',
    'reviewerComment': '',
    'reviewedAt': null,
  };

  static Reviewer? reviewerFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return Reviewer(
      uid: doc.id,
      name: data['name'] as String? ?? '',
      relationship: data['relationship'] as String? ?? 'mentor',
      title: data['title'] as String? ?? '',
      organization: data['organization'] as String? ?? '',
      active: data['active'] as bool? ?? false,
    );
  }
}
