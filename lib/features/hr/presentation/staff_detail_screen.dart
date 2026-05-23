// lib/features/hr/presentation/staff_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_staff_app/shared/widgets/main_scaffold.dart';
import 'package:school_erp_staff_app/core/api/api_client.dart';
import 'package:url_launcher/url_launcher.dart';

final staffDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final dio = ApiClient().dio;
  final response = await dio.get('/staff/hr/staff-list/$id');
  return response.data as Map<String, dynamic>;
});

class StaffDetailScreen extends ConsumerWidget {
  final String staffId;
  const StaffDetailScreen({super.key, required this.staffId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffDetailProvider(staffId));

    return MainScaffold(
      title: 'Staff Profile',
      body: staffAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (staff) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Profile Header (Premium Card)
              _buildProfileHeader(context, staff),
              const SizedBox(height: 25),

              // 2. Monthly Vitals
              const Text('Monthly Vitals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _buildVitalsGrid(staff),
              const SizedBox(height: 30),

              // 3. Employment Details
              const Text('Employment Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _buildInfoSection([
                _InfoItem(label: 'Designation', value: staff['designation']),
                _InfoItem(label: 'Department', value: staff['department']),
                _InfoItem(label: 'Joining Date', value: staff['joining_date'] ?? 'N/A'),
                _InfoItem(label: 'Qualification', value: staff['qualification'] ?? 'N/A'),
              ]),
              const SizedBox(height: 30),

              // 4. Salary & Financials
              const Text('Financial Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _buildSalaryCard(staff),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, Map<String, dynamic> staff) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 37,
                  backgroundImage: staff['photo_url'] != null ? NetworkImage(staff['photo_url']) : null,
                  child: staff['photo_url'] == null ? const Icon(Icons.person, size: 40) : null,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staff['name'],
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      staff['staff_id'],
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        staff['designation'],
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 40, color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _HeaderAction(icon: Icons.call, label: 'Call', onTap: () => _launchCaller(staff['phone'])),
              _HeaderAction(icon: Icons.email, label: 'Email', onTap: () => _launchEmail(staff['email'])),
              _HeaderAction(icon: Icons.badge, label: 'ID Card', onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsGrid(Map<String, dynamic> staff) {
    return Row(
      children: [
        _VitalCard(
          label: 'Attendance',
          value: '${staff['monthly_attendance_rate']}%',
          icon: Icons.calendar_month,
          color: Colors.green,
        ),
        const SizedBox(width: 15),
        _VitalCard(
          label: 'Workload',
          value: '${staff['workload']} Classes',
          icon: Icons.menu_book,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildSalaryCard(Map<String, dynamic> staff) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          _RowItem(label: 'Basic Salary', value: '₹${staff['basic_salary']}'),
          const Divider(height: 20),
          _RowItem(label: 'Allowances', value: '₹${staff['allowances']}'),
          const Divider(height: 20),
          _RowItem(label: 'Deductions', value: '₹${staff['deductions']}'),
          const Divider(height: 20),
          _RowItem(
            label: 'Net Payable',
            value: '₹${staff['net_salary']}',
            valueStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(List<_InfoItem> items) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item.label, style: TextStyle(color: Colors.grey.shade600)),
              Text(item.value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        )).toList(),
      ),
    );
  }

  void _launchCaller(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  void _launchEmail(String email) async {
    final url = Uri.parse('mailto:$email');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }
}

class _VitalCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _VitalCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HeaderAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }
}

class _InfoItem {
  final String label, value;
  _InfoItem({required this.label, required this.value});
}

class _RowItem extends StatelessWidget {
  final String label, value;
  final TextStyle? valueStyle;

  const _RowItem({required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
        Text(value, style: valueStyle ?? const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
