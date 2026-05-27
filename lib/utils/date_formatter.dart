import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _dateFormat = DateFormat('d MMM yyyy', 'id_ID');
  static final DateFormat _dateTimeFormat = DateFormat('d MMM yyyy, HH:mm', 'id_ID');

  static String short(DateTime date) => _dateFormat.format(date);
  static String dateTime(DateTime date) => _dateTimeFormat.format(date);
}

