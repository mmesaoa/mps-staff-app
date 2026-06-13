import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/student_dashboard_repository.dart';

final studentDashboardRepositoryProvider = Provider((ref) => StudentDashboardRepository());

class StudentDashboardState {
  final bool isLoading;
  final String? errorMessage;
  final Map<String, dynamic>? data;

  StudentDashboardState({
    this.isLoading = false,
    this.errorMessage,
    this.data,
  });

  StudentDashboardState copyWith({
    bool? isLoading,
    String? errorMessage,
    Map<String, dynamic>? data,
  }) {
    return StudentDashboardState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      data: data ?? this.data,
    );
  }
}

class StudentDashboardController extends StateNotifier<StudentDashboardState> {
  final StudentDashboardRepository _repository;

  StudentDashboardController(this._repository) : super(StudentDashboardState()) {
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final data = await _repository.fetchDashboardStats();
      state = state.copyWith(isLoading: false, data: data);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final studentDashboardControllerProvider =
    StateNotifierProvider<StudentDashboardController, StudentDashboardState>((ref) {
  final repo = ref.watch(studentDashboardRepositoryProvider);
  return StudentDashboardController(repo);
});
