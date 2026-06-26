import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  static String format(num value) => _formatter.format(value);

  static String formatSimple(num value) {
    final formatted = _formatter.format(value);
    return formatted.replaceAll('Rp', '').trim();
  }
}


