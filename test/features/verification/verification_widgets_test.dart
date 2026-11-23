import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nextgig/features/profile/domain/entities/skill.dart';
import 'package:nextgig/features/verification/domain/entities/evidence.dart';
import 'package:nextgig/features/verification/domain/entities/reviewer.dart';
import 'package:nextgig/features/verification/domain/entities/verification_request.dart';
import 'package:nextgig/features/verification/domain/entities/verification_status.dart';
import 'package:nextgig/features/verification/domain/repositories/verification_repository.dart';
import 'package:nextgig/features/verification/domain/usecases/verification_usecases.dart';
import 'package:nextgig/features/verification/presentation/cubit/verification_decision_cubit.dart';
import 'package:nextgig/features/verification/presentation/screens/review_request_screen.dart';
import 'package:nextgig/features/verification/presentation/widgets/verification_badge.dart';
import 'package:nextgig/features/verification/presentation/widgets/verification_widgets.dart';

class MockVerificationRepository extends Mock
    implements VerificationRepository {}

const pending = VerificationRequest(
  id: 'r1',
  userId: 'aline',
  userName: 'Aline',
  skillId: 'figma',
  skillName: 'Figma',
  evidenceUrl: '',
  evidenceFileName: 'figma-course.pdf',
  evidencePath: 'verifications/aline/r1/figma-course.pdf',
  evidenceContentType: 'application/pdf',
  evidenceType: EvidenceType.courseCertificate,
  status: VerificationStatus.pending,
);

const david = Reviewer(
  uid: 'david',
  name: 'David Mugisha',
  relationship: 'mentor',
  active: true,
);

void main() {
  group('VerificationBadge', () {
    for (final status in VerificationStatus.values) {
      testWidgets('shows the ${status.name} label', (tester) async {
        await tester.pumpWidget(
          MaterialApp(home: VerificationBadge(status: status)),
        );
        expect(find.text(status.label.toUpperCase()), findsOneWidget);
      });
    }

    testWidgets('only the verified badge has the check mark', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Column(
            children: [
              VerificationBadge(status: VerificationStatus.verified),
              VerificationBadge(status: VerificationStatus.pending),
              VerificationBadge(status: VerificationStatus.unverified),
            ],
          ),
        ),
      );
      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
    });

    testWidgets('verified skills show who endorsed them and when', (
      tester,
    ) async {
      final skill = Skill(
        id: 'flutter',
        name: 'Flutter',
        proficiency: 'intermediate',
        verified: true,
        verificationStatus: 'verified',
        verifiedByName: 'David Mugisha',
        verifiedByRelationship: 'lecturer',
        verifiedAt: DateTime(2026, 11, 20),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: VerifiedByLine(skill: skill)),
        ),
      );
      expect(
        find.text('Verified by David Mugisha · Lecturer · 20 Nov 2026'),
        findsOneWidget,
      );
    });

    testWidgets('pending skills show no endorsement line', (tester) async {
      const skill = Skill(
        id: 'figma',
        name: 'Figma',
        proficiency: 'beginner',
        verificationStatus: 'pending',
        verifiedByName: 'Should not show',
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: VerifiedByLine(skill: skill)),
        ),
      );
      expect(find.textContaining('Verified by'), findsNothing);
    });
  });

  group('ReviewRequestScreen', () {
    late MockVerificationRepository repo;
    late StreamController<VerificationRequest?> request;
    late StreamController<Reviewer?> reviewer;

    setUpAll(() {
      registerFallbackValue(pending);
      registerFallbackValue(david);
    });

    setUp(() {
      repo = MockVerificationRepository();
      request = StreamController<VerificationRequest?>();
      reviewer = StreamController<Reviewer?>();
      when(() => repo.watchRequest('r1')).thenAnswer((_) => request.stream);
      when(() => repo.watchReviewer(any())).thenAnswer((_) => reviewer.stream);
      when(
        () => repo.decide(
          request: any(named: 'request'),
          reviewer: any(named: 'reviewer'),
          approve: any(named: 'approve'),
          comment: any(named: 'comment'),
        ),
      ).thenAnswer((_) async {});
    });

    tearDown(() async {
      await request.close();
      await reviewer.close();
    });

    Future<void> pump(WidgetTester tester, Reviewer? as) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) =>
                VerificationDecisionCubit(repo, DecideVerification(repo))
                  ..watch(requestId: 'r1', viewerId: as?.uid ?? 'stranger'),
            child: const ReviewRequestScreen(),
          ),
        ),
      );
      reviewer.add(as);
      await tester.pump();
      request.add(pending);
      await tester.pumpAndSettle();
    }

    testWidgets('a reviewer endorses with a comment after confirming', (
      tester,
    ) async {
      await pump(tester, david);

      expect(find.text('figma-course.pdf'), findsWidgets);
      final endorse = find.widgetWithText(FilledButton, 'Endorse');

      // A comment is required.
      await tester.ensureVisible(endorse);
      await tester.tap(endorse);
      await tester.pump();
      expect(
        find.text('Add a short comment explaining your decision.'),
        findsOneWidget,
      );

      await tester.enterText(
        find.byType(TextFormField),
        'Certificate matches her portfolio.',
      );
      await tester.ensureVisible(endorse);
      await tester.tap(endorse);
      await tester.pumpAndSettle();
      expect(find.text('Endorse Figma?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Endorse').last);
      await tester.pumpAndSettle();

      verify(
        () => repo.decide(
          request: pending,
          reviewer: david,
          approve: true,
          comment: 'Certificate matches her portfolio.',
        ),
      ).called(1);
      expect(find.text('Figma is now verified.'), findsOneWidget);
    });

    testWidgets('non-reviewers see no decision buttons', (tester) async {
      await pump(tester, null);

      expect(
        find.text('Only authorized reviewers can endorse skills.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, 'Endorse'), findsNothing);
      expect(find.text('Reject'), findsNothing);
    });

    testWidgets('the owner cannot review their own request', (tester) async {
      await pump(
        tester,
        const Reviewer(
          uid: 'aline',
          name: 'Aline',
          relationship: 'mentor',
          active: true,
        ),
      );

      expect(find.text('You cannot review your own skill.'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Endorse'), findsNothing);
    });
  });
}
