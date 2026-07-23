import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

// ✅ ADD THIS IMPORT STATEMENT to link to your core API services
import 'package:school_erp_staff_app/core/api/api_providers.dart';
import 'package:school_erp_staff_app/core/api/api_client.dart';
import 'package:school_erp_staff_app/core/branding/branding_providers.dart';
import 'package:school_erp_staff_app/shared/widgets/shimmer_loading.dart';

import 'homework_providers.dart';

class HomeworkDetailsScreen extends ConsumerWidget {
  final int homeworkId;
  const HomeworkDetailsScreen({super.key, required this.homeworkId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsState = ref.watch(homeworkDetailsProvider(homeworkId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Homework Submissions'),
      ),
      body: detailsState.when(
        loading: () => SkeletonLoaders.detailPage(),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (data) {
          final homework = data['homework'];
          final students = data['students'] as List;

          return RefreshIndicator(
            onRefresh: () =>
                ref.refresh(homeworkDetailsProvider(homeworkId).future),
            child: ListView.builder(
              itemCount: students.length + 1, // +1 for the header
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _HomeworkHeader(homework: homework);
                }
                final student = students[index - 1];
                final submission = (student['submissions'] as List).isNotEmpty
                    ? student['submissions'][0]
                    : null;

                return _SubmissionTile(
                  student: student,
                  submission: submission,
                  homeworkId: homeworkId,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _HomeworkHeader extends ConsumerWidget {
  final Map<String, dynamic> homework;
  const _HomeworkHeader({required this.homework});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = homework['title'] ?? 'No Title';
    final subject = homework['subject']?['name'] ?? 'N/A';
    final className = homework['school_class']?['name'] ?? 'N/A';
    final sectionName = homework['section']?['name'] ?? 'N/A';
    final dueDateStr = homework['due_date'] != null
        ? DateFormat('dd MMM, yyyy').format(DateTime.parse(homework['due_date']))
        : 'N/A';
    final description = homework['description'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('${ref.watch(terminologyProvider).subjectLabel}: $subject'),
          Text('${ref.watch(terminologyProvider).classLabel}: $className - $sectionName'),
          Text('Due Date: $dueDateStr'),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(description),
          ],
          const Divider(height: 32),
          Text('Student Submissions',
              style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _SubmissionTile extends ConsumerWidget {
  final Map<String, dynamic> student;
  final Map<String, dynamic>? submission;
  final int homeworkId;

  const _SubmissionTile({
    required this.student,
    this.submission,
    required this.homeworkId,
  });

  void _showEvaluationDialog(BuildContext context, WidgetRef ref) {
    final marksController = TextEditingController(text: submission?['marks']?.toString() ?? '');
    final remarksController = TextEditingController(text: submission?['remarks'] ?? '');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Evaluate Submission'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: marksController,
                    decoration: const InputDecoration(labelText: 'Marks (Optional)'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: remarksController,
                    decoration: const InputDecoration(labelText: 'Remarks (Optional)'),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setState(() => isSaving = true);
                          try {
                            await ref.read(homeworkEvaluationControllerProvider).submitEvaluation(
                                  submissionId: submission!['id'],
                                  marks: marksController.text.trim(),
                                  remarks: remarksController.text.trim(),
                                );
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Evaluation saved successfully')),
                              );
                              ref.refresh(homeworkDetailsProvider(homeworkId).future);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          } finally {
                            if (context.mounted) {
                              setState(() => isSaving = false);
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _viewSubmission(BuildContext context, ApiClient apiClient) async {
    final filePath = submission?['file_path'];
    if (filePath == null) return;

    final String fullUrl = "${apiClient.storageBaseUrl}$filePath";
    final Uri url = Uri.parse(fullUrl);

    if (!await canLaunchUrl(url)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the file: Invalid URL')),
      );
      }
      return;
    }
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This will now work because of the new import statement.
    final apiClient = ref.watch(apiClientProvider);

    Widget statusChip;
    bool isEvaluated = submission?['marks'] != null;

    if (submission == null) {
      statusChip =
          const Chip(label: Text('Not Submitted'), backgroundColor: Colors.grey);
    } else if (isEvaluated) {
      statusChip = Chip(
          label: Text('Marks: ${submission!['marks']}'),
          backgroundColor: Colors.green.shade600,
          labelStyle: const TextStyle(color: Colors.white));
    } else {
      statusChip = Chip(
          label: const Text('Submitted'),
          backgroundColor: Colors.blue.shade600,
          labelStyle: const TextStyle(color: Colors.white));
    }

    final studentName =
        "${student['first_name'] ?? ''} ${student['last_name'] ?? ''}".trim();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(studentName.isNotEmpty ? studentName : 'Unknown Student'),
        subtitle: Text('Roll No: ${student['roll_no'] ?? 'N/A'}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            statusChip,
            if (submission?['file_path'] != null)
              IconButton(
                icon: const Icon(Icons.open_in_new),
                onPressed: () => _viewSubmission(context, apiClient),
                tooltip: 'View Submission',
              ),
          ],
        ),
        onTap: (submission != null)
            ? () => _showEvaluationDialog(context, ref)
            : null,
      ),
    );
  }
}