import 'package:flutter/cupertino.dart';
import 'app_colors.dart';

/// Configuración centralizada de temas de la aplicación
class AppTheme {
  /// Construye el tema de Cupertino basado en el modo oscuro
  static CupertinoThemeData buildTheme(bool isDarkMode) {
    return CupertinoThemeData(
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      primaryColor: AppColors.primaryBlue,
      scaffoldBackgroundColor: isDarkMode
          ? CupertinoColors.black
          : AppColors.backgroundGray,
      barBackgroundColor: isDarkMode
          ? CupertinoColors.darkBackgroundGray
          : AppColors.backgroundWhite,
      textTheme: _buildTextTheme(isDarkMode),
    );
  }

  /// Construye el tema de texto
  static CupertinoTextThemeData _buildTextTheme(bool isDarkMode) {
    final textColor = isDarkMode ? CupertinoColors.white : AppColors.textPrimary;

    return CupertinoTextThemeData(
      primaryColor: textColor,
      textStyle: TextStyle(
        fontFamily: '.SF Pro Text',
        fontSize: 17,
        color: textColor,
      ),
      navTitleTextStyle: TextStyle(
        fontFamily: '.SF Pro Display',
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      navLargeTitleTextStyle: TextStyle(
        fontFamily: '.SF Pro Display',
        fontSize: 34,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );
  }
}
