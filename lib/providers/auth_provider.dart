import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:deadlinealert/services/supabase_service.dart';
import 'package:deadlinealert/services/local_storage_service.dart';

// Auth state enum
enum AuthStatus { initial, authenticated, unauthenticated, loading, error }

// Auth state class with user and status
class AuthState {
  final User? user;
  final AuthStatus status;
  final String? errorMessage;
  final String deviceId;

  AuthState({
    this.user,
    required this.status,
    this.errorMessage,
    required this.deviceId,
  });

  // Copying with new values
  AuthState copyWith({
    User? user,
    AuthStatus? status,
    String? errorMessage,
    String? deviceId,
  }) {
    return AuthState(
      user: user ?? this.user,
      status: status ?? this.status,
      errorMessage: errorMessage,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  // Check if the user is authenticated
  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;

  // Check if the user is in guest mode
  bool get isGuestMode => status == AuthStatus.unauthenticated && user == null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseClient _client;

  AuthNotifier(this._client)
    : super(AuthState(status: AuthStatus.initial, deviceId: '')) {
    _initialize();
  }

  // Initialize authentication state
  Future<void> _initialize() async {
    // Get the device ID for guest mode
    final deviceId = await LocalStorageService.getDeviceId();

    // Set the initial state with device ID
    state = state.copyWith(status: AuthStatus.loading, deviceId: deviceId);

    try {
      // Check if there's an active session
      final user = _client.auth.currentUser;

      if (user != null) {
        state = state.copyWith(user: user, status: AuthStatus.authenticated);
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }

    // Listen for auth state changes
    _client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed) {
        state = state.copyWith(
          user: session?.user,
          status: AuthStatus.authenticated,
        );
      } else if (event == AuthChangeEvent.signedOut) {
        state = state.copyWith(user: null, status: AuthStatus.unauthenticated);
      } else if (event == AuthChangeEvent.userUpdated) {
        state = state.copyWith(user: session?.user);
      }
    });
  }

  // Sign in with email and password
  Future<void> signIn({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Migrate guest data to user account
        await SupabaseService(
          SupabaseService.client,
        ).migrateGuestData(state.deviceId);

        state = state.copyWith(
          user: response.user,
          status: AuthStatus.authenticated,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Failed to sign in',
        );
      }
    } catch (e) {
      // Provide a more user-friendly error message
      String errorMessage = 'An error occurred during sign in';

      if (e.toString().contains('invalid_credentials') ||
          e.toString().contains('Invalid login credentials')) {
        errorMessage = 'Incorrect email or password. Please try again.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('too many requests') ||
          e.toString().contains('429')) {
        errorMessage = 'Too many login attempts. Please try again later.';
      }

      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: errorMessage,
      );
    }
  }

  // Sign up with email and password
  Future<void> signUp({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Migrate guest data to user account
        await SupabaseService(
          SupabaseService.client,
        ).migrateGuestData(state.deviceId);

        state = state.copyWith(
          user: response.user,
          status:
              response.session != null
                  ? AuthStatus.authenticated
                  : AuthStatus.unauthenticated,
          errorMessage:
              response.session == null
                  ? 'Please verify your email to complete signup'
                  : null,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Failed to sign up',
        );
      }
    } catch (e) {
      // Provide a more user-friendly error message
      String errorMessage = 'An error occurred during sign up';

      if (e.toString().contains('already registered')) {
        errorMessage =
            'This email is already registered. Please use a different email or try to log in.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('password')) {
        errorMessage =
            'Password is too weak. Please choose a stronger password.';
      } else if (e.toString().contains('email')) {
        errorMessage =
            'Invalid email format. Please enter a valid email address.';
      }

      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: errorMessage,
      );
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // First set state to loading to indicate the operation is in progress
      state = state.copyWith(status: AuthStatus.loading);

      // Preserve the device ID for guest mode
      final currentDeviceId = state.deviceId;

      // Clear Supabase session
      await _client.auth.signOut();

      // Complete reset of the state
      state = AuthState(
        user: null,
        status: AuthStatus.unauthenticated,
        deviceId: currentDeviceId,
        errorMessage: null,
      );

      // Ensure the state is updated before continuing
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      // Handle errors
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Error during sign out: ${e.toString()}',
      );

      // Rethrow to allow the UI to handle the error
      rethrow;
    }
  }

  // Get the current user
  User? get currentUser => state.user;

  // Get the device ID for guest mode
  String get deviceId => state.deviceId;
}

// Provider for auth state
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(SupabaseService.client);
});
