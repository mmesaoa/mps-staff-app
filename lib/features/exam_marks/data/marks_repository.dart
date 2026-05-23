// lib/features/exam_marks/data/marks_repository.dart
import 'package:school_erp_staff_app/core/api/api_client.dart';
import '../domain/marks_models.dart';

class MarksRepository {
  final ApiClient _apiClient;
  MarksRepository(this._apiClient);

  Future<Map<String, dynamic>> getOptions() async {
    final response = await _apiClient.dio.get('/staff/exam-marks/options');
    return {
      'exams': (response.data['exams'] as List).map((e) => Exam.fromJson(e)).toList(),
      // 'classes' is no longer returned here
    };
  }

  // ✅ ADD THIS NEW METHOD
  Future<List<SchoolClass>> getClassesForExam(int examId) async {
    final response = await _apiClient.dio.get('/staff/exam-marks/classes/$examId');
    return (response.data as List).map((c) => SchoolClass.fromJson(c)).toList();
  }

  Future<List<Section>> getSections(int classId) async {
    final response = await _apiClient.dio.get('/staff/exam-marks/sections/$classId');
    return (response.data as List).map((s) => Section.fromJson(s)).toList();
  }
  
  Future<Map<String, dynamic>> getStudentsAndStructure({
    required int examId, required int classId, required int sectionId
  }) async {
    final response = await _apiClient.dio.get('/staff/exam-marks/students', queryParameters: {
      'exam_id': examId, 'class_id': classId, 'section_id': sectionId
    });
    return {
      'distributions': (response.data['distributions'] as List).map((d) => MarkDistribution.fromJson(d)).toList(),
      'students': (response.data['students'] as List).map((s) => StudentMarksEntry.fromJson(s)).toList(),
    };
  }
  
  Future<String> saveMarks(List<Map<String, dynamic>> marks) async {
    final response = await _apiClient.dio.post('/staff/exam-marks/store', data: {'marks': marks});
    return response.data['message'];
  }
}