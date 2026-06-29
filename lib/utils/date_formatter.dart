import 'package:intl/intl.dart';

class DateFormatter {
  const DateFormatter._();

  static String short(DateTime date) => _format(
        date,
        localizedPattern: 'd MMM yyyy',
        fallbackPattern: 'dd/MM/yyyy',
      );

  static String dateTime(DateTime date) => _format(
        date,
        localizedPattern: 'd MMM yyyy, HH:mm',
        fallbackPattern: 'dd/MM/yyyy HH:mm',
      );

  static String _format(
    DateTime date, {
    required String localizedPattern,
    required String fallbackPattern,
  }) {
    try {
      return DateFormat(localizedPattern, 'id_ID').format(date);
    } catch (_) {
      return DateFormat(fallbackPattern).format(date);
    }
  }
}
