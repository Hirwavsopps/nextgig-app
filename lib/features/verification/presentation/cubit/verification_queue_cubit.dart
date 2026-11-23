import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nextgig/features/verification/domain/entities/reviewer.dart';
import 'package:nextgig/features/verification/domain/entities/verification_request.dart';
import 'package:nextgig/features/verification/domain/repositories/verification_repository.dart';

class VerificationQueueState extends Equatable {
  const VerificationQueueState({
    this.loading = true,
    this.reviewer,
    this.pending = const [],
    this.reviewed = const [],
    this.error,
  });

  final bool loading;
  final Reviewer? reviewer;

  /// Waiting requests from other people, oldest first.
  final List<VerificationRequest> pending;

  /// Requests this reviewer decided, newest first.
  final List<VerificationRequest> reviewed;
  final String? error;

  bool get isReviewer => reviewer?.active ?? false;

  @override
  List<Object?> get props => [loading, reviewer, pending, reviewed, error];
}

/// Knows whether the signed-in user is an authorized reviewer, and if so
/// keeps their queue up to date. Non-reviewers never query the requests,
/// which the rules would refuse anyway.
class VerificationQueueCubit extends Cubit<VerificationQueueState> {
  VerificationQueueCubit(this._repo) : super(const VerificationQueueState());

  final VerificationRepository _repo;
  StreamSubscription<Reviewer?>? _reviewerSub;
  StreamSubscription<List<VerificationRequest>>? _pendingSub;
  StreamSubscription<List<VerificationRequest>>? _reviewedSub;
  String _uid = '';

  void watch(String uid) {
    _uid = uid;
    _reviewerSub?.cancel();
    _reviewerSub = _repo.watchReviewer(uid).listen((reviewer) {
      final active = reviewer?.active ?? false;
      if (!active) {
        _stopQueue();
        emit(VerificationQueueState(loading: false, reviewer: reviewer));
        return;
      }
      emit(
        VerificationQueueState(
          loading: _pendingSub == null,
          reviewer: reviewer,
          pending: state.pending,
          reviewed: state.reviewed,
        ),
      );
      _startQueue();
    }, onError: (_) => _fail('Could not check reviewer access.'));
  }

  void _startQueue() {
    _pendingSub ??= _repo.watchPending().listen(
      (requests) => _emit(
        pending: [
          for (final request in requests)
            if (request.userId != _uid) request,
        ],
      ),
      onError: (_) => _fail('Could not load the endorsement queue.'),
    );
    _reviewedSub ??= _repo
        .watchReviewedBy(_uid)
        .listen(
          (requests) => _emit(reviewed: requests),
          onError: (_) => _fail('Could not load your past reviews.'),
        );
  }

  void _stopQueue() {
    _pendingSub?.cancel();
    _reviewedSub?.cancel();
    _pendingSub = null;
    _reviewedSub = null;
  }

  void _emit({
    List<VerificationRequest>? pending,
    List<VerificationRequest>? reviewed,
  }) {
    emit(
      VerificationQueueState(
        loading: false,
        reviewer: state.reviewer,
        pending: pending ?? state.pending,
        reviewed: reviewed ?? state.reviewed,
      ),
    );
  }

  void _fail(String message) => emit(
    VerificationQueueState(
      loading: false,
      reviewer: state.reviewer,
      pending: state.pending,
      reviewed: state.reviewed,
      error: message,
    ),
  );

  @override
  Future<void> close() async {
    await _reviewerSub?.cancel();
    _stopQueue();
    return super.close();
  }
}
