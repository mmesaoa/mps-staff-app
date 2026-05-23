import '../../../core/api/api_client.dart';

class LeaveRepository {
  final ApiClient _apiClient;
  LeaveRepository(this._apiClient);

  // Fetches the leave history for the logged-in staff member
  Future<List<dynamic>> getMyLeaveRequests() async {
    final response = await _apiClient.dio.get('/staff/leave/my-requests');
    // The API returns paginated data; we extract the list.
    return response.data['data'];
  }

  // ✅ 1. ADD METHOD TO FETCH LEAVE TYPES
  Future<List<dynamic>> getLeaveTypes() async {
    final response = await _apiClient.dio.get('/staff/leave/types');
    return response.data['data'];
  }

  // ✅ 2. ADD METHOD TO SUBMIT THE LEAVE APPLICATION
  Future<void> applyForLeave({
    required int leaveTypeId,
    required String startDate,
    required String endDate,
    required String reason,
  }) async {
    await _apiClient.dio.post(
      '/staff/leave/apply',
      data: {
        'leave_type_id': leaveTypeId,
        'start_date': startDate,
        'end_date': endDate,
        'reason': reason,
      },
    );
  }

  // Admin: Fetch all leave requests
  Future<List<dynamic>> getAllLeaveRequests() async {
    final response = await _apiClient.dio.get('/staff/leave/all-requests');
    if (response.data is Map<String, dynamic> && response.data.containsKey('data')) {
      return response.data['data'];
    }
    return response.data;
  }

  // Admin: Update leave status
  Future<void> updateLeaveStatus({
    required int leaveId,
    required String status,
    String? remarks,
  }) async {
    await _apiClient.dio.patch(
      '/staff/leave/requests/$leaveId',
      data: {
        'status': status,
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
      },
    );
  }

}

