/// Utility for parsing, validating, and normalizing phone numbers.
/// Optimized for Indian mobile/landline numbers (+91), while gracefully
/// supporting international formats.
class PhoneNormalizer {
  PhoneNormalizer._();

  /// Normalizes a phone string into a canonical format (digits only, e.g. '919876512345').
  /// Returns empty string if the input has no valid digits.
  static String normalize(String? rawPhone) {
    if (rawPhone == null || rawPhone.trim().isEmpty) {
      return '';
    }

    // 1. Remove all non-numeric characters except leading '+'
    final trimmed = rawPhone.trim();

    // Strip everything that is not a digit
    String digits = trimmed.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) return '';

    // 2. Handle international prefix '00' (e.g. 00919876512345 -> 919876512345)
    if (digits.startsWith('00') && digits.length > 11) {
      digits = digits.substring(2);
    }

    // 3. Indian standard normalization:
    // Case A: 11 digits starting with '0' (e.g., 09876512345 -> 919876512345)
    if (digits.length == 11 && digits.startsWith('0')) {
      final withoutZero = digits.substring(1);
      return '91$withoutZero';
    }

    // Case B: 10 digits (e.g. 9876512345 -> 919876512345)
    if (digits.length == 10) {
      return '91$digits';
    }

    // Case C: 12 digits starting with 91 (e.g. 919876512345 -> 919876512345)
    if (digits.length == 12 && digits.startsWith('91')) {
      return digits;
    }

    // Case D: Other international numbers (if + was present or length is between 8 and 15 digits)
    if (digits.length >= 8 && digits.length <= 15) {
      return digits;
    }

    return digits;
  }

  /// Checks if a raw phone string resolves to a valid, reachable phone number.
  static bool isValid(String? rawPhone) {
    final normalized = normalize(rawPhone);
    if (normalized.isEmpty) return false;

    // Reject numbers with fewer than 10 digits or more than 15 digits
    if (normalized.length < 10 || normalized.length > 15) return false;

    // For 12-digit Indian numbers (91 + 10 digits):
    if (normalized.startsWith('91') && normalized.length == 12) {
      final coreNumber = normalized.substring(2);
      // Valid Indian mobile numbers generally start with 6, 7, 8, or 9
      // Landlines start with 1-5
      final firstDigit = coreNumber[0];
      return '123456789'.contains(firstDigit);
    }

    return true;
  }

  /// Returns a user-friendly validation error message if invalid, or null if valid.
  static String? getValidationError(String? rawPhone) {
    if (rawPhone == null || rawPhone.trim().isEmpty) {
      return 'No phone number available';
    }

    final digitsOnly = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) {
      return 'Phone number contains no digits';
    }

    if (digitsOnly.length < 8) {
      return 'Phone number is too short (${digitsOnly.length} digits)';
    }

    if (digitsOnly.length > 15) {
      return 'Phone number is too long (${digitsOnly.length} digits)';
    }

    if (!isValid(rawPhone)) {
      return 'Invalid phone format ($rawPhone)';
    }

    return null;
  }

  /// Formats a phone number for clean, readable UI display:
  /// e.g. '919876512345' -> '+91 98765 12345'
  static String formatDisplay(String? phone) {
    if (phone == null || phone.trim().isEmpty) return '';
    final normalized = normalize(phone);
    if (normalized.isEmpty) return phone.trim();

    // Indian 12-digit format (91XXXXXXXXXX)
    if (normalized.length == 12 && normalized.startsWith('91')) {
      final part1 = normalized.substring(2, 7);
      final part2 = normalized.substring(7);
      return '+91 $part1 $part2';
    }

    // 10-digit format
    if (normalized.length == 10) {
      final part1 = normalized.substring(0, 5);
      final part2 = normalized.substring(5);
      return '$part1 $part2';
    }

    // International format with '+'
    return '+$normalized';
  }
}
