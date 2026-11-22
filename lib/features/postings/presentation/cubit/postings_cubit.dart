import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nextgig/features/applications/data/application_repository.dart';
import 'package:nextgig/features/applications/domain/entities/gig_application.dart';
import 'package:nextgig/features/gigs/domain/entities/gig.dart';
import 'package:nextgig/features/gigs/domain/repositories/gig_repository.dart';

class PostingsState extends Equatable {
  const PostingsState({
    this.gigs = const [],
    this.applications = const [],
    this.error,
  });

  final List<Gig> gigs;
  final List<GigApplication> applications;
  final String? error;

  PostingsState copyWith({
    List<Gig>? gigs,
    List<GigApplication>? applications,
    String? error,
  }) {
    return PostingsState(
      gigs: gigs ?? this.gigs,
      applications: applications ?? this.applications,
      error: error,
    );
  }

  @override
  List<Object?> get props => [gigs, applications, error];
}

class PostingsCubit extends Cubit<PostingsState> {
  PostingsCubit(this._gigs, this._applications) : super(const PostingsState());

  final GigRepository _gigs;
  final ApplicationRepository _applications;
  StreamSubscription<List<Gig>>? _gigSub;
  StreamSubscription<List<GigApplication>>? _appSub;

  void watch(String uid) {
    _gigSub?.cancel();
    _appSub?.cancel();
    _gigSub = _gigs
        .watchPostedBy(uid)
        .listen(
          (gigs) => emit(state.copyWith(gigs: gigs)),
          onError: (_) =>
              emit(state.copyWith(error: 'Could not load your gigs.')),
        );
    _appSub = _applications
        .watchByApplicant(uid)
        .listen(
          (applications) => emit(state.copyWith(applications: applications)),
          onError: (_) =>
              emit(state.copyWith(error: 'Could not load your applications.')),
        );
  }

  Future<void> deleteGig(String gigId) async {
    try {
      await _gigs.deleteGig(gigId);
    } catch (_) {
      emit(state.copyWith(error: 'Could not delete the gig.'));
      rethrow;
    }
  }

  @override
  Future<void> close() async {
    await _gigSub?.cancel();
    await _appSub?.cancel();
    return super.close();
  }
}
