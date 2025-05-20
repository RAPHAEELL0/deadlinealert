import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:deadlinealert/models/deadline.dart';
import 'package:deadlinealert/models/category.dart';
import 'package:deadlinealert/providers/auth_provider.dart';
import 'package:deadlinealert/providers/deadline_provider.dart';
import 'package:deadlinealert/providers/category_provider.dart';

class DeadlineFormScreen extends ConsumerStatefulWidget {
  final String? deadlineId;

  const DeadlineFormScreen({super.key, this.deadlineId});

  @override
  ConsumerState<DeadlineFormScreen> createState() => _DeadlineFormScreenState();
}

class _DeadlineFormScreenState extends ConsumerState<DeadlineFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _dueDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _dueTime = TimeOfDay.fromDateTime(
    DateTime.now().add(const Duration(hours: 1)),
  );
  String? _selectedCategoryId;
  Priority _selectedPriority = Priority.medium;
  List<int> _reminderMinutes = [30]; // Default reminder is 30 minutes before
  bool _isLoading = false;

  bool get _isEditing => widget.deadlineId != null;
  Deadline? _originalDeadline;

  @override
  void initState() {
    super.initState();
    _loadDeadline();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadDeadline() async {
    if (!_isEditing) return;

    setState(() {
      _isLoading = true;
    });

    final authState = ref.read(authProvider);
    final deadlines = ref.read(deadlineProvider(authState.deviceId)).deadlines;

    final deadline = deadlines.firstWhere(
      (d) => d.id == widget.deadlineId,
      orElse: () => throw Exception('Deadline not found'),
    );

    _originalDeadline = deadline;

    _titleController.text = deadline.title;
    _descriptionController.text = deadline.description ?? '';
    _dueDate = deadline.dueDate;
    _dueTime = TimeOfDay.fromDateTime(deadline.dueDate);
    _selectedCategoryId = deadline.categoryId;
    _selectedPriority = deadline.priority;
    _reminderMinutes = deadline.reminderMinutes;

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (pickedDate != null && pickedDate != _dueDate) {
      setState(() {
        _dueDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _dueTime.hour,
          _dueTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _dueTime,
    );

    if (pickedTime != null && pickedTime != _dueTime) {
      setState(() {
        _dueTime = pickedTime;
        _dueDate = DateTime(
          _dueDate.year,
          _dueDate.month,
          _dueDate.day,
          _dueTime.hour,
          _dueTime.minute,
        );
      });
    }
  }

  Future<void> _saveDeadline() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authState = ref.read(authProvider);

      final newDeadline = Deadline(
        id: _isEditing ? _originalDeadline!.id : null,
        title: _titleController.text.trim(),
        description:
            _descriptionController.text.trim().isNotEmpty
                ? _descriptionController.text.trim()
                : null,
        dueDate: _dueDate,
        categoryId: _selectedCategoryId,
        priority: _selectedPriority,
        reminderMinutes: _reminderMinutes,
      );

      if (_isEditing) {
        await ref
            .read(deadlineProvider(authState.deviceId).notifier)
            .updateDeadline(newDeadline);
      } else {
        await ref
            .read(deadlineProvider(authState.deviceId).notifier)
            .addDeadline(newDeadline);
      }

      if (mounted) {
        context.go('/home');
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

  void _toggleReminder(int minutes, bool value) {
    setState(() {
      if (value) {
        if (!_reminderMinutes.contains(minutes)) {
          _reminderMinutes.add(minutes);
        }
      } else {
        _reminderMinutes.remove(minutes);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final categoryState = ref.watch(categoryProvider(authState.deviceId));

    final dateFormat = DateFormat('EEEE, MMMM d, y');
    final timeFormat = DateFormat('h:mm a');

    final formattedDate = dateFormat.format(_dueDate);
    final formattedTime = timeFormat.format(_dueDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Deadline' : 'Add Deadline'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveDeadline,
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
                    // Title field
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'Enter a title for your deadline',
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                        hintText: 'Enter a description',
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // Due date section
                    const Text(
                      'Due Date',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            leading: const Icon(Icons.calendar_today),
                            title: Text(formattedDate),
                            onTap: _selectDate,
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            leading: const Icon(Icons.access_time),
                            title: Text(formattedTime),
                            onTap: _selectTime,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Category section
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (categoryState.categories.isEmpty)
                      Row(
                        children: [
                          const Text('No categories available'),
                          TextButton(
                            onPressed: () => context.push('/category/new'),
                            child: const Text('Create Category'),
                          ),
                        ],
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: _selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Select Category (optional)',
                          prefixIcon: Icon(Icons.category),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryId = value;
                          });
                        },
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('No category'),
                          ),
                          ...categoryState.categories.map((category) {
                            return DropdownMenuItem(
                              value: category.id,
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: category.colorValue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Text(category.name),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    const SizedBox(height: 24),

                    // Priority section
                    const Text(
                      'Priority',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildPriorityOption(Priority.low),
                        _buildPriorityOption(Priority.medium),
                        _buildPriorityOption(Priority.high),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Reminder section
                    const Text(
                      'Reminders',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      title: const Text('5 minutes before'),
                      value: _reminderMinutes.contains(5),
                      onChanged: (value) => _toggleReminder(5, value ?? false),
                    ),
                    CheckboxListTile(
                      title: const Text('15 minutes before'),
                      value: _reminderMinutes.contains(15),
                      onChanged: (value) => _toggleReminder(15, value ?? false),
                    ),
                    CheckboxListTile(
                      title: const Text('30 minutes before'),
                      value: _reminderMinutes.contains(30),
                      onChanged: (value) => _toggleReminder(30, value ?? false),
                    ),
                    CheckboxListTile(
                      title: const Text('1 hour before'),
                      value: _reminderMinutes.contains(60),
                      onChanged: (value) => _toggleReminder(60, value ?? false),
                    ),
                    CheckboxListTile(
                      title: const Text('1 day before'),
                      value: _reminderMinutes.contains(24 * 60),
                      onChanged:
                          (value) => _toggleReminder(24 * 60, value ?? false),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildPriorityOption(Priority priority) {
    // Define priority colors
    final priorityColors = {
      Priority.low: Colors.green,
      Priority.medium: Colors.orange,
      Priority.high: Colors.red.shade500,
    };

    // Define priority labels
    final priorityLabels = {
      Priority.low: 'Low',
      Priority.medium: 'Medium',
      Priority.high: 'High',
    };

    // Define priority icons
    final priorityIcons = {
      Priority.low: Icons.arrow_downward,
      Priority.medium: Icons.remove,
      Priority.high: Icons.arrow_upward,
    };

    final isSelected = _selectedPriority == priority;
    final color = priorityColors[priority]!;
    final label = priorityLabels[priority]!;
    final icon = priorityIcons[priority]!;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPriority = priority;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
