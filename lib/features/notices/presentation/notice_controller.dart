import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package:school_erp_staff_app/features/dashboard/presentation/dashboard_controller.dart';
import '../data/notice_repository.dart';

final noticeControllerProvider =
    AsyncNotifierProvider<NoticeController, List<dynamic>>(
  NoticeController.new,
);

class NoticeController extends AsyncNotifier<List<dynamic>> {
  final _repository = NoticeRepository();

  @override
  FutureOr<List<dynamic>> build() {
    final selectedChild = ref.watch(dashboardControllerProvider).value?.selectedChild;
    if (selectedChild == null) throw 'No student selected.';

    return _repository.getNotices(studentId: selectedChild['id']);
  }
}