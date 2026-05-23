import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../attendance/presentation/attendance_providers.dart';
import '../data/notice_repository.dart';

// ✅ THE FIX: Import the controller file.
import 'create_notice_controller.dart';

// A provider for the repository itself
final noticeRepositoryProvider = Provider<NoticeRepository>((ref) {
  return NoticeRepository(ref.watch(apiClientProvider));
});

// A provider to fetch the list of notices
final noticeListProvider = FutureProvider.autoDispose<List<dynamic>>((ref) {
  return ref.watch(noticeRepositoryProvider).getNotices();
});

// A provider for our new controller
final createNoticeControllerProvider = Provider.autoDispose((ref) {
  // This line will now work correctly because of the import above.
  return CreateNoticeController(ref.read(noticeRepositoryProvider));
});