import 'package:intl/intl.dart';

class Formatters {
  static String price(double value) {
    if (value >= 1) {
      return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(value);
    }
    return NumberFormat.currency(symbol: '\$', decimalDigits: 6).format(value);
  }

  static String compactCurrency(double value) {
    if (value >= 1e12) return '\$${(value / 1e12).toStringAsFixed(2)}T';
    if (value >= 1e9) return '\$${(value / 1e9).toStringAsFixed(2)}B';
    if (value >= 1e6) return '\$${(value / 1e6).toStringAsFixed(2)}M';
    return '\$${value.toStringAsFixed(2)}';
  }

  static String supply(double value) {
    return NumberFormat.decimalPattern().format(value.toInt());
  }
}
