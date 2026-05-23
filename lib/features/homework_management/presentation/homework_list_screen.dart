import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:school_erp_staff_app/shared/widgets/main_scaffold.dart';
import 'homework_providers.dart';

class HomeworkListScreen extends ConsumerWidget {
  const HomeworkListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeworkState = ref.watch(homeworkListProvider);

    return MainScaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(homeworkListProvider.future),
        child: homeworkState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Text('Error: $err'),
          ),
          data: (homeworks) {
            if (homeworks.isEmpty) {
              return const Center(
                child: Text('No homework assignments found. Tap + to create one.'),
              );
            }
            return ListView.builder(
              itemCount: homeworks.length,
              itemBuilder: (context, index) {
                final homework = homeworks[index];
                final dueDate = DateTime.parse(homework['due_date']);
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  child: ListTile(
                    title: Text(
                      homework['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Class: ${homework['school_class']['name']} - ${homework['section']['name']}',
                        ),
                        Text('Subject: ${homework['subject']['name']}'),
                        Text(
                          'Due Date: ${DateFormat('dd MMM, yyyy').format(dueDate)}',
                          style: TextStyle(
                            color: dueDate.isBefore(DateTime.now()) ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      context.go('/dashboard/homework/details/${homework['id']}');
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // ✅ THE FIX: Use context.push() which returns a Future, allowing you to await it.
          // This ensures the list is refreshed only after the user returns from the create screen.
          await context.push('/dashboard/homework/create');
          ref.invalidate(homeworkListProvider);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}