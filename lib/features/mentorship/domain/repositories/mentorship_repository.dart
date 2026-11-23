import 'package:nextgig/features/mentorship/domain/entities/mentorship.dart';

/// Full CRUD on `mentorshipRequests` for the signed-in talent.
abstract class MentorshipRepository {
  /// READ: my requests, newest first.
  Stream<List<MentorshipRequest>> watchMyRequests(String talentId);

  /// CREATE
  Future<void> sendRequest({
    required String talentId,
    required String talentName,
    required String mentorName,
    required String gigId,
    required String gigTitle,
    required String message,
  });

  /// UPDATE: status -> cancelled.
  Future<void> cancelRequest(String requestId);

  /// DELETE: remove a request from my list.
  Future<void> deleteRequest(String requestId);
}
