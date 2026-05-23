import '../../../core/api/api_client.dart';

class AttendanceRepository {
  final ApiClient _apiClient;
  AttendanceRepository(this._apiClient);

  Future<List<dynamic>> getClassesWithSections() async {
    // ✅ RENAMED ENDPOINT FOR CLARITY AND SECURITY
    final response = await _apiClient.dio.get('/staff/data/classes-with-sections');
    return response.data['data'];
  }

  // ✅ UPDATED METHOD TO ACCEPT AND SEND THE DATE
  Future<List<dynamic>> getStudentsForSection(int sectionId, String date) async {
    final response = await _apiClient.dio.get(
      '/staff/sections/$sectionId/students',
      queryParameters: {'date': date}, // Send date as a query parameter
    );
    return response.data['data'];
  }

  Future<void> submitAttendance({
    required int sectionId,
    required String date,
    required List<Map<String, dynamic>> attendances,
  }) async {
    await _apiClient.dio.post(
      '/staff/attendance',
      data: {
        'section_id': sectionId,
        'date': date,
        'attendances': attendances,
      },
    );
  }
}