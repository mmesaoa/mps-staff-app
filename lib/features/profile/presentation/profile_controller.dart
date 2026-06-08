import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_staff_app/features/dashboard/presentation/dashboard_controller.dart';
import '../data/profile_repository.dart';

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, Map<String, dynamic>>(
  ProfileController.new,
);

class ProfileController extends AsyncNotifier<Map<String, dynamic>> {
  final _repository = ProfileRepository();

  @override
  FutureOr<Map<String, dynamic>> build() {
    final selectedChild = ref.watch(dashboardControllerProvider).value?.selectedChild;
    if (selectedChild == null) throw 'No student selected.';

    return _repository.getStudentProfile(studentId: selectedChild['id']);
  }
}