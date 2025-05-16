import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:deadlinealert/models/deadline.dart';
import 'package:deadlinealert/models/category.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  final SupabaseClient _client;

  SupabaseService(this._client);

  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
  }

  // Get the client instance
  static SupabaseClient get client => Supabase.instance.client;

  // Auth methods
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Check current session
  User? get currentUser => _client.auth.currentUser;
  bool get hasUser => currentUser != null;

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // CRUD operations for deadlines
  Future<List<Deadline>> getDeadlines({String? deviceId}) async {
    final user = currentUser;

    if (user != null) {
      final response = await _client
          .from('deadlines')
          .select()
          .eq('user_id', user.id)
          .order('due_date', ascending: true);

      return (response as List).map((json) => Deadline.fromJson(json)).toList();
    } else if (deviceId != null) {
      final response = await _client
          .from('deadlines')
          .select()
          .eq('device_id', deviceId)
          .filter('user_id', 'is', 'null')
          .order('due_date', ascending: true);

      return (response as List).map((json) => Deadline.fromJson(json)).toList();
    }

    return [];
  }

  Future<Deadline> createDeadline(Deadline deadline) async {
    final user = currentUser;
    final data = deadline.toJson();

    if (user != null) {
      data['user_id'] = user.id;
    }

    final response =
        await _client.from('deadlines').insert(data).select().single();
    return Deadline.fromJson(response);
  }

  Future<Deadline> updateDeadline(Deadline deadline) async {
    final response =
        await _client
            .from('deadlines')
            .update(deadline.toJson())
            .eq('id', deadline.id)
            .select()
            .single();

    return Deadline.fromJson(response);
  }

  Future<void> deleteDeadline(String id) async {
    await _client.from('deadlines').delete().eq('id', id);
  }

  // CRUD operations for categories
  Future<List<Category>> getCategories({String? deviceId}) async {
    final user = currentUser;

    if (user != null) {
      final response = await _client
          .from('categories')
          .select()
          .eq('user_id', user.id)
          .order('name');

      return (response as List).map((json) => Category.fromJson(json)).toList();
    } else if (deviceId != null) {
      final response = await _client
          .from('categories')
          .select()
          .eq('device_id', deviceId)
          .filter('user_id', 'is', 'null')
          .order('name');

      return (response as List).map((json) => Category.fromJson(json)).toList();
    }

    return [];
  }

  Future<Category> createCategory(Category category) async {
    final user = currentUser;
    final data = category.toJson();

    if (user != null) {
      data['user_id'] = user.id;
    }

    final response =
        await _client.from('categories').insert(data).select().single();
    return Category.fromJson(response);
  }

  Future<Category> updateCategory(Category category) async {
    final response =
        await _client
            .from('categories')
            .update(category.toJson())
            .eq('id', category.id)
            .select()
            .single();

    return Category.fromJson(response);
  }

  Future<void> deleteCategory(String id) async {
    await _client.from('categories').delete().eq('id', id);
  }

  // Real-time subscriptions
  RealtimeChannel subscribeToDeadlines({
    String? deviceId,
    Function(List<Deadline>)? onDeadlinesChange,
  }) {
    final channel = _client.channel('deadlines');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'deadlines',
          callback: (payload) {
            if (onDeadlinesChange != null) {
              getDeadlines(deviceId: deviceId).then((deadlines) {
                onDeadlinesChange(deadlines);
              });
            }
          },
        )
        .subscribe();

    return channel;
  }

  // Migrate guest data to user account after login
  Future<void> migrateGuestData(String deviceId) async {
    final user = currentUser;
    if (user == null) return;

    // Update deadlines to associate with user
    await _client
        .from('deadlines')
        .update({'user_id': user.id})
        .eq('device_id', deviceId)
        .filter('user_id', 'is', 'null');

    // Update categories to associate with user
    await _client
        .from('categories')
        .update({'user_id': user.id})
        .eq('device_id', deviceId)
        .filter('user_id', 'is', 'null');
  }
}
