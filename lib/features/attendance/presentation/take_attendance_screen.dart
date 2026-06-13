// lib/features/attendance/presentation/take_attendance_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/api_error_widget.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import 'attendance_controller.dart';

class TakeAttendanceScreen extends ConsumerStatefulWidget {
  final int sectionId;
  final String date;
  const TakeAttendanceScreen(
      {super.key, required this.sectionId, required this.date});

  @override
  ConsumerState<TakeAttendanceScreen> createState() =>
      _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends ConsumerState<TakeAttendanceScreen> {
  bool _isSubmitting = false;
  bool _isViewOnly = false;

  @override
  void initState() {
    super.initState();
    // Determine if the screen should be in "view only" mode.
    // This happens if the selected date is before today.
    try {
      final attendanceDate = DateFormat('yyyy-MM-dd').parse(widget.date);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      _isViewOnly = attendanceDate.isAfter(today); 
    } catch (e) {
      // If date parsing fails, default to view only for safety.
      _isViewOnly = true;
    }
  }

  Future<void> _submitAttendance() async {
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(attendanceControllerProvider(widget.sectionId, widget.date)
              .notifier)
          .submitAttendance();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Attendance Submitted Successfully!'),
              backgroundColor: Colors.green,
            ));
        // Go back to the previous screen on success.
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        final message = e is ApiException ? e.message : e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
            ));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendanceAsyncState =
        ref.watch(attendanceControllerProvider(widget.sectionId, widget.date));

    return Scaffold(
      appBar: AppBar(
        title: Text(_isViewOnly ? 'View Attendance' : 'Take Attendance'),
        actions: [
          // Only show action buttons if it's not "view only" mode.
          if (!_isViewOnly && attendanceAsyncState.hasValue)
            IconButton(
              icon: const Icon(Icons.checklist, color: Colors.white),
              tooltip: 'Mark All Present',
              // Disable if all students are locked
              onPressed: attendanceAsyncState.value!.lockedStudentIds.length == attendanceAsyncState.value!.students.length
                  ? null 
                  : () => ref
                      .read(attendanceControllerProvider(widget.sectionId, widget.date)
                          .notifier)
                      .markAllAsPresent(),
            ),
        ],
      ),
      bottomNavigationBar: !_isViewOnly && attendanceAsyncState.hasValue
          ? Container(
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
                    backgroundColor: Colors.orange, // Based on the user's FAB color
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    )
                  ),
                  onPressed: _isSubmitting || (attendanceAsyncState.value!.lockedStudentIds.length == attendanceAsyncState.value!.students.length)
                      ? null 
                      : _submitAttendance,
                  child: _isSubmitting 
                      ? const SizedBox(
                          width: 24, height: 24, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : const Text('Submit Attendance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: attendanceAsyncState.when(
          loading: () => SkeletonLoaders.listTile(),
          error: (err, stack) {
            final exception = err is ApiException ? err : ApiException.server(err.toString());
            return ApiErrorWidget(
              error: exception,
              onRetry: () => ref.refresh(attendanceControllerProvider(widget.sectionId, widget.date)),
            );
          },
          data: (state) {
            final students = state.students;
            if (students.isEmpty) {
              return const Center(child: Text('No students found in this section.'));
            }

            return Column(
              children: [
                const _AttendanceLegend(),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: students.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final student = students[index];
                      final studentId = student['id'] as int;
                      final isLocked = state.lockedStudentIds.contains(studentId);
                      
                      return _StudentAttendanceTile(
                        student: student,
                        status: state.attendanceMap[studentId],
                        isLocked: isLocked,
                        // Pass null for onStatusChanged if in "view only" mode OR if individual record is locked
                        onStatusChanged: (_isViewOnly || isLocked)
                            ? null
                            : (newStatus) {
                                ref
                                    .read(attendanceControllerProvider(
                                            widget.sectionId, widget.date)
                                        .notifier)
                                    .updateStatus(studentId, newStatus);
                              },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Widget for the instructional legend at the top of the screen.
class _AttendanceLegend extends StatelessWidget {
  const _AttendanceLegend();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Wrap(
        spacing: 16.0,
        runSpacing: 8.0,
        alignment: WrapAlignment.center,
        children: const [
          _LegendItem(icon: Icons.check_circle_outline, label: 'Present', color: Colors.green),
          _LegendItem(icon: Icons.cancel_outlined, label: 'Absent', color: Colors.red),
          _LegendItem(icon: Icons.watch_later_outlined, label: 'Late', color: Colors.orange),
          _LegendItem(icon: Icons.star_half_outlined, label: 'Half Day', color: Colors.blue),
        ],
      ),
    );
  }
}

// Helper widget for each item in the legend.
class _LegendItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _LegendItem({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}


// Widget for each student's attendance selection row.
class _StudentAttendanceTile extends StatelessWidget {
  final Map<String, dynamic> student;
  final String? status; // Can be null for "Not Marked"
  final bool isLocked;
  final ValueChanged<String>? onStatusChanged; // Is null in "view only" mode or if record is locked

  const _StudentAttendanceTile({
    required this.student,
    this.status,
    this.isLocked = false,
    this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(
        children: [
          Expanded(child: Text(student['full_name'] ?? 'Unknown Student')),
          if (isLocked)
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Icon(Icons.lock_outline, size: 14, color: Colors.grey),
            ),
        ],
      ),
      subtitle: Text('Roll No: ${student['roll_no'] ?? 'N/A'}'),
      trailing: SizedBox(
        width: 220,
        child: Opacity(
          opacity: isLocked ? 0.7 : 1.0,
          child: SegmentedButton<String>(
            segments: const <ButtonSegment<String>>[
              ButtonSegment<String>(
                  value: 'Present',
                  icon: Tooltip(message: 'Present', child: Icon(Icons.check_circle_outline))),
              ButtonSegment<String>(
                  value: 'Absent',
                  icon: Tooltip(message: 'Absent', child: Icon(Icons.cancel_outlined))),
              ButtonSegment<String>(
                  value: 'Late',
                  icon: Tooltip(message: 'Late', child: Icon(Icons.watch_later_outlined))),
              ButtonSegment<String>(
                  value: 'Half Day',
                  icon: Tooltip(message: 'Half Day', child: Icon(Icons.star_half_outlined))),
            ],
            
            // If status is null, the set is empty, and NO button is selected.
            selected: status == null ? <String>{} : <String>{status!},
            
            // The onSelectionChanged callback is disabled if it's null.
            onSelectionChanged: onStatusChanged == null ? null : (newSelection) {
              onStatusChanged!(newSelection.first);
            },
            
            emptySelectionAllowed: true,
  
            style: ButtonStyle(
               tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: WidgetStateProperty.all<EdgeInsets>(
                const EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
          ),
        ),
      ),
    );
  }
}