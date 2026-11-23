/// Saved gigs, stored per user in `users/{uid}/bookmarks/{gigId}`.
abstract class BookmarkRepository {
  /// READ: the ids of the gigs this user saved, live.
  Stream<Set<String>> watchBookmarks(String uid);

  /// CREATE
  Future<void> addBookmark(String uid, String gigId);

  /// DELETE
  Future<void> removeBookmark(String uid, String gigId);
}
