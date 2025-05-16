import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'package:deadlinealert/models/deadline.dart';
import 'package:deadlinealert/models/category.dart';
import 'package:deadlinealert/providers/auth_provider.dart';
import 'package:deadlinealert/providers/deadline_provider.dart';
import 'package:deadlinealert/providers/category_provider.dart';
import 'package:deadlinealert/services/supabase_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  String? _selectedCategoryId;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabChange(int index) {
    setState(() {
      _currentIndex = index;
      // Reset selected category when changing tabs
      if (_currentIndex != 3) {
        _selectedCategoryId = null;
      }
    });
  }

  void _addNewDeadline() {
    context.go('/deadline/new');
  }

  void _editDeadline(String id) {
    context.go('/deadline/$id');
  }

  void _toggleDeadlineCompletion(String id, bool currentStatus) {
    final authState = ref.read(authProvider);
    ref
        .read(deadlineProvider(authState.deviceId).notifier)
        .toggleDeadlineCompletion(id, !currentStatus);
  }

  void _showDeleteConfirmation(BuildContext context, String id, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF8B0000).withOpacity(0.9),
          title: const Text(
            'Confirm Delete',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to delete "$title"?',
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                // Delete the deadline
                final authState = ref.read(authProvider);
                ref
                    .read(deadlineProvider(authState.deviceId).notifier)
                    .deleteDeadline(id);
                Navigator.of(context).pop();
                // Show feedback to user
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted "$title"'),
                    backgroundColor: Colors.red.shade700,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _deleteDeadline(String id, String title) {
    _showDeleteConfirmation(context, id, title);
  }

  void _openSettings() {
    context.go('/settings');
  }

  void _selectCategory(String? categoryId) {
    setState(() {
      _selectedCategoryId =
          categoryId == _selectedCategoryId ? null : categoryId;
    });
  }

  void _rescheduleOverdue() {
    // Show a dialog or navigate to a screen where users can reschedule overdue tasks
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF8B0000).withOpacity(0.9),
            title: const Text(
              'Reschedule Overdue Tasks',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'This feature will allow you to reschedule all overdue tasks to a new date.',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();

                  // Show date picker
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFF8B0000),
                            onPrimary: Colors.white,
                            surface: Color(0xFF6B0000),
                            onSurface: Colors.white,
                          ),
                          dialogBackgroundColor: const Color(0xFF4B0000),
                        ),
                        child: child!,
                      );
                    },
                  );

                  if (pickedDate != null) {
                    final authState = ref.read(authProvider);
                    final rescheduledCount = await ref
                        .read(deadlineProvider(authState.deviceId).notifier)
                        .rescheduleOverdueDeadlines(pickedDate);

                    // Show success message with count
                    if (!context.mounted) return;

                    final formattedDate =
                        "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                    String message =
                        rescheduledCount > 0
                            ? '$rescheduledCount task${rescheduledCount > 1 ? 's' : ''} rescheduled to $formattedDate'
                            : 'No tasks to reschedule';

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        backgroundColor: const Color(0xFF006400), // Dark green
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: const Text(
                  'Reschedule All',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 70, color: Colors.white.withOpacity(0.6)),
          const SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineItem(Deadline deadline, {bool showOptions = true}) {
    final authState = ref.read(authProvider);
    final categoryState = ref.watch(categoryProvider(authState.deviceId));
    final category = categoryState.findById(deadline.categoryId);

    final dateFormat = DateFormat('h:mm a');
    final formattedTime = dateFormat.format(deadline.dueDate);

    // Define priority colors
    final priorityColors = {
      Priority.low: Colors.green,
      Priority.medium: Colors.orange,
      Priority.high: Colors.red.shade500,
    };

    final priorityColor = priorityColors[deadline.priority] ?? Colors.orange;

    return Slidable(
      key: ValueKey(deadline.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _editDeadline(deadline.id),
            backgroundColor: Colors.white.withOpacity(0.3),
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Edit',
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
          ),
          SlidableAction(
            onPressed: (_) => _deleteDeadline(deadline.id, deadline.title),
            backgroundColor: Colors.red.withOpacity(0.7),
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        color: Colors.white.withOpacity(0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _editDeadline(deadline.id),
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.white.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox
                Transform.scale(
                  scale: 1.1,
                  child: Checkbox(
                    value: deadline.isCompleted,
                    onChanged: (value) {
                      if (value != null) {
                        _toggleDeadlineCompletion(
                          deadline.id,
                          deadline.isCompleted,
                        );
                      }
                    },
                    fillColor: MaterialStateProperty.resolveWith<Color>((
                      states,
                    ) {
                      if (states.contains(MaterialState.selected)) {
                        return Colors.white.withOpacity(0.8);
                      }
                      return Colors.white.withOpacity(0.3);
                    }),
                    checkColor: const Color(0xFF8B0000),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Priority indicator
                Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.only(top: 2, right: 12),
                  decoration: BoxDecoration(
                    color: priorityColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        deadline.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                          decoration:
                              deadline.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                        ),
                      ),
                      if (deadline.description != null &&
                          deadline.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            deadline.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ),
                      // Category
                      if (category != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: category.colorValue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                category.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                // Time
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  child: Text(
                    formattedTime,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayScreen() {
    final authState = ref.watch(authProvider);
    final deadlineState = ref.watch(deadlineProvider(authState.deviceId));
    final todayDeadlines = deadlineState.todayDeadlines;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF8B0000), // Dark red
            const Color(0xFF6B0000), // Even darker red
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        margin: const EdgeInsets.only(right: 12),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hari Ini',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${todayDeadlines.length} tugas',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: _openSettings,
                  ),
                ],
              ),
            ),

            // Overdue section
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => context.go('/overdue'),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          const Text(
                            'Overdue ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${deadlineState.overdueDeadlines.length}',
                            style: TextStyle(
                              color: Colors.red.shade300,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _rescheduleOverdue,
                    child: Text(
                      'Reschedule',
                      style: TextStyle(
                        color: Colors.red.shade300,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Deadline list
            Expanded(
              child:
                  todayDeadlines.isEmpty
                      ? _buildEmptyState(
                        'No deadlines due today',
                        Icons.check_circle_outline,
                      )
                      : ListView.builder(
                        itemCount: todayDeadlines.length,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemBuilder: (context, index) {
                          return _buildDeadlineItem(todayDeadlines[index]);
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingScreen() {
    final authState = ref.watch(authProvider);
    final deadlineState = ref.watch(deadlineProvider(authState.deviceId));

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF8B0000), // Dark red
            const Color(0xFF6B0000), // Even darker red
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        margin: const EdgeInsets.only(right: 12),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Upcoming',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${deadlineState.upcomingDeadlines.length} tugas',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: _openSettings,
                  ),
                ],
              ),
            ),

            // Deadline list
            Expanded(
              child:
                  deadlineState.upcomingDeadlines.isEmpty
                      ? _buildEmptyState(
                        'No upcoming deadlines',
                        Icons.event_note,
                      )
                      : ListView.builder(
                        itemCount: deadlineState.upcomingDeadlines.length,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemBuilder: (context, index) {
                          return _buildDeadlineItem(
                            deadlineState.upcomingDeadlines[index],
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchScreen() {
    final authState = ref.watch(authProvider);
    final deadlineState = ref.watch(deadlineProvider(authState.deviceId));

    // Filter deadlines based on search query
    final filteredDeadlines =
        _searchQuery.isEmpty
            ? deadlineState.deadlines
            : deadlineState.deadlines
                .where(
                  (deadline) =>
                      deadline.title.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      (deadline.description != null &&
                          deadline.description!.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          )),
                )
                .toList();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF8B0000), // Dark red
            const Color(0xFF6B0000), // Even darker red
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        margin: const EdgeInsets.only(right: 12),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const Text(
                        'Search',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: _openSettings,
                  ),
                ],
              ),
            ),

            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search deadlines...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                          : null,
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: 16),

            // Results count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Text(
                    'Results',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${filteredDeadlines.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Deadline list
            Expanded(
              child:
                  filteredDeadlines.isEmpty
                      ? _buildEmptyState(
                        _searchQuery.isEmpty
                            ? 'No deadlines found'
                            : 'No results for "$_searchQuery"',
                        Icons.search_off,
                      )
                      : ListView.builder(
                        itemCount: filteredDeadlines.length,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemBuilder: (context, index) {
                          return _buildDeadlineItem(filteredDeadlines[index]);
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesScreen() {
    final authState = ref.watch(authProvider);
    final categoryState = ref.watch(categoryProvider(authState.deviceId));
    final deadlineState = ref.watch(deadlineProvider(authState.deviceId));

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF8B0000), // Dark red
            const Color(0xFF6B0000), // Even darker red
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        margin: const EdgeInsets.only(right: 12),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const Text(
                        'Categories',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: _openSettings,
                  ),
                ],
              ),
            ),

            // Add category button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton.icon(
                onPressed: () => context.go('/category/new'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Category'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Categories list or selected category
            Expanded(
              child:
                  _selectedCategoryId == null
                      ? _buildCategoriesList(categoryState, deadlineState)
                      : _buildCategoryDetails(categoryState, deadlineState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesList(
    CategoryState categoryState,
    DeadlineState deadlineState,
  ) {
    if (categoryState.categories.isEmpty) {
      return _buildEmptyState('No categories yet', Icons.category_outlined);
    }

    return ListView.builder(
      itemCount: categoryState.categories.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final category = categoryState.categories[index];
        final deadlines = deadlineState.getDeadlinesByCategory(category.id);
        final completedCount = deadlines.where((d) => d.isCompleted).length;
        final progress =
            deadlines.isEmpty ? 0.0 : completedCount / deadlines.length;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: Colors.white.withOpacity(0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _selectCategory(category.id),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: category.colorValue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          category.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        '${deadlines.length} tasks',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      PopupMenuButton(
                        icon: Icon(
                          Icons.more_vert,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        color: const Color(0xFF6B0000),
                        itemBuilder:
                            (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Edit',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            context.go('/category/${category.id}');
                          } else if (value == 'delete') {
                            final authState = ref.read(authProvider);
                            ref
                                .read(
                                  categoryProvider(authState.deviceId).notifier,
                                )
                                .deleteCategory(category.id);

                            // Show feedback
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Deleted "${category.name}" category',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      color: category.colorValue,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$completedCount of ${deadlines.length} completed',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryDetails(
    CategoryState categoryState,
    DeadlineState deadlineState,
  ) {
    final category = categoryState.findById(_selectedCategoryId!);
    final deadlines = deadlineState.getDeadlinesByCategory(_selectedCategoryId);

    if (category == null) {
      // If category not found, reset and show all categories
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedCategoryId = null;
        });
      });
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: category.colorValue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => setState(() => _selectedCategoryId = null),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Tasks count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            '${deadlines.length} tasks in this category',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Task list
        Expanded(
          child:
              deadlines.isEmpty
                  ? _buildEmptyState(
                    'No tasks in this category',
                    Icons.task_alt,
                  )
                  : ListView.builder(
                    itemCount: deadlines.length,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemBuilder: (context, index) {
                      return _buildDeadlineItem(deadlines[index]);
                    },
                  ),
        ),
      ],
    );
  }

  // Get the current screen based on selected index
  Widget _getScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildTodayScreen();
      case 1:
        return _buildUpcomingScreen();
      case 2:
        return _buildSearchScreen();
      case 3:
        return _buildCategoriesScreen();
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getScreen(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewDeadline,
        elevation: 4,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF8B0000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _handleTabChange,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF8B0000),
          unselectedItemColor: Colors.grey.shade600,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Today',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month),
              label: 'Upcoming',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
            BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Browse'),
          ],
        ),
      ),
    );
  }
}
