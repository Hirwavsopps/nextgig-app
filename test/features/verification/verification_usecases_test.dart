import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nextgig/features/profile/domain/entities/skill.dart';
import 'package:nextgig/features/verification/domain/entities/evidence.dart';
import 'package:nextgig/features/verification/domain/entities/reviewer.dart';
import 'package:nextgig/features/verification/domain/entities/verification_request.dart';
import 'package:nextgig/features/verification/domain/entities/verification_status.dart';
import 'package:nextgig/features/verification/domain/repositories/verification_repository.dart';
import 'package:nextgig/features/verification/domain/usecases/verification_usecases.dart';
import 'package:nextgig/features/verification/presentation/cubit/evidence_upload_cubit.dart';

class MockVerificationRepository extends Mock
    implements VerificationRepository {}

const pdf = EvidenceFile(
  name: 'cert.pdf',
  localPath: '/tmp/cert.pdf',
  sizeBytes: 2048,
);

Skill skillWith(String status) => Skill(
  id: 'figma',
  name: 'Figma',
  proficiency: 'beginner',
  verificationStatus: status,
);

VerificationRequest requestWith(
  VerificationStatus status, {
  String userId = 'aline',
}) => VerificationRequest(
  id: 'r1',
  userId: userId,
  userName: 'Aline',
  skillId: 'figma',
  skillName: 'Figma',
  evidenceUrl: 'https://example.com/cert.pdf',
  evidenceFileName: 'cert.pdf',
  evidencePath: 'verifications/aline/r1/cert.pdf',
  evidenceType: EvidenceType.courseCertificate,
  status: status,
);

const david = Reviewer(
  uid: 'david',
  name: 'David',
  relationship: 'mentor',
  active: true,
);

void main() {
  late MockVerificationRepository repo;

  setUpAll(() {
    registerFallbackValue(pdf);
    registerFallbackValue(EvidenceType.other);
    registerFallbackValue(requestWith(VerificationStatus.pending));
    registerFallbackValue(david);
  });

  setUp(() {
    repo = MockVerificationRepository();
    when(
      () => repo.submit(
        userId: any(named: 'userId'),
        userName: any(named: 'userName'),
        skillId: any(named: 'skillId'),
        skillName: any(named: 'skillName'),
        file: any(named: 'file'),
        evidenceType: any(named: 'evidenceType'),
        note: any(named: 'note'),
        onProgress: any(named: 'onProgress'),
      ),
    ).thenAnswer((invocation) async {
      final onProgress =
          invocation.namedArguments[#onProgress] as void Function(double)?;
      onProgress?.call(0.5);
      onProgress?.call(1);
      return 'r1';
    });
    when(
      () => repo.decide(
        request: any(named: 'request'),
        reviewer: any(named: 'reviewer'),
        approve: any(named: 'approve'),
        comment: any(named: 'comment'),
      ),
    ).thenAnswer((_) async {});
  });

  group('SubmitSkillEvidence', () {
    Future<String> submit(Skill skill, {EvidenceFile? file = pdf}) =>
        SubmitSkillEvidence(repo)(
          userId: 'aline',
          userName: 'Aline',
          skill: skill,
          file: file,
          evidenceType: EvidenceType.courseCertificate,
          note: '  Coursera, 2026  ',
        );

    test('sends an unverified skill with a trimmed note', () async {
      expect(await submit(skillWith('unverified')), 'r1');
      verify(
        () => repo.submit(
          userId: 'aline',
          userName: 'Aline',
          skillId: 'figma',
          skillName: 'Figma',
          file: pdf,
          evidenceType: EvidenceType.courseCertificate,
          note: 'Coursera, 2026',
          onProgress: any(named: 'onProgress'),
        ),
      ).called(1);
    });

    test('a rejected skill can be sent again', () async {
      expect(await submit(skillWith('rejected')), 'r1');
    });

    test('pending and verified skills are refused before uploading', () {
      expect(
        () => submit(skillWith('pending')),
        throwsA(isA<VerificationException>()),
      );
      expect(
        () => submit(skillWith('verified')),
        throwsA(isA<VerificationException>()),
      );
      verifyNever(
        () => repo.submit(
          userId: any(named: 'userId'),
          userName: any(named: 'userName'),
          skillId: any(named: 'skillId'),
          skillName: any(named: 'skillName'),
          file: any(named: 'file'),
          evidenceType: any(named: 'evidenceType'),
          note: any(named: 'note'),
          onProgress: any(named: 'onProgress'),
        ),
      );
    });

    test('a missing or invalid file is refused', () {
      expect(
        () => submit(skillWith('unverified'), file: null),
        throwsA(isA<VerificationException>()),
      );
      expect(
        () => submit(
          skillWith('unverified'),
          file: const EvidenceFile(
            name: 'a.exe',
            localPath: '/a',
            sizeBytes: 1,
          ),
        ),
        throwsA(isA<VerificationException>()),
      );
    });
  });

  group('DecideVerification', () {
    Future<void> decide({
      Reviewer? reviewer = david,
      VerificationRequest? request,
      String comment = 'Certificate checks out.',
    }) => DecideVerification(repo)(
      reviewer: reviewer,
      request: request ?? requestWith(VerificationStatus.pending),
      approve: true,
      comment: comment,
    );

    test('an active reviewer can approve a pending request', () async {
      await decide();
      verify(
        () => repo.decide(
          request: any(named: 'request'),
          reviewer: david,
          approve: true,
          comment: 'Certificate checks out.',
        ),
      ).called(1);
    });

    test('non-reviewers and inactive reviewers are blocked', () {
      expect(
        () => decide(reviewer: null),
        throwsA(isA<VerificationException>()),
      );
      expect(
        () => decide(
          reviewer: const Reviewer(
            uid: 'david',
            name: 'David',
            relationship: 'mentor',
          ),
        ),
        throwsA(isA<VerificationException>()),
      );
    });

    test('reviewers cannot approve their own skill', () {
      expect(
        () => decide(
          request: requestWith(VerificationStatus.pending, userId: 'david'),
        ),
        throwsA(
          isA<VerificationException>().having(
            (e) => e.message,
            'message',
            'You cannot review your own skill.',
          ),
        ),
      );
    });

    test('a request that was already decided cannot be decided again', () {
      expect(
        () => decide(request: requestWith(VerificationStatus.verified)),
        throwsA(isA<VerificationException>()),
      );
      expect(
        () => decide(request: requestWith(VerificationStatus.rejected)),
        throwsA(isA<VerificationException>()),
      );
    });

    test('a comment is required', () {
      expect(
        () => decide(comment: '  '),
        throwsA(isA<VerificationException>()),
      );
      expect(
        () => decide(comment: 'x' * 501),
        throwsA(isA<VerificationException>()),
      );
      verifyNever(
        () => repo.decide(
          request: any(named: 'request'),
          reviewer: any(named: 'reviewer'),
          approve: any(named: 'approve'),
          comment: any(named: 'comment'),
        ),
      );
    });
  });

  group('EvidenceUploadCubit', () {
    EvidenceUploadCubit build() =>
        EvidenceUploadCubit(repo, SubmitSkillEvidence(repo));

    blocTest<EvidenceUploadCubit, EvidenceUploadState>(
      'a picked file that is too large shows an error and cannot be sent',
      setUp: () => when(() => repo.pickEvidence()).thenAnswer(
        (_) async => const EvidenceFile(
          name: 'big.pdf',
          localPath: '/big.pdf',
          sizeBytes: EvidencePolicy.maxBytes + 1,
        ),
      ),
      build: build,
      act: (cubit) => cubit.pickFile(),
      verify: (cubit) {
        expect(cubit.state.fileError, 'The file must be smaller than 5 MB.');
        expect(cubit.state.canSubmit, isFalse);
      },
    );

    blocTest<EvidenceUploadCubit, EvidenceUploadState>(
      'uploading reports progress and ends in success',
      setUp: () => when(() => repo.pickEvidence()).thenAnswer((_) async => pdf),
      build: build,
      act: (cubit) async {
        await cubit.pickFile();
        await cubit.submit(
          userId: 'aline',
          userName: 'Aline',
          skill: skillWith('unverified'),
          note: '',
        );
      },
      skip: 1, // the picked file
      expect: () => [
        isA<EvidenceUploadState>()
            .having((s) => s.phase, 'phase', UploadPhase.uploading)
            .having((s) => s.progress, 'progress', 0),
        isA<EvidenceUploadState>().having((s) => s.progress, 'progress', 0.5),
        isA<EvidenceUploadState>().having((s) => s.progress, 'progress', 1),
        isA<EvidenceUploadState>()
            .having((s) => s.phase, 'phase', UploadPhase.success)
            .having((s) => s.requestId, 'requestId', 'r1'),
      ],
    );

    blocTest<EvidenceUploadCubit, EvidenceUploadState>(
      'a network failure ends in failure with a message',
      setUp: () {
        when(() => repo.pickEvidence()).thenAnswer((_) async => pdf);
        when(
          () => repo.submit(
            userId: any(named: 'userId'),
            userName: any(named: 'userName'),
            skillId: any(named: 'skillId'),
            skillName: any(named: 'skillName'),
            file: any(named: 'file'),
            evidenceType: any(named: 'evidenceType'),
            note: any(named: 'note'),
            onProgress: any(named: 'onProgress'),
          ),
        ).thenThrow(Exception('offline'));
      },
      build: build,
      act: (cubit) async {
        await cubit.pickFile();
        await cubit.submit(
          userId: 'aline',
          userName: 'Aline',
          skill: skillWith('unverified'),
          note: '',
        );
      },
      verify: (cubit) {
        expect(cubit.state.phase, UploadPhase.failure);
        expect(cubit.state.error, isNotNull);
      },
    );
  });
}
