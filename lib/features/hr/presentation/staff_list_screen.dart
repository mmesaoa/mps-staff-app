// lib/features/hr/presentation/staff_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_erp_staff_app/shared/widgets/main_scaffold.dart';
import 'package:school_erp_staff_app/core/api/api_client.dart';
import 'package:school_erp_staff_app/core/api/api_providers.dart';

final staffListProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ApiClient().dio;
  final response = await dio.get('/staff/hr/staff-list');
  return response.data['data'] as List<dynamic>;
});

class StaffListScreen extends ConsumerStatefulWidget {
  const StaffListScreen({super.key});

  @override
  ConsumerState<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends ConsumerState<StaffListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffListProvider);
    final storageBaseUrl = ref.watch(apiClientProvider).storageBaseUrl;

    return MainScaffold(
      title: 'Staff Directory & HR',
      body: staffAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (staffList) {
          final filteredList = staffList.where((staff) {
            final name = (staff['name'] ?? '').toString().toLowerCase();
            final dept = (staff['department'] ?? '').toString().toLowerCase();
            final query = _searchQuery.toLowerCase();
            return name.contains(query) || dept.contains(query);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search staff by name or department...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
              ),
              Expanded(
                child: filteredList.isEmpty
                  ? const Center(child: Text('No staff records found.'))
                  : ListView.builder(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        return _StaffListItem(
                          staff: filteredList[index],
                          storageBaseUrl: storageBaseUrl,
                        );
                      },
                    ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StaffListItem extends StatelessWidget {
  final dynamic staff;
  final String storageBaseUrl;
  const _StaffListItem({required this.staff, required this.storageBaseUrl});

  @override
  Widget build(BuildContext context) {
    final color = _getAttendanceColor(staff['attendance_today'] ?? 'Not Marked');
    
    final photoPath = staff['photo_url'] ?? staff['avatar'];
    String? fullPhotoUrl;
    if (photoPath != null && photoPath.toString().isNotEmpty) {
      if (photoPath.toString().startsWith('http')) {
        fullPhotoUrl = photoPath.toString();
      } else {
        fullPhotoUrl = '$storageBaseUrl$photoPath';
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: InkWell(
        onTap: () => context.push('/dashboard/staff-list/detail/${staff['id']}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.blue.shade50,
                backgroundImage: fullPhotoUrl != null ? NetworkImage(fullPhotoUrl) : null,
                child: fullPhotoUrl == null 
                    ? Text((staff['name'] ?? 'S')[0].toUpperCase(), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 24)) 
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staff['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${staff['designation']} • ${staff['department']}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MiniBadge(
                          label: staff['attendance_today'],
                          color: color,
                          icon: Icons.calendar_today,
                        ),
                        _MiniBadge(
                          label: '${staff['monthly_attendance_rate']}% Monthly',
                          color: Colors.blue,
                          icon: Icons.analytics,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAttendanceColor(String status) {
    switch (status.toLowerCase()) {
      case 'present': return Colors.green;
      case 'absent': return Colors.red;
      case 'late': return Colors.orange;
      default: return Colors.grey;
    }
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _MiniBadge({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
