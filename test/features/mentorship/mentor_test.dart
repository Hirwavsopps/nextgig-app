import 'package:flutter_test/flutter_test.dart';
import 'package:nextgig/features/gigs/domain/entities/gig.dart';
import 'package:nextgig/features/mentorship/domain/entities/mentorship.dart';

Gig _gig(String id, {String? mentor}) => Gig(
  id: id,
  title: 'Gig $id',
  description: '',
  category: 'Tech',
  neighborhood: 'Remera',
  pay: 10000,
  requiredSkills: const [],
  posterName: 'Client',
  posterId: 'poster',
  duration: '',
  level: '',
  applicantCount: 0,
  verifiedClient: false,
  escrowFunded: false,
  deliverables: const [],
  mentorName: mentor,
);

void main() {
  test('Mentor splits "Name (Title)" into name and title', () {
    const mentor = Mentor(
      fullLabel: 'David Mugisha (Senior Creative Lead)',
      gigs: [],
    );
    expect(mentor.name, 'David Mugisha');
    expect(mentor.title, 'Senior Creative Lead');
    expect(const Mentor(fullLabel: 'Aline', gigs: []).title, 'Mentor');
  });

  test(
    'fromGigs groups gigs by mentor, busiest first, skipping unmentored',
    () {
      final mentors = Mentor.fromGigs([
        _gig('1', mentor: 'Aline (Designer)'),
        _gig('2'),
        _gig('3', mentor: 'Eric (Engineer)'),
        _gig('4', mentor: 'Eric (Engineer)'),
        _gig('5', mentor: '   '),
      ]);

      expect(mentors.map((m) => m.name), ['Eric', 'Aline']);
      expect(mentors.first.gigs.map((g) => g.id), ['3', '4']);
    },
  );
}
