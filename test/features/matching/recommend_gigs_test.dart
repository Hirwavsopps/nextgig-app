import 'package:flutter_test/flutter_test.dart';
import 'package:nextgig/features/gigs/domain/entities/gig.dart';
import 'package:nextgig/features/matching/domain/recommend_gigs.dart';

Gig _gig(String id, int pay, List<String> skills) {
  return Gig(
    id: id,
    title: id,
    description: '',
    category: 'Tech',
    neighborhood: 'Remera',
    pay: pay,
    requiredSkills: skills,
    posterName: 'Aline',
    posterId: 'poster',
  );
}

void main() {
  const skills = [
    (name: 'Flutter', verified: true),
    (name: 'Figma', verified: false),
    (name: ' firebase ', verified: true),
  ];

  test(
    'scores only verified skills, drops zeros, and sorts by overlap then pay',
    () {
      final scored = recommendGigs([
        _gig('none', 999999, ['Cooking']),
        _gig('one-low', 10000, ['flutter']),
        _gig('one-high', 80000, ['Firebase']),
        _gig('both', 20000, ['Flutter', 'Firebase']),
        _gig('unverified', 50000, ['Figma']),
      ], skills);

      expect(scored.map((item) => item.gig.id), [
        'both',
        'one-high',
        'one-low',
      ]);
      expect(scored.first.score, 2);
      expect(scored[1].score, 1);
    },
  );
}
