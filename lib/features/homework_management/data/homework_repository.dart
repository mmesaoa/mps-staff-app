import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class HomeworkRepository {
  // ✅ THE FIX: Added the constructor to accept the ApiClient.
  final ApiClient _apiClient;
  HomeworkRepository(this._apiClient);

  Future<void> evaluateSubmission({
    required int submissionId,
    required String marks,
    String? remarks,
  }) async {
    await _apiClient.dio.post(
      '/staff/submissions/$submissionId/evaluate',
      data: {
        'marks': marks,
        'remarks': remarks ?? '',
      },
    );
  }

  Future<List<dynamic>> getHomeworkList() async {
    final response = await _apiClient.dio.get('/staff/homework');
    return response.data['data'];
  }

  Future<Map<String, dynamic>> getHomeworkDetails(int homeworkId) async {
    final response = await _apiClient.dio.get('/staff/homework/$homeworkId');
    return response.data['data'];
  }

  Future<List<dynamic>> getSubjectsForClass(int classId) async {
    final response = await _apiClient.dio.get('/staff/data/subjects-for-class/$classId');
    return response.data['data'];
  }

  Future<void> createHomework({
    required int classId,
    required int sectionId,
    required int subjectId,
    required String title,
    required String dueDate,
    String? description,
    String? filePath,
  }) async {
    final formData = FormData.fromMap({
      'school_class_id': classId,
      'section_id': sectionId,
      'subject_id': subjectId,
      'title': title,
      'due_date': dueDate,
      if (description != null) 'description': description,
      if (filePath != null) 'file': await MultipartFile.fromFile(filePath),
    });

    await _apiClient.dio.post('/staff/homework', data: formData);
  }
}