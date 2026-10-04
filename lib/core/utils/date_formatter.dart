import 'package:intl/intl.dart';

/// Date Formatter utility tailored for Indian commercial standards
class DateFormatter {
  DateFormatter._();

  static final DateFormat _displayDate = DateFormat('dd MMM yyyy'); // e.g. 14 Sep 2026
  static final DateFormat _fullDateTime = DateFormat('dd MMM yyyy, hh:mm a'); // e.g. 14 Sep 2026, 04:30 PM
  static final DateFormat _shortDate = DateFormat('dd/MM/yyyy'); // e.g. 14/09/2026
  static final DateFormat _monthYear = DateFormat('MMMM yyyy'); // e.g. September 2026
  static final DateFormat _isoDate = DateFormat('yyyy-MM-dd');

  static String formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return _displayDate.format(dateTime);
  }

  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return _fullDateTime.format(dateTime);
  }

  static String formatShort(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return _shortDate.format(dateTime);
  }

  static String formatMonthYear(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return _monthYear.format(dateTime);
  }

  static String formatIso(DateTime? dateTime) {
    if (dateTime == null) return '';
    return _isoDate.format(dateTime);
  }

  /// Calculates number of days between given date and today
  static int daysAgo(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return today.difference(target).inDays;
  }
}
