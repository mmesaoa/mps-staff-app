import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_erp_staff_app/features/auth/presentation/auth_controller.dart';

class ScaffoldWithNavBar extends ConsumerWidget {
  /// The navigation shell and container for the branch Navigators.
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine the user's role to customize the 2nd tab
    final user = ref.watch(authControllerProvider).value;
    final isAdmin = user?.role == 'school_admin';
    final isTeacher = user?.role == 'teacher';

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (int index) => _onTap(context, index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          
          // DYNAMIC 2nd TAB
          if (isAdmin)
            const NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics),
              label: 'Attendance', // Admin views Staff Attendance
            )
          else if (isTeacher)
            const NavigationDestination(
              icon: Icon(Icons.schedule_outlined),
              selectedIcon: Icon(Icons.schedule),
              label: 'Timetable', // Teachers view their Timetable
            )
          else
            const NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics),
              label: 'My Logs', // Other staff view their own logs
            ),

          const NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign),
            label: 'Notices',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    // When navigating to a new branch, it's recommended to use the goBranch
    // method, as doing so ensures the last navigation state of the
    // branch (if there is one) is restored.
    navigationShell.goBranch(
      index,
      // A common pattern when tapping an active tab is to go to the initial location
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
