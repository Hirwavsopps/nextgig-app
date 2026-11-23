import 'package:equatable/equatable.dart';
import 'package:nextgig/features/verification/domain/entities/evidence.dart';
import 'package:nextgig/features/verification/domain/entities/verification_status.dart';

/// One submission of evidence for one skill (verificationRequests/{id}).
/// The reviewer fields stay empty until an authorized reviewer decides.
class VerificationRequest extends Equatable {
  const VerificationRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.skillId,
    required this.skillName,
    required this.evidenceUrl,
    required this.evidenceFileName,
    required this.evidencePath,
    required this.evidenceType,
    required this.status,
    this.evidenceContentType = '',
    this.note = '',
    this.submittedAt,
    this.reviewerId,
    this.reviewerName = '',
    this.reviewerRelationship = '',
    this.reviewerComment = '',
    this.reviewedAt,
  });

  final String id;
  final String userId;
  final String userName;
  final String skillId;
  final String skillName;
  final String evidenceUrl;
  final String evidenceFileName;

  /// Storage path, `verifications/{uid}/{requestId}/{file}`.
  final String evidencePath;
  final String evidenceContentType;
  final EvidenceType evidenceType;

  /// Optional context from the user, e.g. where the course was taken.
  final String note;
  final VerificationStatus status;
  final DateTime? submittedAt;
  final String? reviewerId;
  final String reviewerName;

  /// mentor, lecturer or client.
  final String reviewerRelationship;
  final String reviewerComment;
  final DateTime? reviewedAt;

  bool get isImage => evidenceContentType.startsWith('image/');

  @override
  List<Object?> get props => [
    id,
    userId,
    userName,
    skillId,
    skillName,
    evidenceUrl,
    evidenceFileName,
    evidencePath,
    evidenceContentType,
    evidenceType,
    note,
    status,
    submittedAt,
    reviewerId,
    reviewerName,
    reviewerRelationship,
    reviewerComment,
    reviewedAt,
  ];
}
