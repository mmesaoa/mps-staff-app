import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:school_erp_staff_app/shared/widgets/main_scaffold.dart';
import 'package:school_erp_staff_app/shared/widgets/shimmer_loading.dart';
import 'homework_providers.dart';

class HomeworkListScreen extends ConsumerStatefulWidget {
  const HomeworkListScreen({super.key});

  @override
  ConsumerState<HomeworkListScreen> createState() => _HomeworkListScreenState();
}

class _HomeworkListScreenState extends ConsumerState<HomeworkListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'All'; // 'All', 'Active', 'Overdue'
  bool _sortAscending = false; // False = newest due date first, True = oldest first

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeworkState = ref.watch(homeworkListProvider);
    final theme = Theme.of(context);

    return MainScaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(homeworkListProvider.future),
        child: Column(
          children: [
            // TOP CONTROL BAR
            _buildControlBar(theme),
            
            // HOMEWORK LIST
            Expanded(
              child: homeworkState.when(
                loading: () => SkeletonLoaders.cardList(),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (homeworks) {
                  // Apply Search & Filter
                  var filteredList = homeworks.where((hw) {
                    final titleMatch = hw['title'].toString().toLowerCase().contains(_searchController.text.toLowerCase());
                    final subjectMatch = hw['subject']['name'].toString().toLowerCase().contains(_searchController.text.toLowerCase());
                    final searchMatch = titleMatch || subjectMatch;

                    final dueDate = DateTime.parse(hw['due_date']);
                    final isOverdue = dueDate.isBefore(DateTime.now());

                    bool filterMatch = true;
                    if (_filterStatus == 'Active') filterMatch = !isOverdue;
                    if (_filterStatus == 'Overdue') filterMatch = isOverdue;

                    return searchMatch && filterMatch;
                  }).toList();

                  // Apply Sort
                  filteredList.sort((a, b) {
                    final dateA = DateTime.parse(a['due_date']);
                    final dateB = DateTime.parse(b['due_date']);
                    return _sortAscending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
                  });

                  if (filteredList.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(child: Text('No homework assignments found matching criteria.')),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      return _buildHomeworkCard(filteredList[index], theme);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.primaryColor,
        onPressed: () async {
          await context.push('/dashboard/homework/create');
          ref.invalidate(homeworkListProvider);
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildControlBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Search Field
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by title or subject...',
              prefixIcon: Icon(Icons.search, color: theme.primaryColor),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filter & Sort Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Filter Chips
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Active', 'Overdue'].map((status) {
                      final isSelected = _filterStatus == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(status),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _filterStatus = status);
                          },
                          selectedColor: theme.primaryColor.withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: isSelected ? theme.primaryColor : Colors.grey.shade700,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              // Sort Button
              InkWell(
                onTap: () => setState(() => _sortAscending = !_sortAscending),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.sort, size: 16, color: theme.primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        _sortAscending ? 'Oldest' : 'Newest',
                        style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHomeworkCard(Map<String, dynamic> homework, ThemeData theme) {
    final dueDate = DateTime.parse(homework['due_date']);
    final isOverdue = dueDate.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.go('/dashboard/homework/details/${homework['id']}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row: Subject Icon + Title + Status Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Box
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.menu_book, color: theme.primaryColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    // Title & Subject
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            homework['title'],
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            homework['subject']['name'],
                            style: TextStyle(color: Colors.blueGrey.shade600, fontWeight: FontWeight.w500, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOverdue ? Colors.red.shade50 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isOverdue ? Colors.red.shade200 : Colors.green.shade200),
                      ),
                      child: Text(
                        isOverdue ? 'Overdue' : 'Active',
                        style: TextStyle(
                          color: isOverdue ? Colors.red.shade700 : Colors.green.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                // Footer Row: Class details + Due Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Class & Section
                    Row(
                      children: [
                        Icon(Icons.people_outline, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${homework['school_class']['name']} - ${homework['section']['name']}',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                        ),
                      ],
                    ),
                    // Due Date
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: isOverdue ? Colors.red.shade600 : Colors.orange.shade800),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd MMM, yyyy').format(dueDate),
                          style: TextStyle(
                            color: isOverdue ? Colors.red.shade700 : Colors.orange.shade900,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}