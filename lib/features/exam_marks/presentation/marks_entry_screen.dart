import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/api_error_widget.dart';
import '../domain/marks_models.dart';
import 'marks_controller.dart';

class MarksEntryScreen extends ConsumerStatefulWidget {
  final int examId, classId, sectionId;
  final String header;
  const MarksEntryScreen({super.key, required this.examId, required this.classId, required this.sectionId, required this.header});

  @override
  ConsumerState<MarksEntryScreen> createState() => _MarksEntryScreenState();
}

class _MarksEntryScreenState extends ConsumerState<MarksEntryScreen> {
  bool _isSubmitting = false;

  Future<void> _submitMarks() async {
    setState(() => _isSubmitting = true);
    try {
      final notifier = ref.read(marksEntryControllerProvider(
        examId: widget.examId, classId: widget.classId, sectionId: widget.sectionId
      ).notifier);
      final msg = await notifier.saveAllMarks();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        final message = e is ApiException ? e.message : e.toString();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final marksState = ref.watch(marksEntryControllerProvider(
      examId: widget.examId, classId: widget.classId, sectionId: widget.sectionId
    ));
    final notifier = ref.read(marksEntryControllerProvider(
      examId: widget.examId, classId: widget.classId, sectionId: widget.sectionId
    ).notifier);
    
    return Scaffold(
      appBar: AppBar(title: Text(widget.header)),
      bottomNavigationBar: marksState.hasValue ? Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -4),
              blurRadius: 8,
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: Colors.orange, // Match the theme color
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              )
            ),
            onPressed: _isSubmitting ? null : _submitMarks,
            child: _isSubmitting 
                ? const SizedBox(
                    width: 24, height: 24, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                : const Text('Save All Marks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ) : null,
      body: SafeArea(
        child: marksState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) {
            final exception = err is ApiException ? err : ApiException.server(err.toString());
            return ApiErrorWidget(
              error: exception,
              onRetry: () => ref.refresh(marksEntryControllerProvider(
                examId: widget.examId, classId: widget.classId, sectionId: widget.sectionId
              )),
            );
          },
          data: (data) {
            final List<MarkDistribution> distributions = data['distributions'];
            final List<StudentMarksEntry> students = data['students'];
  
            return ListView.builder(
              padding: const EdgeInsets.all(8),
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