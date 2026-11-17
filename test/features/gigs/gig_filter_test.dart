import 'package:flutter_test/flutter_test.dart';
import 'package:nextgig/features/gigs/domain/entities/gig.dart';
import 'package:nextgig/features/gigs/domain/entities/gig_filter.dart';

Gig _gig({
  required String id,
  String title = 'Sample gig',
  String category = 'Tech',
  String neighborhood = 'Kimironko',
  int pay = 50000,
  List<String> skills = const ['Flutter'],
}) {
  return Gig(
    id: id,
    title: title,
    description: 'Description',
    category: category,
    neighborhood: neighborhood,
    pay: pay,
    requiredSkills: skills,
    posterName: 'Poster',
    posterId: 'user-1',
  );
}

void main() {
  final gigs = [
    _gig(id: '1', title: 'Landing page', category: 'Tech', pay: 60000),
    _gig(
      id: '2',
      title: 'Logo design',
      category: 'Design',
      neighborhood: 'Remera',
      pay: 30000,
      skills: ['Illustrator'],
    ),
    _gig(
      id: '3',
      title: 'Math tutor',
      category: 'Tutoring',
      neighborhood: 'Remera',
      pay: 20000,
      skills: ['Mathematics'],
    ),
  ];

  test('an empty filter returns every gig', () {
    expect(const GigFilter().apply(gigs), gigs);
    expect(const GigFilter().isActive, isFalse);
  });

  test('filters by category', () {
    final result = const GigFilter(category: 'Design').apply(gigs);
    expect(result.map((g) => g.id), ['2']);
  });

  test('filters by neighborhood and pay range together', () {
    final result = const GigFilter(
      neighborhood: 'Remera',
      minPay: 25000,
      maxPay: 40000,
    ).apply(gigs);
    expect(result.map((g) => g.id), ['2']);
  });

  test('search matches title and required skills, ignoring case', () {
    expect(const GigFilter(query: 'LANDING').apply(gigs).map((g) => g.id), [
      '1',
    ]);
    expect(const GigFilter(query: 'mathematics').apply(gigs).map((g) => g.id), [
      '3',
    ]);
  });
}
