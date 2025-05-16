import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:deadlinealert/models/category.dart';
import 'package:deadlinealert/providers/auth_provider.dart';
import 'package:deadlinealert/providers/category_provider.dart';

class CategoryFormScreen extends ConsumerStatefulWidget {
  final String? categoryId;

  const CategoryFormScreen({super.key, this.categoryId});

  @override
  ConsumerState<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedColor = '#FF0000'; // Default color is red
  bool _isLoading = false;

  bool get _isEditing => widget.categoryId != null;
  Category? _originalCategory;

  // Predefined colors for selection
  final List<Map<String, dynamic>> _colors = [
    {'name': 'Red', 'hex': '#FF0000'},
    {'name': 'Pink', 'hex': '#FF4081'},
    {'name': 'Purple', 'hex': '#9C27B0'},
    {'name': 'Deep Purple', 'hex': '#673AB7'},
    {'name': 'Indigo', 'hex': '#3F51B5'},
    {'name': 'Blue', 'hex': '#2196F3'},
    {'name': 'Light Blue', 'hex': '#03A9F4'},
    {'name': 'Cyan', 'hex': '#00BCD4'},
    {'name': 'Teal', 'hex': '#009688'},
    {'name': 'Green', 'hex': '#4CAF50'},
    {'name': 'Light Green', 'hex': '#8BC34A'},
    {'name': 'Lime', 'hex': '#CDDC39'},
    {'name': 'Yellow', 'hex': '#FFEB3B'},
    {'name': 'Amber', 'hex': '#FFC107'},
    {'name': 'Orange', 'hex': '#FF9800'},
    {'name': 'Deep Orange', 'hex': '#FF5722'},
    {'name': 'Brown', 'hex': '#795548'},
    {'name': 'Grey', 'hex': '#9E9E9E'},
    {'name': 'Blue Grey', 'hex': '#607D8B'},
    {'name': 'Black', 'hex': '#000000'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCategory();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadCategory() async {
    if (!_isEditing) return;

    setState(() {
      _isLoading = true;
    });

    final authState = ref.read(authProvider);
    final categories =
        ref.read(categoryProvider(authState.deviceId)).categories;

    final category = categories.firstWhere(
      (c) => c.id == widget.categoryId,
      orElse: () => throw Exception('Category not found'),
    );

    _originalCategory = category;

    _nameController.text = category.name;
    _selectedColor = category.color;

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authState = ref.read(authProvider);

      final newCategory = Category(
        id: _isEditing ? _originalCategory!.id : null,
        name: _nameController.text.trim(),
        color: _selectedColor,
      );

      if (_isEditing) {
        await ref
            .read(categoryProvider(authState.deviceId).notifier)
            .updateCategory(newCategory);
      } else {
        await ref
            .read(categoryProvider(authState.deviceId).notifier)
            .addCategory(newCategory);
      }

      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home'); // Fallback to home if cannot pop
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper to convert hex string to Color
  Color _hexToColor(String hexString) {
    final hex = hexString.replaceAll('#', '');
    final intValue = int.parse(hex, radix: 16);
    return Color(intValue).withOpacity(1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Category' : 'Add Category'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveCategory,
            child:
                _isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Save'),
          ),
        ],
      ),
      body:
          _isLoading && _isEditing
              ? const Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // Category name field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Category Name',
                        hintText: 'Enter a name for your category',
                        prefixIcon: Icon(Icons.category),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a category name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Color selection
                    const Text(
                      'Category Color',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children:
                          _colors.map((color) {
                            final isSelected = _selectedColor == color['hex'];

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedColor = color['hex'];
                                });
                              },
                              child: Column(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _hexToColor(color['hex']),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                                : Colors.transparent,
                                        width: 2,
                                      ),
                                      boxShadow:
                                          isSelected
                                              ? [
                                                BoxShadow(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                      .withOpacity(0.5),
                                                  spreadRadius: 1,
                                                  blurRadius: 4,
                                                ),
                                              ]
                                              : null,
                                    ),
                                    child:
                                        isSelected
                                            ? Icon(
                                              Icons.check,
                                              color:
                                                  _hexToColor(
                                                            color['hex'],
                                                          ).computeLuminance() >
                                                          0.5
                                                      ? Colors.black
                                                      : Colors.white,
                                              size: 20,
                                            )
                                            : null,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    color['name'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
    );
  }
}
