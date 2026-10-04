import 'package:flutter_test/flutter_test.dart';
import 'package:mpm_connect/core/utils/phone_normalizer.dart';

void main() {
  group('PhoneNormalizer Tests', () {
    test('Normalizes standard 10-digit Indian phone', () {
      expect(PhoneNormalizer.normalize('9876512345'), '919876512345');
    });

    test('Normalizes 11-digit Indian phone with leading zero', () {
      expect(PhoneNormalizer.normalize('09876512345'), '919876512345');
    });

    test('Normalizes 12-digit Indian phone with +91', () {
      expect(PhoneNormalizer.normalize('+919876512345'), '919876512345');
    });

    test('Normalizes formatted phone with spaces and dashes', () {
      expect(PhoneNormalizer.normalize('+91 98765 12345'), '919876512345');
      expect(PhoneNormalizer.normalize('+91-98765-12345'), '919876512345');
      expect(PhoneNormalizer.normalize('(098) 765-12345'), '919876512345');
    });

    test('All equivalent representations produce identical normalizedPhone', () {
      final f1 = PhoneNormalizer.normalize('9876512345');
      final f2 = PhoneNormalizer.normalize('09876512345');
      final f3 = PhoneNormalizer.normalize('+919876512345');
      final f4 = PhoneNormalizer.normalize('+91 98765 12345');
      expect(f1, f2);
      expect(f2, f3);
      expect(f3, f4);
    });

    test('Validates phone numbers correctly', () {
      expect(PhoneNormalizer.isValid('9876512345'), isTrue);
      expect(PhoneNormalizer.isValid('+91 98470 45678'), isTrue);
      expect(PhoneNormalizer.isValid(''), isFalse);
      expect(PhoneNormalizer.isValid(null), isFalse);
      expect(PhoneNormalizer.isValid('123'), isFalse);
      expect(PhoneNormalizer.isValid('abcd'), isFalse);
    });

    test('Rejection reasons are clear and descriptive', () {
      expect(PhoneNormalizer.getValidationError(''), contains('No phone number'));
      expect(PhoneNormalizer.getValidationError(null), contains('No phone number'));
      expect(PhoneNormalizer.getValidationError('123'), contains('too short'));
    });

    test('Format display shows clean readable format', () {
      expect(PhoneNormalizer.formatDisplay('919876512345'), '+91 98765 12345');
      expect(PhoneNormalizer.formatDisplay('9876512345'), '+91 98765 12345');
    });
  });
}
