import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static String format(double amount) {
    return _formatter.format(amount);
  }

  static String formatWithSign(double amount) {
    if (amount > 0) {
      return '+${_formatter.format(amount)}';
    }
    return _formatter.format(amount);
  }
}
