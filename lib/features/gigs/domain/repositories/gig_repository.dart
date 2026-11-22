import 'package:nextgig/features/gigs/domain/entities/gig.dart';

/// Contract the presentation layer depends on. The data layer implements it.
abstract class GigRepository {
  /// Live list of gigs, newest first. Emits again whenever Firestore changes.
  Stream<List<Gig>> watchGigs();

  Stream<List<Gig>> watchPostedBy(String posterId);

  Future<void> createGig(Gig gig);

  Future<void> updateGig(Gig gig);

  Future<void> deleteGig(String gigId);
}
