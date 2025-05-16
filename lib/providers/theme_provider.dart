import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deadlinealert/services/local_storage_service.dart';

enum ThemeMode { system, light, dark }

// Define custom colors
const Color darkRed = Color(0xFF8B0000);
const Color lightRed = Color(0xFFB22222);
const Color lightGray = Color(0xFFF5F5F5);
const Color mediumGray = Color(0xFFE0E0E0);
const Color darkGray = Color(0xFF757575);

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final savedTheme = await LocalStorageService.getTheme();
    switch (savedTheme) {
      case 'light':
        state = ThemeMode.light;
        break;
      case 'dark':
        state = ThemeMode.dark;
        break;
      case 'system':
      default:
        state = ThemeMode.system;
        break;
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    String themeName;

    switch (mode) {
      case ThemeMode.light:
        themeName = 'light';
        break;
      case ThemeMode.dark:
        themeName = 'dark';
        break;
      case ThemeMode.system:
      default:
        themeName = 'system';
        break;
    }

    await LocalStorageService.setTheme(themeName);
    state = mode;
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

// Light theme
final lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme(
    primary: darkRed,
    onPrimary: Colors.white,
    secondary: lightRed,
    onSecondary: Colors.white,
    error: Colors.red.shade800,
    onError: Colors.white,
    background: lightGray,
    onBackground: Colors.black87,
    surface: Colors.white,
    onSurface: Colors.black87,
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: lightGray,
  appBarTheme: const AppBarTheme(
    backgroundColor: darkRed,
    foregroundColor: Colors.white,
    centerTitle: true,
    elevation: 0,
    scrolledUnderElevation: 2,
  ),
  cardTheme: CardTheme(
    color: Colors.white,
    elevation: 2,
    shadowColor: darkRed.withOpacity(0.3),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: darkRed,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: darkGray.withOpacity(0.3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: darkRed, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: darkRed,
    foregroundColor: Colors.white,
  ),
  dividerTheme: const DividerThemeData(color: mediumGray, thickness: 1),
  chipTheme: ChipThemeData(
    backgroundColor: mediumGray,
    labelStyle: const TextStyle(color: Colors.black87),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  ),
  tabBarTheme: const TabBarTheme(
    labelColor: darkRed,
    unselectedLabelColor: darkGray,
    indicatorColor: darkRed,
  ),
);

// Dark theme
final darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme(
    primary: lightRed,
    onPrimary: Colors.white,
    secondary: darkRed,
    onSecondary: Colors.white,
    error: Colors.red.shade300,
    onError: Colors.black,
    background: const Color(0xFF121212),
    onBackground: Colors.white,
    surface: const Color(0xFF1E1E1E),
    onSurface: Colors.white,
    brightness: Brightness.dark,
  ),
  scaffoldBackgroundColor: const Color(0xFF121212),
  appBarTheme: const AppBarTheme(
    backgroundColor: darkRed,
    foregroundColor: Colors.white,
    centerTitle: true,
    elevation: 0,
    scrolledUnderElevation: 2,
  ),
  cardTheme: CardTheme(
    color: const Color(0xFF1E1E1E),
    elevation: 2,
    shadowColor: Colors.black38,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: lightRed,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF2C2C2C),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: lightRed, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: lightRed,
    foregroundColor: Colors.white,
  ),
  dividerTheme: const DividerThemeData(color: Color(0xFF2C2C2C), thickness: 1),
  chipTheme: ChipThemeData(
    backgroundColor: const Color(0xFF2C2C2C),
    labelStyle: const TextStyle(color: Colors.white),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  ),
  tabBarTheme: const TabBarTheme(
    labelColor: lightRed,
    unselectedLabelColor: Colors.white70,
    indicatorColor: lightRed,
  ),
);
