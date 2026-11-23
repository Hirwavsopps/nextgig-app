import 'package:nextgig/features/verification/domain/entities/evidence.dart';
import 'package:nextgig/features/verification/domain/entities/reviewer.dart';
import 'package:nextgig/features/verification/domain/entities/verification_request.dart';

abstract class VerificationRepository {
  /// Opens the file picker. Null when the user cancels.
  Future<EvidenceFile?> pickEvidence();

  /// Uploads [file] to Storage, then creates the request and marks the skill
  /// pending in one batch. [onProgress] receives values from 0 to 1.
  Future<String> submit({
    required String userId,
    required String userName,
    required String skillId,
    required String skillName,
    required EvidenceFile file,
    required EvidenceType evidenceType,
    required String note,
    void Function(double progress)? onProgress,
  });

  /// Every request the owner has sent for one skill, newest first.
  Stream<List<VerificationRequest>> watchForSkill(
    String userId,
    String skillId,
  );

  Stream<VerificationRequest?> watchRequest(String requestId);

  /// Requests waiting for a reviewer, oldest first. Reviewers only.
  Stream<List<VerificationRequest>> watchPending();

  /// Requests this reviewer has decided, newest first.
  Stream<List<VerificationRequest>> watchReviewedBy(String reviewerId);

  /// Null when [uid] is not on the reviewers list.
  Stream<Reviewer?> watchReviewer(String uid);

  /// Approves or rejects [request]. Approval also writes an endorsement and
  /// marks the skill verified, all in one batch.
  Future<void> decide({
    required VerificationRequest request,
    required Reviewer reviewer,
    required bool approve,
    required String comment,
  });
}
