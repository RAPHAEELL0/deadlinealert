import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class LocalStorageService {
  static const String _deviceIdKey = 'device_id';
  static const String _reminderEnabledKey = 'reminder_enabled';
  static const String _themeKey = 'theme';
  static const String _languageKey = 'language';

  // Get or generate device ID for guest mode
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);

    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString(_deviceIdKey, deviceId);
    }

    return deviceId;
  }

  // Reminder settings
  static Future<bool> isReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_reminderEnabledKey) ?? true;
  }

  static Future<void> setReminderEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reminderEnabledKey, value);
  }

  // Theme settings
  static Future<String> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? 'system';
  }

  static Future<void> setTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme);
  }

  // Language settings
  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'en';
  }

  static Future<void> setLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
  }

  // Clear all saved data (for logout)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    // Keep device ID for potential data migration
    final deviceId = prefs.getString(_deviceIdKey);
    await prefs.clear();

    if (deviceId != null) {
      await prefs.setString(_deviceIdKey, deviceId);
    }
  }
}
