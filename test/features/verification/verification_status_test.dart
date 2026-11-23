import 'package:flutter_test/flutter_test.dart';
import 'package:nextgig/features/profile/domain/entities/skill.dart';
import 'package:nextgig/features/verification/domain/entities/evidence.dart';
import 'package:nextgig/features/verification/domain/entities/verification_status.dart';

void main() {
  group('VerificationStatus transitions', () {
    const s = VerificationStatus.values;

    test('only the documented workflow moves are allowed', () {
      final allowed = <(VerificationStatus, VerificationStatus)>{
        for (final from in s)
          for (final to in s)
            if (from.canTransitionTo(to)) (from, to),
      };
      expect(allowed, {
        (VerificationStatus.unverified, VerificationStatus.pending),
        (VerificationStatus.rejected, VerificationStatus.pending),
        (VerificationStatus.pending, VerificationStatus.verified),
        (VerificationStatus.pending, VerificationStatus.rejected),
      });
    });

    test('a skill cannot jump from unverified straight to verified', () {
      expect(
        VerificationStatus.unverified.canTransitionTo(
          VerificationStatus.verified,
        ),
        isFalse,
      );
    });

    test('a verified skill never changes again', () {
      for (final next in s) {
        expect(VerificationStatus.verified.canTransitionTo(next), isFalse);
      }
    });

    test('evidence can be sent only when unverified or rejected', () {
      expect(VerificationStatus.unverified.canSubmitEvidence, isTrue);
      expect(VerificationStatus.rejected.canSubmitEvidence, isTrue);
      expect(VerificationStatus.pending.canSubmitEvidence, isFalse);
      expect(VerificationStatus.verified.canSubmitEvidence, isFalse);
    });
  });

  group('VerificationStatus.parse', () {
    test('reads stored names', () {
      expect(VerificationStatus.parse('pending'), VerificationStatus.pending);
      expect(VerificationStatus.parse('rejected'), VerificationStatus.rejected);
    });

    test('unknown or missing values are unverified', () {
      expect(VerificationStatus.parse(null), VerificationStatus.unverified);
      expect(VerificationStatus.parse('hacked'), VerificationStatus.unverified);
    });

    test('older skills with only verified == true stay verified', () {
      const legacy = Skill(
        id: 's',
        name: 'Flutter',
        proficiency: 'advanced',
        verified: true,
      );
      expect(legacy.status, VerificationStatus.verified);
      expect(legacy.isVerified, isTrue);
    });

    test('an explicit status wins over the legacy flag', () {
      const skill = Skill(
        id: 's',
        name: 'Flutter',
        proficiency: 'advanced',
        verificationStatus: 'pending',
      );
      expect(skill.isVerified, isFalse);
    });
  });

  group('EvidencePolicy', () {
    EvidenceFile file(String name, int size) =>
        EvidenceFile(name: name, localPath: '/tmp/$name', sizeBytes: size);

    test('accepts PDF, JPG and PNG up to 5 MB', () {
      expect(EvidencePolicy.validate(file('cert.pdf', 1024)), isNull);
      expect(EvidencePolicy.validate(file('shot.JPG', 1024)), isNull);
      expect(EvidencePolicy.validate(file('shot.jpeg', 1024)), isNull);
      expect(
        EvidencePolicy.validate(file('shot.png', EvidencePolicy.maxBytes)),
        isNull,
      );
    });

    test('rejects other file types', () {
      expect(EvidencePolicy.validate(file('virus.exe', 10)), isNotNull);
      expect(EvidencePolicy.validate(file('noextension', 10)), isNotNull);
      expect(EvidencePolicy.validate(file('doc.docx', 10)), isNotNull);
    });

    test('rejects empty and oversized files', () {
      expect(EvidencePolicy.validate(file('cert.pdf', 0)), isNotNull);
      expect(
        EvidencePolicy.validate(file('cert.pdf', EvidencePolicy.maxBytes + 1)),
        'The file must be smaller than 5 MB.',
      );
    });

    test('content type follows the extension', () {
      expect(EvidencePolicy.contentTypeFor('pdf'), 'application/pdf');
      expect(EvidencePolicy.contentTypeFor('png'), 'image/png');
      expect(EvidencePolicy.contentTypeFor('jpg'), 'image/jpeg');
    });

    test('file names are made safe for Storage paths', () {
      expect(
        EvidencePolicy.safeFileName('My Cert (final)/../x.pdf'),
        'My_Cert__final__.._x.pdf',
      );
      expect(EvidencePolicy.safeFileName('${'a' * 150}.pdf').length, 100);
    });
  });
}
