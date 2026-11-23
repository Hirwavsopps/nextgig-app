import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nextgig/features/gigs/domain/entities/gig.dart';
import 'package:nextgig/features/gigs/domain/usecases/watch_gigs.dart';
import 'package:nextgig/features/mentorship/domain/entities/mentorship.dart';
import 'package:nextgig/features/mentorship/domain/repositories/mentorship_repository.dart';

enum MentorshipLoad { loading, loaded, failure }

class MentorshipState extends Equatable {
  const MentorshipState({
    this.status = MentorshipLoad.loading,
    this.mentors = const [],
    this.requests = const [],
    this.isSending = false,
    this.message,
  });

  final MentorshipLoad status;
  final List<Mentor> mentors;
  final List<MentorshipRequest> requests;
  final bool isSending;

  /// One-shot SnackBar text.
  final String? message;

  List<Gig> get mentoredGigs => [for (final m in mentors) ...m.gigs];

  int get pendingCount => requests.where((r) => r.isPending).length;

  /// True if I already have a pending request for this mentor on this gig.
  bool hasPending(String mentorName, String gigId) => requests.any(
    (r) => r.isPending && r.mentorName == mentorName && r.gigId == gigId,
  );

  MentorshipState copyWith({
    MentorshipLoad? status,
    List<Mentor>? mentors,
    List<MentorshipRequest>? requests,
    bool? isSending,
    String? message,
  }) {
    return MentorshipState(
      status: status ?? this.status,
      mentors: mentors ?? this.mentors,
      requests: requests ?? this.requests,
      isSending: isSending ?? this.isSending,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, mentors, requests, isSending, message];
}

/// Mentor Dashboard: mentors (from gigs) + my requests, both live.
class MentorshipCubit extends Cubit<MentorshipState> {
  MentorshipCubit(this._watchGigs, this._repository)
    : super(const MentorshipState());

  final WatchGigs _watchGigs;
  final MentorshipRepository _repository;
  StreamSubscription<List<Gig>>? _gigsSub;
  StreamSubscription<List<MentorshipRequest>>? _requestsSub;
  late String _uid;
  late String _name;

  void start({required String uid, required String name}) {
    _uid = uid;
    _name = name;
    _gigsSub?.cancel();
    _requestsSub?.cancel();
    _gigsSub = _watchGigs().listen(
      (gigs) => emit(
        state.copyWith(
          status: MentorshipLoad.loaded,
          mentors: Mentor.fromGigs(gigs),
        ),
      ),
      onError: (Object _) =>
          emit(state.copyWith(status: MentorshipLoad.failure)),
    );
    _requestsSub = _repository
        .watchMyRequests(uid)
        .listen(
          (requests) => emit(state.copyWith(requests: requests)),
          onError: (Object _) {},
        );
  }

  /// CREATE a request. Returns true when sent so the sheet can close.
  Future<bool> sendRequest({
    required Mentor mentor,
    required Gig gig,
    required String message,
  }) async {
    if (message.trim().isEmpty || state.isSending) return false;
    if (state.hasPending(mentor.fullLabel, gig.id)) {
      emit(
        state.copyWith(
          message: 'You already asked this mentor about this gig.',
        ),
      );
      return false;
    }
    emit(state.copyWith(isSending: true));
    try {
      await _repository.sendRequest(
        talentId: _uid,
        talentName: _name,
        mentorName: mentor.fullLabel,
        gigId: gig.id,
        gigTitle: gig.title,
        message: message,
      );
      emit(
        state.copyWith(
          isSending: false,
          message: 'Request sent to ${mentor.name}.',
        ),
      );
      return true;
    } catch (_) {
      emit(
        state.copyWith(
          isSending: false,
          message: 'Could not send the request. Try again.',
        ),
      );
      return false;
    }
  }

  /// UPDATE
  Future<void> cancel(MentorshipRequest request) async {
    try {
      await _repository.cancelRequest(request.id);
      emit(state.copyWith(message: 'Request cancelled.'));
    } catch (_) {
      emit(state.copyWith(message: 'Could not cancel. Try again.'));
    }
  }

  /// DELETE
  Future<void> remove(MentorshipRequest request) async {
    try {
      await _repository.deleteRequest(request.id);
    } catch (_) {
      emit(state.copyWith(message: 'Could not remove. Try again.'));
    }
  }

  @override
  Future<void> close() async {
    await _gigsSub?.cancel();
    await _requestsSub?.cancel();
    return super.close();
  }
}
