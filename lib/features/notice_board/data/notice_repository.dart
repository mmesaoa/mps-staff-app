import '../../../core/api/api_client.dart';

class NoticeRepository {
  final ApiClient _apiClient;
  NoticeRepository(this._apiClient);

  Future<List<dynamic>> getNotices() async {
    final response = await _apiClient.dio.get('/staff/notices');
    return response.data['data'];
  }

  // ✅ ADD THIS NEW METHOD TO POST THE NOTICE
  Future<void> createNotice({
    required String title,
    required String content,
    required String publishedAt,
    required String recipientType,
    int? noticableId,
  }) async {
    await _apiClient.dio.post(
      '/staff/notices',
      data: {
        'title': title,
        'content': content,
        'published_at': publishedAt,
        'recipient_type': recipientType,
        'noticable_id': noticableId,
      },
    );
  }
}