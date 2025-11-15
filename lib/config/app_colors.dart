import 'package:flutter/cupertino.dart';

/// Configuración de colores de la aplicación
/// Paleta: Azul, Negro, Blanco con psicología del color para descuentos
class AppColors {
  // Colores primarios - Azul
  static const Color primaryBlue = Color(0xFF0066FF); // Azul vibrante
  static const Color primaryBlueDark = Color(0xFF0052CC); // Azul oscuro
  static const Color primaryBlueLight = Color(0xFF3385FF); // Azul claro
  
  // Degradados azules para elementos premium
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0066FF), Color(0xFF0052CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF3385FF), Color(0xFF0066FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Colores de fondo
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundGray = Color(0xFFF5F5F7); // Gris muy claro
  static const Color backgroundDark = Color(0xFF1C1C1E); // Negro suave
  
  // Colores de texto
  static const Color textPrimary = Color(0xFF000000); // Negro
  static const Color textSecondary = Color(0xFF3C3C43); // Gris oscuro
  static const Color textTertiary = Color(0xFF8E8E93); // Gris medio
  static const Color textWhite = Color(0xFFFFFFFF);
  
  // Psicología del color para descuentos y ahorros
  // Verde brillante = Dinero, ganancia, ahorro
  static const Color discountGreen = Color(0xFF00C853); // Verde brillante
  static const Color discountGreenLight = Color(0xFF69F0AE); // Verde claro
  static const Color discountGreenDark = Color(0xFF00A344); // Verde oscuro
  
  // Degradado verde para descuentos destacados
  static const LinearGradient discountGradient = LinearGradient(
    colors: [Color(0xFF00C853), Color(0xFF00A344)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Fondo para badges de descuento
  static const Color discountBackground = Color(0xFFE8F5E9); // Verde muy claro
  
  // Rojo para alertas de precio objetivo
  static const Color alertRed = Color(0xFFFF3B30); // Rojo iOS
  static const Color alertRedLight = Color(0xFFFF6B6B);
  static const Color alertBackground = Color(0xFFFFEBEE);
  
  // Colores de estado
  static const Color success = Color(0xFF34C759); // Verde éxito
  static const Color warning = Color(0xFFFF9500); // Naranja advertencia
  static const Color error = Color(0xFFFF3B30); // Rojo error
  static const Color info = Color(0xFF007AFF); // Azul info
  
  // Colores de UI
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE5E5EA);
  static const Color separator = Color(0xFFD1D1D6);
  
  // Colores de sombra
  static Color shadowLight = const Color(0xFF000000).withOpacity(0.05);
  static Color shadowMedium = const Color(0xFF000000).withOpacity(0.10);
  static Color shadowDark = const Color(0xFF000000).withOpacity(0.15);
  
  // Colores para gráficas
  static const Color chartLine = Color(0xFF0066FF); // Azul primario
  static const Color chartGrid = Color(0xFFE5E5EA);
  static const Color chartTargetLine = Color(0xFFFF3B30); // Rojo para precio objetivo
  static const Color chartOriginalLine = Color(0xFF8E8E93); // Gris para precio original
  
  // Colores para badges y etiquetas
  static const Color badgeBlue = Color(0xFFE3F2FD); // Fondo azul claro
  static const Color badgeBlueText = Color(0xFF0066FF);
  
  // Overlay y modales
  static Color overlay = const Color(0xFF000000).withOpacity(0.4);
  
  // Colores para tabs
  static const Color tabActive = Color(0xFF0066FF);
  static const Color tabInactive = Color(0xFF8E8E93);
  
  // Colores para botones
  static const Color buttonPrimary = Color(0xFF0066FF);
  static const Color buttonSecondary = Color(0xFFF5F5F7);
  static const Color buttonDisabled = Color(0xFFE5E5EA);
  
  // Métodos helper para obtener colores según el contexto de Cupertino
  static Color resolveBackground(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    return brightness == Brightness.dark ? backgroundDark : backgroundWhite;
  }
  
  static Color resolveScaffoldBackground(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    return brightness == Brightness.dark ? CupertinoColors.black : backgroundGray;
  }
  
  static Color resolveCardBackground(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    return brightness == Brightness.dark ? const Color(0xFF2C2C2E) : cardBackground;
  }
  
  static Color resolveBarBackground(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    return brightness == Brightness.dark ? CupertinoColors.darkBackgroundGray : backgroundWhite;
  }
  
  static Color resolveTextPrimary(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    return brightness == Brightness.dark ? textWhite : textPrimary;
  }
  
  static Color resolveTextSecondary(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    return brightness == Brightness.dark ? const Color(0xFFAEAEB2) : textSecondary;
  }
  
  static Color resolveTextTertiary(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    return brightness == Brightness.dark ? const Color(0xFF8E8E93) : textTertiary;
  }
  
  static Color resolveSeparator(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    return brightness == Brightness.dark ? const Color(0xFF38383A) : separator;
  }
  
  static Color resolveCardBorder(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    return brightness == Brightness.dark ? const Color(0xFF38383A) : cardBorder;
  }
  
  static Color resolveImageBackground(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    return brightness == Brightness.dark ? const Color(0xFF1C1C1E) : backgroundGray;
  }
  
  static Color resolveSearchBackground(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    return brightness == Brightness.dark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
  }
}
