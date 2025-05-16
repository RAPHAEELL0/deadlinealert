import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:deadlinealert/providers/auth_provider.dart';
import 'package:deadlinealert/providers/theme_provider.dart' as app_theme;
import 'package:deadlinealert/services/local_storage_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final notificationsEnabled = await LocalStorageService.isReminderEnabled();
    final language = await LocalStorageService.getLanguage();

    if (mounted) {
      setState(() {
        _notificationsEnabled = notificationsEnabled;
        _selectedLanguage = language;
      });
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    await LocalStorageService.setReminderEnabled(value);

    if (mounted) {
      setState(() {
        _notificationsEnabled = value;
      });
    }
  }

  Future<void> _setLanguage(String language) async {
    await LocalStorageService.setLanguage(language);

    if (mounted) {
      setState(() {
        _selectedLanguage = language;
      });
    }
  }

  Future<void> _setTheme(app_theme.ThemeMode mode) async {
    await ref.read(app_theme.themeProvider.notifier).setTheme(mode);
  }

  Future<void> _signOut() async {
    // Show confirmation dialog
    final shouldLogout =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Sign Out'),
                content: const Text('Are you sure you want to sign out?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
        ) ??
        false;

    if (!shouldLogout) return;

    // Use OverlayEntry instead of dialog to prevent screen transitions
    final overlayState = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder:
          (context) => Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
    );

    // Insert overlay
    overlayState.insert(overlayEntry);

    try {
      // Important: get auth notifier reference BEFORE any navigation happens
      final authNotifier = ref.read(authProvider.notifier);

      // Perform sign out first
      await authNotifier.signOut();

      // Short delay to ensure state is updated
      await Future.delayed(const Duration(milliseconds: 100));

      // Navigate to login screen
      if (mounted) {
        context.go('/login');
      }

      // Remove overlay after slight delay for smooth transition
      Future.delayed(const Duration(milliseconds: 300), () {
        overlayEntry.remove();
      });
    } catch (e) {
      // Remove the overlay if an error occurs
      overlayEntry.remove();

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(app_theme.themeProvider);
    final isLoggedIn = authState.isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: ListView(
        children: [
          // Account section
          const ListTile(
            title: Text('Account'),
            subtitle: Text('Login and account settings'),
          ),
          if (isLoggedIn)
            ListTile(
              leading: const Icon(Icons.person),
              title: Text('Logged in as ${authState.user?.email ?? "User"}'),
              subtitle: const Text('Tap to sign out'),
              onTap: _signOut,
            )
          else
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Sign In'),
              subtitle: const Text('Sign in to sync your deadlines'),
              onTap: () => context.go('/login'),
            ),

          const Divider(),

          // Appearance section
          const ListTile(
            title: Text('Appearance'),
            subtitle: Text('Customize how the app looks'),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_4),
            title: const Text('Theme'),
            trailing: DropdownButton<app_theme.ThemeMode>(
              value: themeMode,
              onChanged: (app_theme.ThemeMode? newValue) {
                if (newValue != null) {
                  _setTheme(newValue);
                }
              },
              items:
                  app_theme.ThemeMode.values.map((mode) {
                    return DropdownMenuItem(
                      value: mode,
                      child: Text(mode.name.capitalize()),
                    );
                  }).toList(),
              underline: Container(),
            ),
          ),

          const Divider(),

          // Notifications section
          const ListTile(
            title: Text('Notifications'),
            subtitle: Text('Configure reminder settings'),
          ),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            subtitle: const Text('Get reminders for upcoming deadlines'),
            value: _notificationsEnabled,
            onChanged: _toggleNotifications,
          ),

          const Divider(),

          // Language section
          const ListTile(
            title: Text('Language'),
            subtitle: Text('Change application language'),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            trailing: DropdownButton<String>(
              value: _selectedLanguage,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  _setLanguage(newValue);
                }
              },
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'id', child: Text('Indonesian')),
              ],
              underline: Container(),
            ),
          ),

          const Divider(),

          // About section
          const ListTile(
            title: Text('About'),
            subtitle: Text('Information about the app'),
          ),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Source Code'),
            onTap: () {
              // Open source code repository
            },
          ),
        ],
      ),
    );
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
