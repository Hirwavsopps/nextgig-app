import 'package:flutter_bloc/flutter_bloc.dart';

/// Ids of bookmarked gigs. App-wide, so the heart on a gig card AND the
/// saved-count badge in the app bar update from the same state change
/// (this is the "one state update touching two widgets" demo).
class BookmarksCubit extends Cubit<Set<String>> {
  BookmarksCubit() : super(const <String>{});

  void toggle(String gigId) {
    final updated = Set<String>.of(state);
    if (!updated.remove(gigId)) {
      updated.add(gigId);
    }
    emit(updated);
  }
}
