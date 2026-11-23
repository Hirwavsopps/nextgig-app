import 'package:nextgig/features/gigs/data/datasources/gig_remote_data_source.dart';
import 'package:nextgig/features/gigs/data/models/gig_model.dart';
import 'package:nextgig/features/gigs/domain/entities/gig.dart';
import 'package:nextgig/features/gigs/domain/repositories/gig_repository.dart';

class GigRepositoryImpl implements GigRepository {
  GigRepositoryImpl(this._remote);

  final GigRemoteDataSource _remote;

  @override
  Stream<List<Gig>> watchGigs() => _remote.watchGigs();

  @override
  Stream<List<Gig>> watchPostedBy(String posterId) =>
      _remote.watchPostedBy(posterId);

  @override
  Future<void> createGig(Gig gig) => _remote.createGig(GigModel.fromGig(gig));

  @override
  Future<void> updateGig(Gig gig) => _remote.updateGig(GigModel.fromGig(gig));

  @override
  Future<void> deleteGig(String gigId) => _remote.deleteGig(gigId);
}
