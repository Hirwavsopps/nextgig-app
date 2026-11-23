import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nextgig/features/gigs/domain/repositories/bookmark_repository.dart';
import 'package:nextgig/features/gigs/presentation/cubit/bookmarks_cubit.dart';

/// Keeps bookmarks in memory and pushes them like Firestore would.
class _FakeBookmarks implements BookmarkRepository {
  final _saved = <String>{};
  final _changes = StreamController<Set<String>>.broadcast();
  bool failWrites = false;

  @override
  Stream<Set<String>> watchBookmarks(String uid) async* {
    yield Set.of(_saved);
    yield* _changes.stream;
  }

  @override
  Future<void> addBookmark(String uid, String gigId) async {
    if (failWrites) throw StateError('offline');
    _saved.add(gigId);
    _changes.add(Set.of(_saved));
  }

  @override
  Future<void> removeBookmark(String uid, String gigId) async {
    if (failWrites) throw StateError('offline');
    _saved.remove(gigId);
    _changes.add(Set.of(_saved));
  }
}

void main() {
  test('without a repository it still toggles in memory', () async {
    final cubit = BookmarksCubit();

    cubit.toggle('gig-1');
    expect(cubit.state, {'gig-1'});
    cubit.toggle('gig-1');
    expect(cubit.state, isEmpty);

    await cubit.close();
  });

  test('saves bookmarks for the signed-in user', () async {
    final repo = _FakeBookmarks();
    final cubit = BookmarksCubit(store: repo, userIds: Stream.value('alice'));
    await Future<void>.delayed(Duration.zero);

    cubit.toggle('gig-1');
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state, {'gig-1'});
    expect(repo._saved, {'gig-1'});
    await cubit.close();
  });

  test('undoes the change on screen when saving fails', () async {
    final repo = _FakeBookmarks()..failWrites = true;
    final cubit = BookmarksCubit(store: repo, userIds: Stream.value('alice'));
    await Future<void>.delayed(Duration.zero);

    cubit.toggle('gig-1');
    expect(cubit.state, {'gig-1'}); // instant
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state, isEmpty); // reverted
    await cubit.close();
  });
}
