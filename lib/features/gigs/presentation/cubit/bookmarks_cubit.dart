import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nextgig/features/gigs/domain/repositories/bookmark_repository.dart';

/// Ids of bookmarked gigs. App-wide, so the heart on a gig card AND the
/// saved-count badge in the app bar update from the same state change
/// (this is the "one state update touching two widgets" demo).
///
/// With a [BookmarkRepository] and a stream of the signed-in uid, bookmarks
/// are also saved to Firestore (`users/{uid}/bookmarks`) so they survive a
/// restart. Without them it works in memory only, exactly as before.
class BookmarksCubit extends Cubit<Set<String>> {
  BookmarksCubit({BookmarkRepository? store, Stream<String?>? userIds})
    : _repository = store,
      super(const <String>{}) {
    _userSub = userIds?.listen(_onUser);
  }

  final BookmarkRepository? _repository;
  StreamSubscription<String?>? _userSub;
  StreamSubscription<Set<String>>? _bookmarksSub;
  String? _uid;

  void _onUser(String? uid) {
    _uid = uid;
    _bookmarksSub?.cancel();
    _bookmarksSub = null;
    final repository = _repository;
    if (uid == null || repository == null) {
      emit(const <String>{});
      return;
    }
    _bookmarksSub = repository
        .watchBookmarks(uid)
        .listen(emit, onError: (_) {});
  }

  void toggle(String gigId) {
    final updated = Set<String>.of(state);
    final removing = updated.remove(gigId);
    if (!removing) {
      updated.add(gigId);
    }
    // Update both widgets instantly; Firestore confirms right after.
    emit(updated);
    final repository = _repository;
    final uid = _uid;
    if (repository == null || uid == null) return;
    final write = removing
        ? repository.removeBookmark(uid, gigId)
        : repository.addBookmark(uid, gigId);
    write.catchError((Object _) {
      // Undo the change on screen if the save failed.
      if (isClosed) return;
      final reverted = Set<String>.of(state);
      removing ? reverted.add(gigId) : reverted.remove(gigId);
      emit(reverted);
    });
  }

  @override
  Future<void> close() async {
    await _userSub?.cancel();
    await _bookmarksSub?.cancel();
    return super.close();
  }
}
