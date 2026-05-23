// lib/features/exam_marks/presentation/marks_entry_screen.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/marks_models.dart';
import 'marks_controller.dart';

class MarksEntryScreen extends ConsumerWidget {
  final int examId, classId, sectionId;
  final String header;
  const MarksEntryScreen({super.key, required this.examId, required this.classId, required this.sectionId, required this.header});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marksState = ref.watch(marksEntryControllerProvider(
      examId: examId, classId: classId, sectionId: sectionId
    ));
    final notifier = ref.read(marksEntryControllerProvider(
      examId: examId, classId: classId, sectionId: sectionId
    ).notifier);
    
    return Scaffold(
      appBar: AppBar(title: Text(header)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          try {
            final msg = await notifier.saveAllMarks();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
          } catch(e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
          }
        },
        label: const Text('Save All Marks'),
        icon: const Icon(Icons.save),
      ),
      body: SafeArea(
        child: marksState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
  
  
          // ✅ 2. IMPROVE THE ERROR WIDGET
          error: (e, st) {
            String errorMessage = 'An unexpected error occurred. Please try again.';
            // Check if the error is a DioException and if it has a response with data
            if (e is DioException && e.response?.data is Map) {
              // Use the 'message' from the server's JSON response
              errorMessage = e.response!.data['message'] ?? 'Failed to load data. Check your selection.';
            } else {
              // Fallback for other types of errors
              errorMessage = 'Error: Could not connect to the server.';
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.red.shade700),
                ),
              ),
            );
          },
  
  
          data: (data) {
            final List<MarkDistribution> distributions = data['distributions'];
            final List<StudentMarksEntry> students = data['students'];
  
            return ListView.builder(
              padding: const EdgeInsets.all(8).copyWith(bottom: 80),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ExpansionTile(
                   title: Text('${student.fullName} (Roll: ${student.rollNo})'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: distributions.map((dist) {
                            final mark = student.marks.firstWhere((m) => m.distributionId == dist.id);
                            final isAbsent = mark.attendanceStatus == 'absent';
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text('${dist.subjectName}\n(${dist.examTypeName})', style: const TextStyle(fontSize: 12)),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      initialValue: mark.marksObtained?.toString() ?? '',
                                      decoration: InputDecoration(
                                        labelText: 'Max ${dist.maxMarks}',
                                        border: const OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      keyboardType: TextInputType.number,
                                      enabled: !isAbsent,
                                      onChanged: (value) => notifier.updateMark(student.id, dist.id, value),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    children: [
                                      const Text('Absent', style: TextStyle(fontSize: 10)),
                                      Switch(
                                        value: isAbsent,
                                        onChanged: (value) => notifier.updateAttendance(student.id, dist.id, value),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}