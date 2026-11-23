import 'package:nextgig/features/gigs/domain/entities/gig.dart';

class ScoredGig {
  const ScoredGig(this.gig, this.score);

  final Gig gig;

  /// How many verified skill names overlap this gig's required skills.
  final int score;
}

/// Scores gigs by overlap with verified skills. Unverified skills and
/// zero-score gigs are dropped. Highest overlap first, then higher pay.
List<ScoredGig> recommendGigs(
  List<Gig> gigs,
  Iterable<({String name, bool verified})> skills,
) {
  final verified = skills
      .where((skill) => skill.verified && skill.name.trim().isNotEmpty)
      .map((skill) => skill.name.trim().toLowerCase())
      .toSet();
  if (verified.isEmpty) return const [];

  final scored = <ScoredGig>[];
  for (final gig in gigs) {
    final overlap = gig.requiredSkills
        .map((skill) => skill.trim().toLowerCase())
        .where(verified.contains)
        .toSet()
        .length;
    if (overlap > 0) scored.add(ScoredGig(gig, overlap));
  }
  scored.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    return b.gig.pay.compareTo(a.gig.pay);
  });
  return scored;
}
