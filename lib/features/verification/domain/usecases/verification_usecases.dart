import 'package:nextgig/features/profile/domain/entities/skill.dart';
import 'package:nextgig/features/verification/domain/entities/evidence.dart';
import 'package:nextgig/features/verification/domain/entities/reviewer.dart';
import 'package:nextgig/features/verification/domain/entities/verification_request.dart';
import 'package:nextgig/features/verification/domain/entities/verification_status.dart';
import 'package:nextgig/features/verification/domain/repositories/verification_repository.dart';

/// A rule was broken before anything reached Firebase. [message] is shown
/// to the user as is.
class VerificationException implements Exception {
  const VerificationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SubmitSkillEvidence {
  const SubmitSkillEvidence(this._repo);

  final VerificationRepository _repo;

  /// Returns the new request id.
  Future<String> call({
    required String userId,
    required String userName,
    required Skill skill,
    required EvidenceFile? file,
    required EvidenceType evidenceType,
    String note = '',
    void Function(double progress)? onProgress,
  }) {
    if (!skill.status.canSubmitEvidence) {
      throw VerificationException(
        skill.status == VerificationStatus.pending
            ? 'This skill is already waiting for a reviewer.'
            : 'This skill is already verified.',
      );
    }
    if (file == null) {
      throw const VerificationException('Choose a file to upload.');
    }
    final problem = EvidencePolicy.validate(file);
    if (problem != null) throw VerificationException(problem);
    if (note.trim().length > EvidencePolicy.maxNoteLength) {
      throw const VerificationException(
        'Keep the note under ${EvidencePolicy.maxNoteLength} characters.',
      );
    }
    return _repo.submit(
      userId: userId,
      userName: userName,
      skillId: skill.id,
      skillName: skill.name,
      file: file,
      evidenceType: evidenceType,
      note: note.trim(),
      onProgress: onProgress,
    );
  }
}

class DecideVerification {
  const DecideVerification(this._repo);

  final VerificationRepository _repo;

  static const int minCommentLength = 3;
  static const int maxCommentLength = 500;

  /// The reason a reviewer cannot decide [request], or null when they can.
  static String? blockReason(Reviewer? reviewer, VerificationRequest request) {
    if (reviewer == null || !reviewer.active) {
      return 'Only authorized reviewers can endorse skills.';
    }
    if (reviewer.uid == request.userId) {
      return 'You cannot review your own skill.';
    }
    if (!request.status.awaitingReview) {
      return 'This request has already been ${request.status.label.toLowerCase()}.';
    }
    return null;
  }

  Future<void> call({
    required Reviewer? reviewer,
    required VerificationRequest request,
    required bool approve,
    required String comment,
  }) {
    final blocked = blockReason(reviewer, request);
    if (blocked != null) throw VerificationException(blocked);
    final next = approve
        ? VerificationStatus.verified
        : VerificationStatus.rejected;
    if (!request.status.canTransitionTo(next)) {
      throw const VerificationException('This request cannot change now.');
    }
    final text = comment.trim();
    if (text.length < minCommentLength) {
      throw const VerificationException(
        'Add a short comment explaining your decision.',
      );
    }
    if (text.length > maxCommentLength) {
      throw const VerificationException(
        'Keep the comment under $maxCommentLength characters.',
      );
    }
    return _repo.decide(
      request: request,
      reviewer: reviewer!,
      approve: approve,
      comment: text,
    );
  }
}
