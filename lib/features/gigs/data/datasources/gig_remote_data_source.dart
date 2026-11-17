import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nextgig/features/gigs/data/models/gig_model.dart';

abstract class GigRemoteDataSource {
  Stream<List<GigModel>> watchGigs();
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
}
