import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:deadlinealert/models/category.dart';
import 'package:deadlinealert/services/supabase_service.dart';
import 'package:deadlinealert/providers/auth_provider.dart';

// Category state class
class CategoryState {
  final List<Category> categories;
  final bool isLoading;
  final String? errorMessage;

  CategoryState({
    this.categories = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  CategoryState copyWith({
    List<Category>? categories,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CategoryState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  // Find a category by ID
  Category? findById(String? id) {
    if (id == null) return null;
    try {
      return categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }
}

class CategoryNotifier extends StateNotifier<CategoryState> {
  final SupabaseClient _client;
  final String _deviceId;

  CategoryNotifier(this._client, this._deviceId) : super(CategoryState()) {
    fetchCategories();
  }

  // Fetch all categories
  Future<void> fetchCategories() async {
    state = state.copyWith(isLoading: true);

    try {
      final supabaseService = SupabaseService(_client);
      final categories = await supabaseService.getCategories(
        deviceId: _deviceId,
      );

      state = state.copyWith(categories: categories, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // Add a new category
  Future<void> addCategory(Category category) async {
    state = state.copyWith(isLoading: true);

    try {
      final supabaseService = SupabaseService(_client);
      final newCategory = category.copyWith(deviceId: _deviceId);
      final createdCategory = await supabaseService.createCategory(newCategory);

      state = state.copyWith(
        categories: [...state.categories, createdCategory],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // Update a category
  Future<void> updateCategory(Category category) async {
    state = state.copyWith(isLoading: true);

    try {
      final supabaseService = SupabaseService(_client);
      final updatedCategory = await supabaseService.updateCategory(category);

      state = state.copyWith(
        categories:
            state.categories
                .map((c) => c.id == updatedCategory.id ? updatedCategory : c)
                .toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // Delete a category
  Future<void> deleteCategory(String categoryId) async {
    state = state.copyWith(isLoading: true);

    try {
      final supabaseService = SupabaseService(_client);
      await supabaseService.deleteCategory(categoryId);

      state = state.copyWith(
        categories: state.categories.where((c) => c.id != categoryId).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

// Provider for category state
final categoryProvider =
    StateNotifierProvider.family<CategoryNotifier, CategoryState, String>((
      ref,
      deviceId,
    ) {
      final supabase = SupabaseService.client;
      return CategoryNotifier(supabase, deviceId);
    });

// Combined provider that uses the auth state to get categories
final categoriesProvider = Provider<CategoryState>((ref) {
  final authState = ref.watch(authProvider);
  final categoryState = ref.watch(categoryProvider(authState.deviceId));

  return categoryState;
});
