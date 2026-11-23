import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nextgig/features/gigs/data/models/gig_model.dart';

abstract class GigRemoteDataSource {
  Stream<List<GigModel>> watchGigs();

  Stream<List<GigModel>> watchPostedBy(String posterId);

  Future<void> createGig(GigModel gig);

  Future<void> updateGig(GigModel gig);

  Future<void> deleteGig(String gigId);
}

class GigRemoteDataSourceImpl implements GigRemoteDataSource {
  GigRemoteDataSourceImpl(this._firestore);

  final FirebaseFirestore _firestore;

  /// Note: documents without a `createdAt` field are excluded by orderBy.
  @override
  Stream<List<GigModel>> watchGigs() {
    return _firestore
        .collection('gigs')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GigModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Stream<List<GigModel>> watchPostedBy(String posterId) {
    return _firestore
        .collection('gigs')
        .where('posterId', isEqualTo: posterId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GigModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Future<void> createGig(GigModel gig) {
    return _firestore.collection('gigs').add(gig.toMap(create: true));
  }

  @override
  Future<void> updateGig(GigModel gig) {
    return _firestore.collection('gigs').doc(gig.id).update(gig.toMap());
  }

  @override
  Future<void> deleteGig(String gigId) {
    return _firestore.collection('gigs').doc(gigId).delete();
  }
}
