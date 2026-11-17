import 'package:nextgig/features/gigs/data/datasources/gig_remote_data_source.dart';
import 'package:nextgig/features/gigs/domain/entities/gig.dart';
import 'package:nextgig/features/gigs/domain/repositories/gig_repository.dart';

class GigRepositoryImpl implements GigRepository {
  GigRepositoryImpl(this._remote);

  final GigRemoteDataSource _remote;

  @override
  Stream<List<Gig>> watchGigs() => _remote.watchGigs();
}
