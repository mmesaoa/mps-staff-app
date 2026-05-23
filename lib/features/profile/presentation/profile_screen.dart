import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package:school_erp_staff_app/shared/widgets/main_scaffold.dart';
import 'profile_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);

    return MainScaffold(
      title: 'Student Profile',
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (profile) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _ProfileHeader(profile: profile),
                const SizedBox(height: 24),

                // Details Section
                _ProfileDetailSection(
                  title: 'Personal Details',
                  details: {
                    'Date of Birth': profile['date_of_birth'] ?? 'N/A',
                    'Gender': profile['gender'] ?? 'N/A',
                    'Category': profile['category'] ?? 'N/A',
                  },
                ),
                _ProfileDetailSection(
                  title: 'Contact Information',
                  details: {
                    // ✅ THE FIX: Add null checks with a fallback value
                    'Phone': profile['student_phone'] ?? 'N/A',
                    'Email': profile['student_email'] ?? 'N/A',
                  },
                ),
                 _ProfileDetailSection(
                  title: 'Parent Information',
                  details: {
                    // ✅ THE FIX: Add null checks for all parent fields
                    'Father Name': profile['father_name'] ?? 'N/A',
                    'Father Phone': profile['father_phone'] ?? 'N/A',
                    'Mother Name': profile['mother_name'] ?? 'N/A',
                    'Mother Phone': profile['mother_phone'] ?? 'N/A',
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// _ProfileHeader widget remains the same...
class _ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> profile;
  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: profile['photo_url'] != null
                ? NetworkImage(profile['photo_url'])
                : null,
            child: profile['photo_url'] == null
                ? const Icon(Icons.person, size: 50)
                : null,
          ),
          const SizedBox(height: 16),
          Text(profile['full_name'], style: Theme.of(context).textTheme.headlineSmall),
          Text('Class: ${profile['class']} - ${profile['section']}'),
          Text('Roll No: ${profile['roll_no']}'),
        ],
      ),
    );
  }
}


// _ProfileDetailSection widget remains the same...
class _ProfileDetailSection extends StatelessWidget {
  final String title;
  final Map<String, String> details;
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
            ...details.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key, style: const TextStyle(color: Colors.grey)),
                  Text(entry.value, style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}