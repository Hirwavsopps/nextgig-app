import 'package:flutter_test/flutter_test.dart';
import 'package:nextgig/features/auth/domain/validators.dart';

void main() {
  group('validateEmail', () {
    test('rejects empty and malformed emails', () {
      expect(validateEmail(''), 'Email is required');
      expect(validateEmail('   '), 'Email is required');
      expect(validateEmail('amina'), 'Enter a valid email address');
      expect(validateEmail('amina@mail'), 'Enter a valid email address');
    });

    test('accepts a normal email, ignoring surrounding spaces', () {
      expect(validateEmail('amina@mail.com'), isNull);
      expect(validateEmail('  amina@mail.com  '), isNull);
    });
  });

  group('validatePassword', () {
    test('requires a value of at least the minimum length', () {
      expect(validatePassword(''), 'Password is required');
      expect(validatePassword(null), 'Password is required');
      expect(validatePassword('short'), isNotNull);
      expect(validatePassword('1234567'), isNotNull);
    });

    test('accepts a password of the minimum length', () {
      expect(validatePassword('12345678'), isNull);
    });
  });

  group('validateName', () {
    test('needs at least two characters', () {
      expect(validateName(''), 'Enter your full name');
      expect(validateName('A'), 'Enter your full name');
      expect(validateName('Amina Mwangi'), isNull);
    });
  });

  group('validatePhone', () {
    test('is optional', () {
      expect(validatePhone(''), isNull);
      expect(validatePhone(null), isNull);
    });

    test('checks the format when provided', () {
      expect(validatePhone('12'), 'Enter a valid phone number');
      expect(validatePhone('abc123456789'), 'Enter a valid phone number');
      expect(validatePhone('0788123456'), isNull);
      expect(validatePhone('+250 788 123 456'), isNull);
    });
  });
}
