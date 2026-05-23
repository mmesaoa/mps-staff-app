// lib/features/hr/presentation/mark_staff_attendance_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_staff_app/shared/widgets/main_scaffold.dart';
import 'package:school_erp_staff_app/core/api/api_client.dart';
import 'package:intl/intl.dart';

class AttendanceItem {
  final String staffId;
  final String name;
  final String designation;
  final String? photoUrl;
  String status;
  String remarks;
  final bool hasPunch;

  AttendanceItem({
    required this.staffId,
    required this.name,
    required this.designation,
    this.photoUrl,
    this.status = 'Not Marked',
    this.remarks = '',
    this.hasPunch = false,
  });

  factory AttendanceItem.fromJson(Map<String, dynamic> json) {
    return AttendanceItem(
      staffId: json['id'].toString(),
      name: json['name'],
      designation: json['designation'],
      photoUrl: json['photo_url'],
      status: json['status'],
      remarks: json['remarks'],
      hasPunch: json['has_punch'] ?? false,
    );
  }
}

class StaffAttendanceState {
  final List<AttendanceItem> allStaff;
  final List<AttendanceItem> filteredStaff;
  final DateTime selectedDate;
  final bool isLoading;
  final bool isSaving;
  final String searchQuery;

  StaffAttendanceState({
    this.allStaff = const [],
    this.filteredStaff = const [],
    required this.selectedDate,
    this.isLoading = false,
    this.isSaving = false,
    this.searchQuery = '',
  });

  StaffAttendanceState copyWith({
    List<AttendanceItem>? allStaff,
    List<AttendanceItem>? filteredStaff,
    DateTime? selectedDate,
    bool? isLoading,
    bool? isSaving,
    String? searchQuery,
  }) {
    return StaffAttendanceState(
      allStaff: allStaff ?? this.allStaff,
      filteredStaff: filteredStaff ?? this.filteredStaff,
      selectedDate: selectedDate ?? this.selectedDate,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class StaffAttendanceController extends StateNotifier<StaffAttendanceState> {
  StaffAttendanceController() : super(StaffAttendanceState(selectedDate: DateTime.now())) {
    fetchStaff();
  }

  Future<void> fetchStaff() async {
    state = state.copyWith(isLoading: true);
    try {
      final dio = ApiClient().dio;
      final dateStr = DateFormat('yyyy-MM-dd').format(state.selectedDate);
      
      debugPrint('Fetching Staff Attendance for date: $dateStr');
      final response = await dio.get('/staff/hr/staff-attendance', queryParameters: {
        'date': dateStr,
      });

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Data: ${response.data}');

      final List<dynamic> rawData = response.data['data'] ?? [];
      final staff = rawData.map((e) => AttendanceItem.fromJson(e)).toList();

      state = state.copyWith(
        allStaff: staff,
        filteredStaff: _filterStaff(staff, state.searchQuery),
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error fetching staff: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  void onSearchChanged(String query) {
    state = state.copyWith(
      searchQuery: query,
      filteredStaff: _filterStaff(state.allStaff, query),
    );
  }

  void onStatusChanged(String staffId, String status) {
    final updatedAll = state.allStaff.map((s) {
      if (s.staffId == staffId) s.status = status;
      return s;
    }).toList();

    state = state.copyWith(
      allStaff: updatedAll,
      filteredStaff: _filterStaff(updatedAll, state.searchQuery),
    );
  }

  void onDateChanged(DateTime date) {
    state = state.copyWith(selectedDate: date, allStaff: [], filteredStaff: []);
    fetchStaff();
  }

  List<AttendanceItem> _filterStaff(List<AttendanceItem> staff, String query) {
    if (query.isEmpty) return staff;
    return staff.where((s) => s.name.toLowerCase().contains(query.toLowerCase())).toList();
  }

  Future<void> saveAttendance(BuildContext context) async {
    state = state.copyWith(isSaving: true);
    try {
      final dio = ApiClient().dio;
      final payload = {
        'date': DateFormat('yyyy-MM-dd').format(state.selectedDate),
        'attendances': state.allStaff
            .where((s) => s.status != 'Not Marked' && !s.hasPunch)
            .map((s) => {
                  'staff_id': s.staffId,
                  'status': s.status,
                  'remarks': s.remarks,
                })
            .toList(),
      };

      await dio.post('/staff/hr/staff-attendance', data: payload);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance saved successfully'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save attendance'), backgroundColor: Colors.red),
      );
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }
}

final staffAttendanceProvider = StateNotifierProvider<StaffAttendanceController, StaffAttendanceState>((ref) {
  return StaffAttendanceController();
});

class MarkStaffAttendanceScreen extends ConsumerWidget {
  const MarkStaffAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(staffAttendanceProvider);
    final controller = ref.read(staffAttendanceProvider.notifier);

    return MainScaffold(
      title: 'Staff Attendance',
      actions: [
        IconButton(
          onPressed: () => _selectDate(context, ref),
          icon: const Icon(Icons.calendar_today),
        ),
      ],
      body: Column(
        children: [
          // 1. Date & Search Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.event, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('EEEE, d MMMM yyyy').format(state.selectedDate),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: controller.onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search staff by name...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  ),
                ),
              ],
            ),
          ),

          // 2. Staff List
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.filteredStaff.isEmpty
                    ? const Center(child: Text('No staff found'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.filteredStaff.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final staff = state.filteredStaff[index];
                          return _StaffAttendanceCard(staff: staff);
                        },
                      ),
          ),

          // 3. Save Button
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: state.isSaving ? null : () => controller.saveAttendance(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: state.isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Attendance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, WidgetRef ref) async {
    final current = ref.read(staffAttendanceProvider).selectedDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      ref.read(staffAttendanceProvider.notifier).onDateChanged(picked);
    }
  }
}

class _StaffAttendanceCard extends ConsumerWidget {
  final AttendanceItem staff;
  const _StaffAttendanceCard({required this.staff});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue.shade50,
                child: const Icon(Icons.person, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(staff.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        if (staff.hasPunch) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.phone_android, size: 10, color: Colors.green.shade800),
                                const SizedBox(width: 4),
                                Text('Punched', style: TextStyle(fontSize: 9, color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(staff.designation, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatusButton(
                label: 'Present',
                color: Colors.green,
                isSelected: staff.status == 'Present',
                isDisabled: staff.hasPunch,
                onTap: () => staff.hasPunch ? null : ref.read(staffAttendanceProvider.notifier).onStatusChanged(staff.staffId, 'Present'),
              ),
              _StatusButton(
                label: 'Absent',
                color: Colors.red,
                isSelected: staff.status == 'Absent',
                isDisabled: staff.hasPunch,
                onTap: () => staff.hasPunch ? null : ref.read(staffAttendanceProvider.notifier).onStatusChanged(staff.staffId, 'Absent'),
              ),
              _StatusButton(
                label: 'Late',
                color: Colors.orange,
                isSelected: staff.status == 'Late',
                isDisabled: staff.hasPunch,
                onTap: () => staff.hasPunch ? null : ref.read(staffAttendanceProvider.notifier).onStatusChanged(staff.staffId, 'Late'),
              ),
              _StatusButton(
                label: 'Half Day',
                color: Colors.blue,
                isSelected: staff.status == 'Half Day',
                isDisabled: staff.hasPunch,
                onTap: () => staff.hasPunch ? null : ref.read(staffAttendanceProvider.notifier).onStatusChanged(staff.staffId, 'Half Day'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.color,
    required this.isSelected,
    this.isDisabled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDisabled ? color.withOpacity(0.5) : color) 
              : (isDisabled ? Colors.grey.shade100 : Colors.transparent),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected 
              ? (isDisabled ? color.withOpacity(0.5) : color) 
              : (isDisabled ? Colors.grey.shade200 : Colors.grey.shade300)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected 
                ? Colors.white 
                : (isDisabled ? Colors.grey.shade400 : Colors.grey.shade700),
          ),
        ),
      ),
    );
  }
}
