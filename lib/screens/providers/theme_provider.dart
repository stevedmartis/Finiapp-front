import 'package:finiapp/constants.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String themePrefKey = 'theme_mode';
  static const String firstLaunchKey = 'first_launch';

  // Inicializar con tema oscuro por defecto
  ThemeMode _themeMode = ThemeMode.dark;
  bool _isDetailPage = false;

  ThemeProvider() {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  // Definición de los colores para el tema claro y oscuro
  final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    appBarTheme: const AppBarTheme(
      backgroundColor: logoCOLOR1,
      foregroundColor: Colors.white,
    ),
    scaffoldBackgroundColor: lightBackground,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: lightTitleColor),
      bodyMedium: TextStyle(color: lightSubtitleColor),
    ),
    iconTheme: const IconThemeData(
      color: lightIconColor,
    ),
    cardColor: lightCardBackground,
  );

  final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    appBarTheme: const AppBarTheme(
      backgroundColor: logoCOLOR1,
      foregroundColor: Colors.white,
    ),
    scaffoldBackgroundColor: backgroundDark,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: darkTitleColor),
      bodyMedium: TextStyle(color: darkSubtitleColor),
    ),
    iconTheme: const IconThemeData(
      color: darkIconColor,
    ),
    cardColor: darkCardBackground,
  );

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _saveThemeMode(_themeMode);
    notifyListeners();
  }

  void changePageDetail(bool isDetailPage) {
    _isDetailPage = isDetailPage;
    notifyListeners();
  }

  bool getThemeCurrent() {
    return _themeMode == ThemeMode.dark ? true : false;
  }

  bool geIsPageDetail() {
    return _isDetailPage;
  }

  Color getColorBasedOnThemeAndPage() {
    if (getThemeCurrent() && geIsPageDetail()) {
      // Si el tema es oscuro y es la página de detalle
      return getSubtitleColor();
    } else if (getThemeCurrent() && !geIsPageDetail()) {
      // Si el tema es oscuro y no es la página de detalle
      return getSubtitleColor(); // Reemplaza con el color deseado para esta condición
    } else if (!getThemeCurrent() && !geIsPageDetail()) {
      // Si el tema no es oscuro y no es la página de detalle
      return darkSubtitleColor; // Reemplaza con el color deseado para esta condición
    } else {
      // Si el tema no es oscuro y es la página de detalle
      return Colors.white; // Reemplaza con el color deseado para esta condición
    }
  }

  Color getCardColor() {
    return _themeMode == ThemeMode.dark
        ? darkCardBackground
        : lightCardBackground;
  }

  Color getTitleColor() {
    return _themeMode == ThemeMode.dark ? darkTitleColor : lightTitleColor;
  }

  Color getSubtitleColor() {
    return _themeMode == ThemeMode.dark
        ? darkSubtitleColor
        : lightSubtitleColor;
  }

  Color getIconColor() {
    return _themeMode == ThemeMode.dark ? darkIconColor : lightIconColor;
  }

  Color getIconModeColor() {
    return _themeMode == ThemeMode.dark ? darkIconColor : lightModeIcon;
  }

  Color getBackgroundColor() {
    return _themeMode == ThemeMode.dark ? backgroundDark : lightBackground;
  }

  LinearGradient getGradientCard() {
    return _themeMode == ThemeMode.dark
        ? const LinearGradient(
            colors: [darkCardBackground, darkCardBackground],
            begin: Alignment.bottomRight,
            end: Alignment.topLeft,
          )
        : const LinearGradient(
            colors: [
              lightCardBackground,
              Colors.white,
            ],
            begin: Alignment.bottomRight,
            end: Alignment.topLeft,
          );
  }

  void _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Verificar si es la primera ejecución
      final isFirstLaunch = prefs.getBool(firstLaunchKey) ?? true;

      if (isFirstLaunch) {
        // Si es la primera ejecución, establecer tema oscuro por defecto
        await prefs.setBool(firstLaunchKey, false);
        await _saveThemeMode(ThemeMode.dark); // Ahora podemos usar await
        _themeMode = ThemeMode.dark;
      } else {
        // Si no es la primera ejecución, cargar el tema guardado
        final savedTheme = prefs.getString(themePrefKey);
        if (savedTheme != null) {
          _themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
        }
      }

      notifyListeners();
    } catch (e) {
      print('Error cargando preferencias de tema: $e');
      // En caso de error, mantener el tema oscuro por defecto
    }
  }

  // Cambiado para devolver un Future para permitir espera
  Future<void> _saveThemeMode(ThemeMode themeMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          themePrefKey, themeMode == ThemeMode.dark ? 'dark' : 'light');
    } catch (e) {
      print('Error guardando preferencias de tema: $e');
    }
  }
}
