import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextgig/core/widgets/gig_card.dart';
import 'package:nextgig/features/gigs/domain/entities/gig.dart';

void main() {
  const gig = Gig(
    id: '1',
    title: 'Build a landing page',
    description: 'Simple page',
    category: 'Tech',
    neighborhood: 'Kimironko',
    pay: 25000,
    requiredSkills: ['HTML', 'CSS'],
    posterName: 'Aline Salon',
    posterId: 'user-1',
    applicantCount: 3,
    escrowFunded: true,
    mentorName: 'David Mugisha',
  );

  testWidgets('GigCard shows gig info and reports bookmark taps', (
    tester,
  ) async {
    var bookmarkTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: GigCard(
              gig: gig,
              isBookmarked: false,
              onTap: () {},
              onBookmarkTap: () => bookmarkTaps++,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Build a landing page'), findsOneWidget);
    expect(find.text('25,000 RWF'), findsOneWidget);
    expect(find.textContaining('Kimironko'), findsOneWidget);
    expect(find.text('3 applicants'), findsOneWidget);
    expect(find.text('David Mugisha'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.bookmark_border));
    expect(bookmarkTaps, 1);
  });
}
