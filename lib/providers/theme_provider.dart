import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeMode {
  light,
  dark,
  system,
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Brightness? _systemBrightness;

  ThemeMode get themeMode => _themeMode;
  Brightness? get systemBrightness => _systemBrightness;

  // Determina el brillo efectivo basado en el modo de tema
  Brightness get effectiveBrightness {
    switch (_themeMode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return _systemBrightness ?? Brightness.light;
    }
  }

  bool get isDarkMode => effectiveBrightness == Brightness.dark;

  ThemeProvider() {
    _loadThemeMode();
  }

  // Cargar el modo de tema guardado
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString('theme_mode');
      
      if (savedMode != null) {
        _themeMode = ThemeMode.values.firstWhere(
          (mode) => mode.toString() == savedMode,
          orElse: () => ThemeMode.system,
        );
        notifyListeners();
      }
    } catch (e) {
      // Si hay error, usar el modo sistema por defecto
      _themeMode = ThemeMode.system;
    }
  }

  // Actualizar el brillo del sistema
  void updateSystemBrightness(Brightness brightness) {
    if (_systemBrightness != brightness) {
      _systemBrightness = brightness;
      notifyListeners();
    }
  }

  // Cambiar el modo de tema
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();

      // Guardar la preferencia
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('theme_mode', mode.toString());
      } catch (e) {
        // Error al guardar, pero continuar
      }
    }
  }

  // Métodos de conveniencia
  Future<void> setLightMode() => setThemeMode(ThemeMode.light);
  Future<void> setDarkMode() => setThemeMode(ThemeMode.dark);
  Future<void> setSystemMode() => setThemeMode(ThemeMode.system);
}
