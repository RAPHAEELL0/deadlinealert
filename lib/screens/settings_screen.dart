import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

import 'package:deadlinealert/providers/auth_provider.dart';
import 'package:deadlinealert/providers/theme_provider.dart' as app_theme;
import 'package:deadlinealert/services/local_storage_service.dart';
import 'package:deadlinealert/services/haptic_feedback_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with TickerProviderStateMixin {
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'en';
  bool _themeChanging = false;

  // Animation controllers
  late AnimationController _themeAnimationController;
  late AnimationController _notificationAnimationController;
  late AnimationController _signOutAnimationController;

  // Track which sections are expanded
  final Map<String, bool> _expandedSections = {
    'account': true,
    'appearance': false,
    'notifications': false,
    'language': false,
    'about': false,
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();

    // Initialize animation controllers
    _themeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _notificationAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _signOutAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _themeAnimationController.dispose();
    _notificationAnimationController.dispose();
    _signOutAnimationController.dispose();
    super.dispose();
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

  void _toggleSection(String section) {
    HapticFeedbackService.instance.feedback(HapticFeedbackType.light);
    setState(() {
      for (final key in _expandedSections.keys) {
        _expandedSections[key] = key == section;
      }
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    HapticFeedbackService.instance.feedback(HapticFeedbackType.light);

    // Play animation
    if (value) {
      _notificationAnimationController.forward(from: 0.0);
    } else {
      _notificationAnimationController.reverse(from: 1.0);
    }

    await LocalStorageService.setReminderEnabled(value);

    if (mounted) {
      setState(() {
        _notificationsEnabled = value;
      });
    }
  }

  Future<void> _setLanguage(String language) async {
    HapticFeedbackService.instance.feedback(HapticFeedbackType.light);

    await LocalStorageService.setLanguage(language);

    if (mounted) {
      setState(() {
        _selectedLanguage = language;
      });
    }
  }

  Future<void> _setTheme(app_theme.ThemeMode mode) async {
    HapticFeedbackService.instance.feedback(HapticFeedbackType.medium);

    // Set flag to trigger animation
    setState(() {
      _themeChanging = true;
    });

    // Run theme animation
    _themeAnimationController.forward(from: 0.0);

    // Change theme
    await ref.read(app_theme.themeProvider.notifier).setTheme(mode);

    // Reset flag after animation duration
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _themeChanging = false;
        });
        _themeAnimationController.reset();
      }
    });
  }

  Future<void> _signOut() async {
    // Start the animation
    _signOutAnimationController.forward(from: 0.0);
    HapticFeedbackService.instance.feedback(HapticFeedbackType.medium);

    // Show confirmation dialog
    final shouldLogout =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text(
                  'Sign Out',
                ).animate().fadeIn(duration: 300.ms),
                content: const Text(
                  'Are you sure you want to sign out?',
                ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
                actions: [
                  TextButton(
                    onPressed: () {
                      HapticFeedbackService.instance.feedback(
                        HapticFeedbackType.light,
                      );
                      Navigator.of(context).pop(false);
                    },
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      HapticFeedbackService.instance.feedback(
                        HapticFeedbackType.medium,
                      );
                      Navigator.of(context).pop(true);
                    },
                    child: const Text('Sign Out'),
                  ),
                ],
              ).animate().scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.0, 1.0),
                duration: 300.ms,
                curve: Curves.easeOutBack,
              ),
        ) ??
        false;

    if (!shouldLogout) {
      // Reset animation
      _signOutAnimationController.reverse();
      return;
    }

    // Use OverlayEntry instead of dialog to prevent screen transitions
    final overlayState = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder:
          (context) => AnimatedBuilder(
            animation: _signOutAnimationController,
            builder: (context, child) {
              return Container(
                color: Colors.black.withOpacity(
                  0.5 * _signOutAnimationController.value,
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    value: _signOutAnimationController.value,
                  ),
                ),
              );
            },
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
      await Future.delayed(const Duration(milliseconds: 300));

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

      // Provide haptic feedback for error
      HapticFeedbackService.instance.feedback(HapticFeedbackType.error);

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

    // Get theme colors
    final colorPrimary = Theme.of(context).colorScheme.primary;
    final colorBackground = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _themeAnimationController,
        builder: (context, child) {
          return Stack(
            children: [
              // Main content
              Opacity(
                opacity: 1.0 - _themeAnimationController.value * 0.3,
                child: child!,
              ),

              // Theme transition overlay
              if (_themeChanging)
                Positioned.fill(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: _themeAnimationController.value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorBackground,
                        gradient: RadialGradient(
                          colors: [
                            colorPrimary.withOpacity(0.7),
                            colorBackground.withOpacity(0.3),
                          ],
                          center: Alignment.center,
                          radius: 0.8,
                          stops: [0.0, 1 - _themeAnimationController.value],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
        child: CustomScrollView(
          slivers: [
            // App bar
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: Theme.of(context).colorScheme.primary,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  HapticFeedbackService.instance.feedback(
                    HapticFeedbackType.light,
                  );
                  context.go('/home');
                },
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withOpacity(0.7),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),

            // Settings content
            SliverList(
              delegate: SliverChildListDelegate([
                // Account section
                _buildSectionHeader(
                  'Account',
                  'Login and account settings',
                  'account',
                  Icons.person,
                ),
                if (_expandedSections['account']!)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      children: [
                        if (isLoggedIn)
                          AnimatedBuilder(
                            animation: _signOutAnimationController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale:
                                    1.0 -
                                    (_signOutAnimationController.value * 0.05),
                                child: ListTile(
                                  leading: const Icon(Icons.person),
                                  title: Text(
                                    'Logged in as ${authState.user?.email ?? "User"}',
                                  ),
                                  subtitle: const Text('Tap to sign out'),
                                  onTap: _signOut,
                                ),
                              );
                            },
                          ).animate().fadeIn(delay: 100.ms, duration: 400.ms)
                        else
                          ListTile(
                            leading: const Icon(Icons.login),
                            title: const Text('Sign In'),
                            subtitle: const Text(
                              'Sign in to sync your deadlines',
                            ),
                            onTap: () {
                              HapticFeedbackService.instance.feedback(
                                HapticFeedbackType.light,
                              );
                              context.go('/login');
                            },
                          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                      ],
                    ),
                  ).animate().slideY(
                    begin: -0.2,
                    end: 0,
                    duration: 300.ms,
                    curve: Curves.easeOutCubic,
                  ),

                const Divider(),

                // Appearance section
                _buildSectionHeader(
                  'Appearance',
                  'Customize how the app looks',
                  'appearance',
                  Icons.palette,
                ),
                if (_expandedSections['appearance']!)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Theme Mode',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildThemeOption(
                              icon: Icons.light_mode,
                              label: 'Light',
                              isSelected:
                                  themeMode == app_theme.ThemeMode.light,
                              onTap: () => _setTheme(app_theme.ThemeMode.light),
                            ),
                            _buildThemeOption(
                              icon: Icons.dark_mode,
                              label: 'Dark',
                              isSelected: themeMode == app_theme.ThemeMode.dark,
                              onTap: () => _setTheme(app_theme.ThemeMode.dark),
                            ),
                            _buildThemeOption(
                              icon: Icons.brightness_auto,
                              label: 'System',
                              isSelected:
                                  themeMode == app_theme.ThemeMode.system,
                              onTap:
                                  () => _setTheme(app_theme.ThemeMode.system),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().slideY(
                    begin: -0.2,
                    end: 0,
                    duration: 300.ms,
                    curve: Curves.easeOutCubic,
                  ),

                const Divider(),

                // Notifications section
                _buildSectionHeader(
                  'Notifications',
                  'Configure reminder settings',
                  'notifications',
                  Icons.notifications,
                ),
                if (_expandedSections['notifications']!)
                  AnimatedBuilder(
                    animation: _notificationAnimationController,
                    builder: (context, child) {
                      return SwitchListTile(
                        title: const Text('Enable Notifications'),
                        subtitle: const Text(
                          'Get reminders for upcoming deadlines',
                        ),
                        value: _notificationsEnabled,
                        onChanged: _toggleNotifications,
                        secondary: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              _notificationsEnabled
                                  ? Icons.notifications_active
                                  : Icons.notifications_off,
                              color:
                                  _notificationsEnabled
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                            ),
                            if (_notificationsEnabled)
                              ...List.generate(
                                3,
                                (index) => AnimatedBuilder(
                                  animation: _notificationAnimationController,
                                  builder: (context, _) {
                                    return Transform.scale(
                                      scale:
                                          1.0 +
                                          (index + 1) *
                                              0.3 *
                                              _notificationAnimationController
                                                  .value,
                                      child: Opacity(
                                        opacity: (1.0 -
                                                _notificationAnimationController
                                                    .value)
                                            .clamp(0.0, 1.0),
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary.withOpacity(
                                                0.5 - (index * 0.15),
                                              ),
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),

                const Divider(),

                // Language section
                _buildSectionHeader(
                  'Language',
                  'Change application language',
                  'language',
                  Icons.language,
                ),
                if (_expandedSections['language']!)
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
                        DropdownMenuItem(
                          value: 'id',
                          child: Text('Indonesian'),
                        ),
                      ],
                      underline: Container(),
                    ),
                  ).animate().slideY(
                    begin: -0.2,
                    end: 0,
                    duration: 300.ms,
                    curve: Curves.easeOutCubic,
                  ),

                const Divider(),

                // About section
                _buildSectionHeader(
                  'About',
                  'Information about the app',
                  'about',
                  Icons.info_outline,
                ),
                if (_expandedSections['about']!)
                  Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.info),
                        title: const Text('Version'),
                        subtitle: const Text('1.0.0'),
                      ).animate().slideY(
                        begin: 0.2,
                        end: 0,
                        duration: 400.ms,
                        delay: 100.ms,
                      ),
                      ListTile(
                        leading: const Icon(Icons.code),
                        title: const Text('Source Code'),
                        subtitle: const Text('View on GitHub'),
                        onTap: () {
                          HapticFeedbackService.instance.feedback(
                            HapticFeedbackType.light,
                          );
                          // Open GitHub link
                        },
                      ).animate().slideY(
                        begin: 0.2,
                        end: 0,
                        duration: 400.ms,
                        delay: 200.ms,
                      ),
                    ],
                  ),

                // Bottom padding
                const SizedBox(height: 40),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String subtitle,
    String section,
    IconData icon,
  ) {
    return InkWell(
      onTap: () => _toggleSection(section),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedRotation(
              turns: _expandedSections[section]! ? 0.25 : 0,
              duration: const Duration(milliseconds: 300),
              child: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildThemeOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              boxShadow:
                  isSelected
                      ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                      : null,
            ),
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (
                    Widget child,
                    Animation<double> animation,
                  ) {
                    return ScaleTransition(
                      scale: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: Icon(
                    icon,
                    key: ValueKey(isSelected),
                    color:
                        isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    color:
                        isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          )
          .animate(target: isSelected ? 1 : 0)
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.05, 1.05),
            duration: 300.ms,
            curve: Curves.easeOutBack,
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
