import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nextgig/features/notifications/domain/entities/app_notification.dart';
import 'package:nextgig/features/notifications/domain/usecases/notification_usecases.dart';
import 'package:nextgig/features/verification/domain/entities/reviewer.dart';
import 'package:nextgig/features/verification/domain/entities/verification_request.dart';
import 'package:nextgig/features/verification/domain/repositories/verification_repository.dart';
import 'package:nextgig/features/verification/domain/usecases/verification_usecases.dart';

class VerificationDecisionState extends Equatable {
  const VerificationDecisionState({
    this.loading = true,
    this.request,
    this.reviewer,
    this.submitting = false,
    this.error,
    this.message,
  });

  final bool loading;

  /// Null once loaded means the request does not exist or cannot be read.
  final VerificationRequest? request;
  final Reviewer? reviewer;
  final bool submitting;
  final String? error;

  /// One-off success text, shown as a SnackBar.
  final String? message;

  /// Why the decision buttons are hidden, or null when they are shown.
  String? get blockReason {
    final current = request;
    if (current == null) return 'This request is not available.';
    return DecideVerification.blockReason(reviewer, current);
  }

  VerificationDecisionState copyWith({
    bool? loading,
    VerificationRequest? request,
    Reviewer? reviewer,
    bool? submitting,
    String? error,
    String? message,
  }) => VerificationDecisionState(
    loading: loading ?? this.loading,
    request: request ?? this.request,
    reviewer: reviewer ?? this.reviewer,
    submitting: submitting ?? this.submitting,
    error: error,
    message: message,
  );

  @override
  List<Object?> get props => [
    loading,
    request,
    reviewer,
    submitting,
    error,
    message,
  ];
}

class VerificationDecisionCubit extends Cubit<VerificationDecisionState> {
  VerificationDecisionCubit(this._repo, this._decide, [this._notify])
    : super(const VerificationDecisionState());

  final VerificationRepository _repo;
  final DecideVerification _decide;
  final SendNotification? _notify;
  StreamSubscription<VerificationRequest?>? _requestSub;
  StreamSubscription<Reviewer?>? _reviewerSub;

  void watch({required String requestId, required String viewerId}) {
    _requestSub?.cancel();
    _reviewerSub?.cancel();
    _reviewerSub = _repo
        .watchReviewer(viewerId)
        .listen(
          // Built in full so a removed reviewer goes back to null.
          (reviewer) => emit(
            VerificationDecisionState(
              loading: state.loading,
              request: state.request,
              reviewer: reviewer,
              submitting: state.submitting,
            ),
          ),
          onError: (_) {},
        );
    _requestSub = _repo
        .watchRequest(requestId)
        .listen(
          (request) => emit(
            VerificationDecisionState(
              loading: false,
              request: request,
              reviewer: state.reviewer,
              submitting: state.submitting,
            ),
          ),
          onError: (_) => emit(
            VerificationDecisionState(
              loading: false,
              reviewer: state.reviewer,
              error: 'You do not have access to this request.',
            ),
          ),
        );
  }

  /// Returns true when the decision was saved.
  Future<bool> decide({required bool approve, required String comment}) async {
    final request = state.request;
    if (request == null || state.submitting) return false;
    emit(state.copyWith(submitting: true));
    try {
      await _decide(
        reviewer: state.reviewer,
        request: request,
        approve: approve,
        comment: comment,
      );
      emit(
        state.copyWith(
          submitting: false,
          message: approve
              ? '${request.skillName} is now verified.'
              : 'Feedback sent to ${request.userName}.',
        ),
      );
      unawaited(_tellOwner(request, approve, comment));
      return true;
    } on VerificationException catch (error) {
      emit(state.copyWith(submitting: false, error: error.message));
    } catch (_) {
      emit(
        state.copyWith(
          submitting: false,
          error: 'Could not save your decision. Try again.',
        ),
      );
    }
    return false;
  }

  /// Best effort: the decision is already saved if this fails.
  Future<void> _tellOwner(
    VerificationRequest request,
    bool approve,
    String comment,
  ) async {
    final notify = _notify;
    if (notify == null) return;
    try {
      await notify(
        toUserId: request.userId,
        type: NotificationType.system,
        title: approve
            ? '${request.skillName} verified'
            : '${request.skillName} needs new evidence',
        body: comment.trim(),
      );
    } catch (_) {}
  }

  @override
  Future<void> close() async {
    await _requestSub?.cancel();
    await _reviewerSub?.cancel();
    return super.close();
  }
}
