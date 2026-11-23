import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nextgig/features/gigs/domain/repositories/bookmark_repository.dart';

/// Firestore implementation of [BookmarkRepository].
/// The document id is the gig id, so saving the same gig twice is harmless.
class BookmarkRepositoryImpl implements BookmarkRepository {
  BookmarkRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _bookmarks(String uid) =>
      _firestore.collection('users').doc(uid).collection('bookmarks');

  @override
  Stream<Set<String>> watchBookmarks(String uid) =>
      _bookmarks(uid)
          .snapshots()
          .map((snap) => snap.docs.map((d) => d.id).toSet());

  @override
  Future<void> addBookmark(String uid, String gigId) =>
      _bookmarks(uid)
          .doc(gigId)
          .set({'gigId': gigId, 'createdAt': FieldValue.serverTimestamp()});

  @override
  Future<void> removeBookmark(String uid, String gigId) =>
      _bookmarks(uid).doc(gigId).delete();
}
