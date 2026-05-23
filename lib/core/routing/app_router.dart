import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_erp_staff_app/features/auth/presentation/auth_controller.dart';
import 'package:school_erp_staff_app/shared/widgets/scaffold_with_navbar.dart';

// Import all your screen files...
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/staff_dashboard_screen.dart';
import '../../features/student_management/presentation/student_profile_screen.dart';
import '../../features/student_management/presentation/student_search_screen.dart';
import '../../features/attendance/presentation/select_section_screen.dart';
import '../../features/attendance/presentation/take_attendance_screen.dart';
import '../../features/attendance/presentation/self_attendance_screen.dart';
import '../../features/homework_management/presentation/homework_list_screen.dart';
import '../../features/homework_management/presentation/homework_details_screen.dart';
import '../../features/homework_management/presentation/create_homework_screen.dart';
import '../../features/leave_management/presentation/my_leave_requests_screen.dart';
import '../../features/leave_management/presentation/apply_for_leave_screen.dart';
import '../../features/notice_board/presentation/notice_list_screen.dart';
import '../../features/notice_board/presentation/create_notice_screen.dart';
import '../../features/notice_board/presentation/notice_detail_screen.dart';
import '../../features/timetable/presentation/timetable_screen.dart';
import '../../features/exam_marks/presentation/marks_selection_screen.dart';
import '../../features/leave_management/presentation/admin_leave_approval_screen.dart';

import '../../features/hr/presentation/staff_directory_screen.dart';
import '../../features/hr/presentation/staff_list_screen.dart';
import '../../features/hr/presentation/staff_detail_screen.dart';
import '../../features/hr/presentation/mark_staff_attendance_screen.dart';
import '../../features/hr/presentation/staff_attendance_report_screen.dart';
import '../../features/fees/presentation/fees_due_report_screen.dart';
import '../../features/chatbot/presentation/chatbot_screen.dart';
import '../../features/profile/presentation/staff_profile_screen.dart';

// Global Key for root navigator
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final user = authState.value;
  final isAdmin = user?.role == 'school_admin';

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isLoggedIn = user != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/chatbot',
        builder: (context, state) => const ChatbotScreen(),
      ),

      // StatefulShellRoute creates the Bottom Navigation UI
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          // Wrap the navigation shell in our custom ScaffoldWithNavBar
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // ==============================
          // BRANCH 1: Dashboard (Home)
          // ==============================
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const StaffDashboardScreen(),
                routes: [
                  // Sub-routes available from the Drawer or Quick Links on the Home tab
                  GoRoute(
                    path: 'self-attendance',
                    builder: (context, state) => const SelfAttendanceScreen(),
                  ),
                  GoRoute(
                    path: 'student-search',
                    builder: (context, state) => const StudentSearchScreen(),
                    routes: [
                      GoRoute(
                        path: 'profile/:studentId',
                        builder: (context, state) {
                          final studentId = int.parse(state.pathParameters['studentId']!);
                          return StudentProfileScreen(studentId: studentId);
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'attendance',
                    builder: (context, state) => const SelectSectionScreen(),
                    routes: [
                      GoRoute(
                        path: 'take/:sectionId',
                        builder: (context, state) {
                          final sectionId = int.parse(state.pathParameters['sectionId']!);
                          final date = state.uri.queryParameters['date']!;
                          return TakeAttendanceScreen(sectionId: sectionId, date: date);
                        },
                      )
                    ],
                  ),
                  GoRoute(
                    path: 'homework',
                    builder: (context, state) => const HomeworkListScreen(),
                    routes: [
                      GoRoute(
                        path: 'create',
                        builder: (context, state) => const CreateHomeworkScreen(),
                      ),
                      GoRoute(
                        path: 'details/:homeworkId',
                        builder: (context, state) {
                          final homeworkId = int.parse(state.pathParameters['homeworkId']!);
                          return HomeworkDetailsScreen(homeworkId: homeworkId);
                        },
                      )
                    ],
                  ),
                  GoRoute(
                    path: 'my-leave',
                    builder: (context, state) => const MyLeaveRequestsScreen(),
                    routes: [
                      GoRoute(
                        path: 'apply',
                        builder: (context, state) => const ApplyForLeaveScreen(),
                      )
                    ],
                  ),
                  GoRoute(
                    path: 'staff-directory',
                    builder: (context, state) => const StaffDirectoryScreen(),
                  ),
                  GoRoute(
                    path: 'staff-list',
                    builder: (context, state) => const StaffListScreen(),
                    routes: [
                      GoRoute(
                        path: 'detail/:staffId',
                        builder: (context, state) {
                          final staffId = state.pathParameters['staffId']!;
                          return StaffDetailScreen(staffId: staffId);
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'exam-marks',
                    builder: (context, state) => const MarksSelectionScreen(),
                  ),
                  // Admin specific deep links
                  GoRoute(
                    path: 'staff-leave-approval',
                    builder: (context, state) => const AdminLeaveApprovalScreen(),
                  ),
                  GoRoute(
                    path: 'fees-reports',
                    builder: (context, state) => const FeesDueReportScreen(),
                  ),
                  GoRoute(
                    path: 'mark-staff-attendance',
                    builder: (context, state) => const MarkStaffAttendanceScreen(),
                  ),
                ],
              ),
            ],
          ),

          // ==============================
          // BRANCH 2: Dynamic Role Based (Admin=Reports, Teacher=Timetable)
          // ==============================
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/staff-reports',
                builder: (context, state) => const StaffAttendanceReportScreen(),
              ),
              if (!isAdmin)
                GoRoute(
                  path: '/my-timetable',
                  builder: (context, state) => const TimetableScreen(),
                ),
            ],
          ),

          // ==============================
          // BRANCH 3: Notices
          // ==============================
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notices',
                builder: (context, state) => const NoticeListScreen(),
                routes: [
                  GoRoute(
                    path: 'create',
                    builder: (context, state) => const CreateNoticeScreen(),
                  ),
                  GoRoute(
                    path: 'detail',
                    builder: (context, state) {
                      final notice = state.extra as Map<String, dynamic>;
                      return NoticeDetailScreen(notice: notice);
                    },
                  ),
                ],
              ),
            ],
          ),

          // ==============================
          // BRANCH 4: Profile
          // ==============================
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/my-profile',
                builder: (context, state) => const StaffProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});