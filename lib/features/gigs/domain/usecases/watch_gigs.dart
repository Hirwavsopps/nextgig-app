import 'package:nextgig/features/gigs/domain/entities/gig.dart';
import 'package:nextgig/features/gigs/domain/repositories/gig_repository.dart';

class WatchGigs {
  const WatchGigs(this._repository);

  final GigRepository _repository;

  Stream<List<Gig>> call() => _repository.watchGigs();
}
