import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_erp_staff_app/core/api/api_providers.dart';
import 'package:school_erp_staff_app/shared/utils/debouncer.dart';
import 'package:school_erp_staff_app/shared/widgets/main_scaffold.dart';
import 'student_search_controller.dart';

class StudentSearchScreen extends ConsumerStatefulWidget {
  const StudentSearchScreen({super.key});

  @override
  ConsumerState<StudentSearchScreen> createState() => _StudentSearchScreenState();
}

class _StudentSearchScreenState extends ConsumerState<StudentSearchScreen> {
  final _debouncer = Debouncer(milliseconds: 500);
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(studentSearchControllerProvider);
    // ✅ Correct way to get the ApiClient instance from the provider
    final apiClient = ref.watch(apiClientProvider);

    return MainScaffold(
      // The MainScaffold provides the AppBar and Drawer
      body: Column(
        children: [
          // This search bar is now a separate, clean widget
          _SearchBar(
            controller: _searchController,
            onChanged: (query) {
              _debouncer.run(() {
                ref.read(studentSearchControllerProvider.notifier).search(query);
              });
            },
          ),
          Expanded(
            child: searchState.when(
              data: (students) {
                // ✅ Check if the search query is empty to show the initial view
                if (_searchController.text.isEmpty) {
                  return const _InitialSearchView();
                }
                if (students.isEmpty) {
                  return const Center(child: Text('No students found for this query.'));
                }
                // The existing ListView for results remains the same
                return ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final photoPath = student['photo_url'] ?? student['student_photo'];
                    String? photoUrl;
                    if (photoPath != null && photoPath.toString().isNotEmpty) {
                      if (photoPath.toString().startsWith('http')) {
                        photoUrl = photoPath.toString();
                      } else {
                        photoUrl = '${apiClient.storageBaseUrl}$photoPath';
                      }
                    }

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            photoUrl != null ? NetworkImage(photoUrl) : null,
                        child: photoUrl == null
                            ? Text(student['full_name']?[0] ?? 'S')
                            : null,
                      ),
                      title: Text(student['full_name'] ?? 'No Name'),
                      subtitle: Text(
                          'Class: ${student['class'] ?? 'N/A'} | Adm No: ${student['admission_no'] ?? 'N/A'}'),
                      onTap: () {
                        context.go('/dashboard/student-search/profile/${student['id']}');
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}


// A dedicated widget for the search input field
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Search by name or admission no...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        ),
        onChanged: onChanged,
      ),
    );
  }
}


// ✅ THIS IS THE NEW ENHANCED WIDGET FOR THE INITIAL VIEW
class _InitialSearchView extends StatelessWidget {
  const _InitialSearchView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 100,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
            ),
            const SizedBox(height: 24),
            Text(
              'Find a Student',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter a student\'s name or admission number in the search bar above to see their details.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}