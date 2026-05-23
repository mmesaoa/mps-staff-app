import '../../../core/api/api_client.dart';

class NoticeRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> getNotices({required int studentId}) async {
    final response = await _apiClient.dio.get(
      '/parent/notices',
      queryParameters: {'student_id': studentId},
    );
    return response.data['data'];
  }
}