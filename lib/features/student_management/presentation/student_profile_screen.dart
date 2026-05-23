import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_staff_app/core/api/api_client.dart';
import 'package:school_erp_staff_app/core/api/api_providers.dart';
import 'student_profile_controller.dart';

class StudentProfileScreen extends ConsumerWidget {
  final int studentId;
  const StudentProfileScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(studentProfileControllerProvider(studentId));

    return Scaffold(
      appBar: AppBar(title: const Text('Student Profile')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(studentProfileControllerProvider(studentId).future),
        child: profileState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (profile) {
            // ✅ 2. GET API CLIENT FROM RIVERPOD
            final storageBaseUrl = ref.watch(apiClientProvider).storageBaseUrl;

            // Construct the full URL if the path exists
            final photoPath = profile['photo_url'] ?? profile['student_photo'];
            String? photoUrl;
            if (photoPath != null && photoPath.toString().isNotEmpty) {
              if (photoPath.toString().startsWith('http')) {
                photoUrl = photoPath.toString();
              } else {
                photoUrl = '$storageBaseUrl$photoPath';
              }
            }

            final feeSummary = profile['fee_summary'] as Map<String, dynamic>? ?? {};

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // ✅ 3. PASS THE FULL URL TO THE HEADER
                _ProfileHeader(profile: profile, fullPhotoUrl: photoUrl),
                const SizedBox(height: 24),
                _SummaryCards(profile: profile, feeSummary: feeSummary),
                const SizedBox(height: 16),
                _ProfileDetailSection(
                  title: 'Personal Details',
                  details: {
                    'Date of Birth': profile['date_of_birth'],
                    'Gender': profile['gender'],
                    'Blood Group': profile['blood_group'],
                    'Category': profile['category'],
                  },
                ),
                _ProfileDetailSection(
                  title: 'Parent & Contact Information',
                  details: {
                    'Student Phone': profile['student_phone'],
                    'Student Email': profile['student_email'],
                    'Father Name': profile['father_name'],
                    'Father Phone': profile['father_phone'],
                    'Mother Name': profile['mother_name'],
                    'Mother Phone': profile['mother_phone'],
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> profile;
  // ✅ 4. ACCEPT THE FULL URL
  final String? fullPhotoUrl;
  const _ProfileHeader({required this.profile, this.fullPhotoUrl});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            // ✅ 5. USE THE FULL URL
            backgroundImage: fullPhotoUrl != null
                ? NetworkImage(fullPhotoUrl!)
                : null,
            child: fullPhotoUrl == null
                ? const Icon(Icons.person, size: 50)
                : null,
          ),
          const SizedBox(height: 16),
          Text(profile['full_name'] ?? 'N/A', style: Theme.of(context).textTheme.headlineSmall),
          Text('Class: ${profile['class'] ?? 'N/A'} - ${profile['section'] ?? 'N/A'}'),
          Text('Adm No: ${profile['admission_no'] ?? 'N/A'} | Roll No: ${profile['roll_no'] ?? 'N/A'}'),
        ],
      ),
    );
  }
}

// ... The rest of the file (_SummaryCards, _SummaryCard, _ProfileDetailSection) remains exactly the same ...
class _SummaryCards extends StatelessWidget {
  final Map<String, dynamic> profile;
  final Map<String, dynamic> feeSummary;
  const _SummaryCards({required this.profile, required this.feeSummary});

  @override
  Widget build(BuildContext context) {
    final currency = feeSummary['currency_symbol'] ?? '';
    final totalDue = feeSummary['total_due'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Attendance',
            subtitle: 'This Month',
            value: '${profile['attendance_percentage'] ?? 0}%',
            icon: Icons.check_circle_outline,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            title: 'Fees Due',
            value: '$currency${totalDue}',
            icon: Icons.account_balance_wallet_outlined,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
            if (subtitle != null)
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileDetailSection extends StatelessWidget {
  final String title;
  final Map<String, String?> details;
  const _ProfileDetailSection({required this.title, required this.details});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 20),
            ...details.entries
              .where((entry) => entry.value != null && entry.value!.isNotEmpty)
              .map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key, style: TextStyle(color: Colors.grey.shade600)),
                    Text(entry.value!, style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }
}