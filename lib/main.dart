import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:deadlinealert/services/supabase_service.dart';
import 'package:deadlinealert/services/notification_service.dart';
import 'package:deadlinealert/providers/auth_provider.dart';
import 'package:deadlinealert/providers/theme_provider.dart' as app_theme;

// Import screens (will be created later)
import 'package:deadlinealert/screens/splash_screen.dart';
import 'package:deadlinealert/screens/home_screen.dart';
import 'package:deadlinealert/screens/auth/login_screen.dart';
import 'package:deadlinealert/screens/auth/signup_screen.dart';
import 'package:deadlinealert/screens/deadline/deadline_form_screen.dart';
import 'package:deadlinealert/screens/deadline/overdue_deadlines_screen.dart';
import 'package:deadlinealert/screens/category/category_form_screen.dart';
import 'package:deadlinealert/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await SupabaseService.initialize();

  // Initialize notification service
  await NotificationService.instance.initialize();

  runApp(const ProviderScope(child: DeadlineAlertApp()));
}

// Define the router
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

final _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  debugLogDiagnostics: true,
  redirect: (BuildContext context, GoRouterState state) {
    final authProviderState = ProviderScope.containerOf(
      context,
    ).read(authProvider);

    final bool isLoggedIn = authProviderState.isAuthenticated;
    final bool goingToLogin = state.matchedLocation == '/login';
    final bool goingToSignup = state.matchedLocation == '/signup';
    final bool goingToRoot = state.matchedLocation == '/';
    final bool goingToAuthScreen = goingToLogin || goingToSignup || goingToRoot;

    // Debug logging
    print(
      'Auth Status: ${authProviderState.status}, Location: ${state.matchedLocation}',
    );
    print('isLoggedIn: $isLoggedIn');

    // Root path should always go to splash screen which handles initial routing
    if (goingToRoot) {
      return null; // Allow navigation to splash screen
    }

    // If authenticated, allow access to all screens except login/signup
    if (isLoggedIn) {
      // If trying to go to login/signup, redirect to home
      if (goingToLogin || goingToSignup) {
        return '/home';
      }
      // Otherwise allow navigation
      return null;
    }

    // If not authenticated and not going to auth screens, redirect to login
    if (!goingToAuthScreen) {
      print('Redirecting to login from ${state.matchedLocation}');
      return '/login';
    }

    // Allow navigation to login/signup screens when not authenticated
    return null;
  },
  // Use a custom error handler to prevent white screens
  errorBuilder:
      (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Navigation Error',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text('Failed to navigate to: ${state.uri.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      ),
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/login',
      pageBuilder:
          (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const LoginScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
          ),
    ),
    GoRoute(
      path: '/signup',
      pageBuilder:
          (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const SignupScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
          ),
    ),
    GoRoute(
      path: '/deadline/new',
      builder: (context, state) => const DeadlineFormScreen(),
    ),
    GoRoute(
      path: '/deadline/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'];
        return DeadlineFormScreen(deadlineId: id);
      },
    ),
    GoRoute(
      path: '/category/new',
      builder: (context, state) => const CategoryFormScreen(),
    ),
    GoRoute(
      path: '/category/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'];
        return CategoryFormScreen(categoryId: id);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/overdue',
      builder: (context, state) => const OverdueDeadlinesScreen(),
    ),
  ],
);

class DeadlineAlertApp extends ConsumerWidget {
  const DeadlineAlertApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(app_theme.themeProvider);

    // Listen to auth changes
    ref.listen(authProvider, (previous, current) {
      if (previous?.isAuthenticated != current.isAuthenticated) {
        // Force router to reevaluate routes on auth status change
        _router.refresh();
      }
    });

    // Convert our ThemeMode enum to Flutter's ThemeMode
    final flutterThemeMode = switch (themeMode) {
      app_theme.ThemeMode.light => ThemeMode.light,
      app_theme.ThemeMode.dark => ThemeMode.dark,
      app_theme.ThemeMode.system => ThemeMode.system,
    };

    return MaterialApp.router(
      title: 'Deadline Alert',
      theme: app_theme.lightTheme.copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(app_theme.lightTheme.textTheme),
      ),
      darkTheme: app_theme.darkTheme.copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(app_theme.darkTheme.textTheme),
      ),
      themeMode: flutterThemeMode,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
