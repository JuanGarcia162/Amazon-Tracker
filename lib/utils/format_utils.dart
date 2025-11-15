import 'package:intl/intl.dart';

/// Utilidades para formateo de datos
class FormatUtils {
  /// Formateador de moneda USD
  static final currencyFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  /// Formateador de fecha corta (dd/MM)
  static final shortDateFormat = DateFormat('dd/MM');

  /// Formateador de fecha completa (dd/MM/yyyy)
  static final fullDateFormat = DateFormat('dd/MM/yyyy');

  /// Formateador de fecha y hora (dd/MM/yyyy HH:mm)
  static final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  /// Formateador de fecha para gráficos (dd MMM yy)
  static final chartDateFormat = DateFormat('dd MMM yy');

  /// Formatea una fecha de manera relativa (hace 5m, hace 2h, etc.)
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'ahora';
    } else if (difference.inHours < 1) {
      return 'hace ${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return 'hace ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'hace ${difference.inDays}d';
    } else {
      return fullDateFormat.format(date);
    }
  }

  /// Formatea un porcentaje
  static String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(0)}%';
  }

  /// Formatea un precio con símbolo de moneda
  static String formatPrice(double price) {
    return currencyFormat.format(price);
  }
}
