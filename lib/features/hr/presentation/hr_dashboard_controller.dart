import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/hr_dashboard_repository.dart';

final hrDashboardRepositoryProvider = Provider((ref) => HrDashboardRepository());

class HrDashboardState {
  final bool isLoading;
  final String? errorMessage;
  final Map<String, dynamic>? data;

  HrDashboardState({
    this.isLoading = false,
    this.errorMessage,
    this.data,
  });

  HrDashboardState copyWith({
    bool? isLoading,
    String? errorMessage,
    Map<String, dynamic>? data,
  }) {
    return HrDashboardState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      data: data ?? this.data,
    );
  }
}

class HrDashboardController extends StateNotifier<HrDashboardState> {
  final HrDashboardRepository _repository;

  HrDashboardController(this._repository) : super(HrDashboardState()) {
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

final hrDashboardControllerProvider =
    StateNotifierProvider<HrDashboardController, HrDashboardState>((ref) {
  final repo = ref.watch(hrDashboardRepositoryProvider);
  return HrDashboardController(repo);
});
