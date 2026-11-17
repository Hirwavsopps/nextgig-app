import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nextgig/features/gigs/domain/entities/gig.dart';
import 'package:nextgig/features/gigs/domain/entities/gig_filter.dart';
import 'package:nextgig/features/gigs/domain/usecases/watch_gigs.dart';
import 'package:nextgig/features/gigs/presentation/cubit/gig_feed_state.dart';

/// Holds the live gig list plus the active search/filter.
/// Because it listens to a Firestore stream, new gigs appear without a refresh.
class GigFeedCubit extends Cubit<GigFeedState> {
  GigFeedCubit(this._watchGigs) : super(const GigFeedState());

  final WatchGigs _watchGigs;
  StreamSubscription<List<Gig>>? _subscription;

  void start() {
    emit(state.copyWith(status: GigFeedStatus.loading));
    _subscription?.cancel();
    _subscription = _watchGigs().listen(
      (gigs) =>
          emit(state.copyWith(status: GigFeedStatus.loaded, allGigs: gigs)),
      onError: (Object error) => emit(
        state.copyWith(
          status: GigFeedStatus.failure,
          errorMessage: 'Could not load gigs. Please try again.',
        ),
      ),
    );
  }

  void search(String query) {
    emit(state.copyWith(filter: state.filter.copyWith(query: query)));
  }

  void updateFilter(GigFilter filter) {
    emit(state.copyWith(filter: filter));
  }

  void clearFilters() {
    emit(state.copyWith(filter: const GigFilter()));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
