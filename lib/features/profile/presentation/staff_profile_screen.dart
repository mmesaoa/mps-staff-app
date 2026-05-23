// lib/features/profile/presentation/staff_profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_staff_app/shared/widgets/main_scaffold.dart';
import 'package:school_erp_staff_app/core/api/api_client.dart';
import 'package:school_erp_staff_app/core/api/api_providers.dart';
import 'package:school_erp_staff_app/features/profile/data/staff_profile_models.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:school_erp_staff_app/features/auth/presentation/auth_controller.dart';
import 'widgets/change_password_dialog.dart';

class StaffProfileScreen extends ConsumerStatefulWidget {
  const StaffProfileScreen({super.key});

  @override
  ConsumerState<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends ConsumerState<StaffProfileScreen> {
  bool _isLoading = true;
  StaffProfileData? _profileData;
  String? _errorMessage;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final dio = ApiClient().dio;
      final response = await dio.get('/staff/hr/my-profile');
      setState(() {
        _profileData = StaffProfileData.fromJson(response.data);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (pickedFile == null) return;

    setState(() { _isUploading = true; });

    try {
      final dio = ApiClient().dio;
      final file = File(pickedFile.path);

      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(file.path, filename: pickedFile.name),
      });

      final response = await dio.post('/staff/hr/my-profile/update-image', data: formData);
      
      if (response.data['photo_url'] != null) {
        await _fetchProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated successfully!'), backgroundColor: Colors.green));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() { _isUploading = false; });
      }
    }
  }

  void _showChangePasswordDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ChangePasswordDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'My Profile',
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
          : _profileData == null 
            ? const Center(child: Text('No profile data found.'))
            : RefreshIndicator(
                onRefresh: _fetchProfile,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _buildHeaderConfig(context),
                      _buildInfoCards(context),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildHeaderConfig(BuildContext context) {
    final user = _profileData!.user;
    final staff = _profileData!.staff;
    final theme = Theme.of(context);
    final storageBaseUrl = ref.watch(apiClientProvider).storageBaseUrl;

    String? fullAvatarUrl;
    if (user.avatar != null && user.avatar!.isNotEmpty) {
      if (user.avatar!.startsWith('http')) {
        fullAvatarUrl = user.avatar;
      } else {
        fullAvatarUrl = '$storageBaseUrl${user.avatar}';
      }
      // Add timestamp to break cache
      fullAvatarUrl = '$fullAvatarUrl?t=${DateTime.now().millisecondsSinceEpoch}';
    }

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 56,
                backgroundColor: theme.primaryColor.withOpacity(0.1),
                backgroundImage: fullAvatarUrl != null ? NetworkImage(fullAvatarUrl) : null,
                child: fullAvatarUrl == null ? Text(user.name[0].toUpperCase(), style: TextStyle(fontSize: 44, color: theme.primaryColor)) : null,
              ),
              if (_isUploading)
                const Positioned.fill(
                  child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
                )
              else if (ref.watch(authControllerProvider).value?.role != 'school_admin')
                GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: theme.primaryColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(user.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          if (staff?.designation != null && staff!.designation != 'N/A')
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(staff.designation!, style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
            ),
          
          const SizedBox(height: 12),
          // ACTIVE BADGE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: Colors.green.shade600, borderRadius: BorderRadius.circular(6)),
            child: const Text('ACTIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
          ),
          
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showChangePasswordDialog,
            icon: const Icon(Icons.lock_reset, size: 18),
            label: const Text('Change Password'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white, backgroundColor: theme.primaryColor,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards(BuildContext context) {
    final staff = _profileData!.staff;
    if (staff == null) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Text("Detailed staff records are only available for internal roles.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildGlassmorphicCard(
            title: 'Professional Details',
            children: [
              _buildDataRow('Staff ID', staff.staffIdCard ?? 'N/A'),
              _buildDataRow('Department', staff.department ?? 'N/A'),
              _buildDataRow('Designation', staff.designation ?? 'N/A'),
              _buildDataRow('Basic Salary', staff.basicSalary != null ? '₹${staff.basicSalary}' : 'N/A'),
              _buildDataRow(
                'Date of Joining', 
                staff.dateOfJoining != null 
                  ? DateFormat('dd MMM, yyyy').format(DateTime.parse(staff.dateOfJoining!)) 
                  : 'N/A'
              ),
              _buildDataRow('Work Experience', staff.workExperience ?? 'N/A'),
            ],
          ),
          const SizedBox(height: 16),
          _buildGlassmorphicCard(
            title: 'Personal Details',
            children: [
              _buildDataRow(
                'Date of Birth', 
                staff.dateOfBirth != null 
                  ? DateFormat('dd MMM, yyyy').format(DateTime.parse(staff.dateOfBirth!)) 
                  : 'N/A'
              ),
              _buildDataRow('Gender', staff.gender ?? 'N/A'),
              _buildDataRow('Marital Status', staff.maritalStatus ?? 'N/A'),
              _buildDataRow('Qualification', staff.qualification ?? 'N/A'),
              _buildDataRow('Father Name', staff.fatherName ?? 'N/A'),
              _buildDataRow('Mother Name', staff.motherName ?? 'N/A'),
            ],
          ),
          const SizedBox(height: 16),
          _buildGlassmorphicCard(
            title: 'Contact Information',
            children: [
              _buildDataRow('Phone', staff.phone ?? 'N/A'),
              _buildDataRow('Emergency Contact', staff.emergencyContact ?? 'N/A'),
              _buildDataRow('Email', _profileData!.user.email),
              _buildDataRow('Current Address', staff.currentAddress ?? 'N/A', isExpanded: true),
              _buildDataRow('Permanent Address', staff.permanentAddress ?? 'N/A', isExpanded: true),
            ],
          ),
          const SizedBox(height: 16),
          _buildGlassmorphicCard(
            title: 'Bank Account Details',
            children: [
              _buildDataRow('Account Title', staff.bankAccountTitle ?? 'N/A'),
              _buildDataRow('Bank Name', staff.bankName ?? 'N/A'),
              _buildDataRow('Branch Name', staff.bankBranchName ?? 'N/A'),
              _buildDataRow('Account Number', staff.bankAccountNumber ?? 'N/A'),
              _buildDataRow('IFSC Code', staff.bankIfscCode ?? 'N/A'),
            ],
          ),
          const SizedBox(height: 16),
          _buildGlassmorphicCard(
            title: 'Social Media Links',
            children: [
              _buildDataRow('Facebook', staff.facebookUrl ?? 'N/A', isExpanded: true),
              _buildDataRow('Twitter', staff.twitterUrl ?? 'N/A', isExpanded: true),
              _buildDataRow('LinkedIn', staff.linkedinUrl ?? 'N/A', isExpanded: true),
              _buildDataRow('Instagram', staff.instagramUrl ?? 'N/A', isExpanded: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassmorphicCard({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.shade50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade100, width: 1.5),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal, color: Colors.black87)),
          const SizedBox(height: 12),
          const Divider(thickness: 1, color: Colors.black12),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value, {bool isExpanded = false}) {
    if (isExpanded) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            flex: 3,
            child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
