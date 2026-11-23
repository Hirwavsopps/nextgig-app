import 'package:nextgig/features/verification/data/datasources/verification_remote_data_source.dart';
import 'package:nextgig/features/verification/domain/entities/evidence.dart';
import 'package:nextgig/features/verification/domain/entities/reviewer.dart';
import 'package:nextgig/features/verification/domain/entities/verification_request.dart';
import 'package:nextgig/features/verification/domain/repositories/verification_repository.dart';

class VerificationRepositoryImpl implements VerificationRepository {
  VerificationRepositoryImpl(this._remote);

  final VerificationRemoteDataSource _remote;

  @override
  Future<EvidenceFile?> pickEvidence() => _remote.pickEvidence();

  @override
  Future<String> submit({
    required String userId,
    required String userName,
    required String skillId,
    required String skillName,
    required EvidenceFile file,
    required EvidenceType evidenceType,
    required String note,
    void Function(double progress)? onProgress,
  }) => _remote.submit(
    userId: userId,
    userName: userName,
    skillId: skillId,
    skillName: skillName,
    file: file,
    evidenceType: evidenceType,
    note: note,
    onProgress: onProgress,
  );

  @override
  Stream<List<VerificationRequest>> watchForSkill(
    String userId,
    String skillId,
  ) => _remote.watchForSkill(userId, skillId);

  @override
  Stream<VerificationRequest?> watchRequest(String requestId) =>
      _remote.watchRequest(requestId);

  @override
  Stream<List<VerificationRequest>> watchPending() => _remote.watchPending();

  @override
  Stream<List<VerificationRequest>> watchReviewedBy(String reviewerId) =>
      _remote.watchReviewedBy(reviewerId);

  @override
  Stream<Reviewer?> watchReviewer(String uid) => _remote.watchReviewer(uid);

  @override
  Future<void> decide({
    required VerificationRequest request,
    required Reviewer reviewer,
    required bool approve,
    required String comment,
  }) => _remote.decide(
    request: request,
    reviewer: reviewer,
    approve: approve,
    comment: comment,
  );
}
