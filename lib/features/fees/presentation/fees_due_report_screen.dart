// lib/features/fees/presentation/fees_due_report_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_staff_app/shared/widgets/main_scaffold.dart';
import 'package:school_erp_staff_app/core/api/api_client.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

// Controller for managing 1k+ students with search and pagination
class FeesDueState {
  final List<dynamic> students;
  final bool isLoading;
  final bool isSendingReminder;
  final String searchQuery;
  final int currentPage;
  final bool hasMore;

  FeesDueState({
    this.students = const [],
    this.isLoading = false,
    this.isSendingReminder = false,
    this.searchQuery = '',
    this.currentPage = 1,
    this.hasMore = true,
  });

  FeesDueState copyWith({
    List<dynamic>? students,
    bool? isLoading,
    bool? isSendingReminder,
    String? searchQuery,
    int? currentPage,
    bool? hasMore,
  }) {
    return FeesDueState(
      students: students ?? this.students,
      isLoading: isLoading ?? this.isLoading,
      isSendingReminder: isSendingReminder ?? this.isSendingReminder,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class FeesDueController extends StateNotifier<FeesDueState> {
  FeesDueController() : super(FeesDueState()) {
    fetchStudents();
  }

  Timer? _searchTimer;

  void onSearchChanged(String query) {
    if (_searchTimer?.isActive ?? false) _searchTimer!.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      state = state.copyWith(searchQuery: query, currentPage: 1, students: [], hasMore: true);
      fetchStudents();
    });
  }

  Future<void> fetchStudents({bool loadMore = false}) async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);
    try {
      final dio = ApiClient().dio;
      final response = await dio.get(
        '/staff/report/fees-due',
        queryParameters: {
          'search': state.searchQuery,
          'page': state.currentPage,
        },
      );

      final List<dynamic> newStudents = response.data['data'];
      final bool hasMore = response.data['next_page_url'] != null;

      state = state.copyWith(
        students: loadMore ? [...state.students, ...newStudents] : newStudents,
        isLoading: false,
        hasMore: hasMore,
        currentPage: state.currentPage + 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> sendReminder(BuildContext context, String studentId) async {
    state = state.copyWith(isSendingReminder: true);
    try {
      final dio = ApiClient().dio;
      final response = await dio.post('/staff/report/send-fee-reminder/$studentId');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.data['message']), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send reminder'), backgroundColor: Colors.red),
      );
    } finally {
      state = state.copyWith(isSendingReminder: false);
    }
  }
}

final feesDueControllerProvider = StateNotifierProvider<FeesDueController, FeesDueState>((ref) {
  return FeesDueController();
});

class FeesDueReportScreen extends ConsumerWidget {
  const FeesDueReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(feesDueControllerProvider);
    final controller = ref.read(feesDueControllerProvider.notifier);

    return MainScaffold(
      title: 'Fees Due Report',
      body: Column(
        children: [
          // 1. Search Bar (Scale Optimization)
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: controller.onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search student or admission no...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // 2. Performance-optimized List
          Expanded(
            child: state.students.isEmpty && !state.isLoading
                ? const Center(child: Text('No students found with dues'))
                : NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification scrollInfo) {
                      if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                        controller.fetchStudents(loadMore: true);
                      }
                      return true;
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: state.students.length + (state.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == state.students.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        return _FeeDueItem(student: state.students[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FeeDueItem extends ConsumerWidget {
  final dynamic student;
  const _FeeDueItem({required this.student});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.red.shade50,
                child: const Icon(Icons.person, size: 20, color: Colors.red),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      '${student['class']} - ${student['section']}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('DUE', style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold)),
                  Text(
                    '₹${student['total_due']}',
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
