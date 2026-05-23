import '../../../core/api/api_client.dart';

class StudentRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> searchStudents({String query = ''}) async {
    final response = await _apiClient.dio.get(
      '/staff/students',
      queryParameters: {'search': query},
    );
    // API returns paginated data, we just want the list for now
    return response.data['data'];
  }

 Future<Map<String, dynamic>> getStudentProfile({required int studentId}) async {
    final response = await _apiClient.dio.get('/staff/students/$studentId');
    return response.data['data'];
  }
}
