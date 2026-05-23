import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_erp_staff_app/core/api/api_providers.dart';
import 'package:school_erp_staff_app/features/auth/presentation/auth_controller.dart';
import 'package:school_erp_staff_app/utils/string_helpers.dart';

class MainScaffold extends ConsumerWidget {
  final Widget body;
  final Widget? floatingActionButton;
  final String? title;
  final List<Widget>? actions;
  final bool showAppBar;
  final bool useSafeArea;

  const MainScaffold({
    super.key,
    required this.body,
    this.floatingActionButton,
    this.title,
    this.actions,
    this.showAppBar = true,
    this.useSafeArea = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ 1. Get the AsyncValue object which wraps your user state.
    final asyncUser = ref.watch(authControllerProvider);
    // ✅ 2. Safely get the actual user data from the '.value' property.
    final user = asyncUser.value;
    
    // The rest of the logic now works correctly.
    final appBarTitle = title ?? user?.schoolName ?? 'Dashboard';

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: Text(appBarTitle),
              actions: actions,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            )
          : null,
      drawer: const AppDrawer(),
      body: useSafeArea ? SafeArea(child: body) : body,
      floatingActionButton: floatingActionButton,
    );
  }
}

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final user = ref.watch(authControllerProvider).value;
    final userRole = user?.role?.toLowerCase() ?? '';
    final isAdmin = userRole == 'school_admin';
    final isTeacher = userRole == 'teacher';

    return Drawer(
      child: SafeArea(
        top: true,
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerProfileHeader(),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Dashboard'),
              onTap: () {
                context.pop();
                context.go('/dashboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('My Profile'),
              onTap: () {
                context.pop();
                context.go('/my-profile');
              },
            ),

            // --- ATTENDANCE & LEAVE (FOR ALL STAFF) ---
            if (!isAdmin) ...[
              const Divider(),
              const Padding(
                padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
                child: Text('My Work', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.time_to_leave_outlined),
                title: const Text('My Leave'),
                onTap: () {
                  context.pop();
                  context.go('/dashboard/my-leave');
                },
              ),
              ListTile(
                leading: const Icon(Icons.analytics_outlined),
                title: const Text('My Attendance Logs'),
                onTap: () {
                  context.pop();
                  context.go('/staff-reports');
                },
              ),
            ],

            // --- ACADEMICS (TEACHER ONLY) ---
            if (isTeacher) ...[
              const Divider(),
              const Padding(
                padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
                child: Text('Academics', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_view_week_outlined),
                title: const Text('My Timetable'),
                onTap: () {
                  context.pop();
                  context.go('/my-timetable');
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_document),
                title: const Text('Homework'),
                onTap: () {
                  context.pop();
                  context.go('/dashboard/homework');
                },
              ),
            ],

            // --- SCHOOL OPERATIONS ---
            const Divider(),
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
              child: Text('School Operations', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            if (isTeacher || isAdmin) ...[
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('Student Search'),
                onTap: () {
                  context.pop();
                  context.go('/dashboard/student-search');
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text('Take Attendance'),
                onTap: () {
                  context.pop();
                  context.go('/dashboard/attendance');
                },
              ),
              ListTile(
                leading: const Icon(Icons.grading_outlined),
                title: const Text('Enter Exam Marks'),
                onTap: () {
                  context.pop();
                  context.go('/dashboard/exam-marks');
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.campaign_outlined),
              title: const Text('Notice Board'),
              onTap: () {
                context.pop();
                context.go('/notices');
              },
            ),

            // --- ADMIN SPECIFIC LINKS ---
            if (isAdmin) ...[
              const Divider(),
              const Padding(
                padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
                child: Text('Administration', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Staff List'),
                onTap: () {
                  context.pop();
                  context.go('/dashboard/staff-list');
                },
              ),
              ListTile(
                leading: const Icon(Icons.analytics_outlined),
                title: const Text('Staff Attend. Logs'),
                onTap: () {
                  context.pop();
                  context.go('/staff-reports');
                },
              ),
              ListTile(
                leading: const Icon(Icons.approval_outlined),
                title: const Text('Staff Leave Approval'),
                onTap: () {
                  context.pop();
                  context.go('/dashboard/staff-leave-approval');
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text('Fees Due'),
                onTap: () {
                  context.pop();
                  context.go('/dashboard/fees-reports');
                },
              ),
            ],

            const Divider(),
            const DrawerSecuritySection(),
            const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              ref.read(authControllerProvider.notifier).logout();
            },
          ),
        ],
      ),
      ),
    );
  }
}

class DrawerSecuritySection extends ConsumerStatefulWidget {
  const DrawerSecuritySection({super.key});

  @override
  ConsumerState<DrawerSecuritySection> createState() => _DrawerSecuritySectionState();
}

class _DrawerSecuritySectionState extends ConsumerState<DrawerSecuritySection> {
  bool? _isAvailable;
  bool _isEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricStatus();
  }

  Future<void> _loadBiometricStatus() async {
    final authController = ref.read(authControllerProvider.notifier);
    final available = await authController.isBiometricAvailable();
    final enabled = await authController.getBiometricPreference();
    if (mounted) {
      setState(() {
        _isAvailable = available;
        _isEnabled = enabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAvailable != true) return const SizedBox.shrink();

    final authController = ref.read(authControllerProvider.notifier);

    return SwitchListTile(
      secondary: const Icon(Icons.fingerprint),
      title: const Text('Biometric Login'),
      subtitle: Text(_isEnabled ? 'Enabled' : 'Disabled'),
      value: _isEnabled,
      onChanged: (value) async {
        await authController.setBiometricEnabled(value);
        setState(() {
          _isEnabled = value;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(value 
                ? 'Biometric login enabled!' 
                : 'Biometric login disabled!'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }
}

class DrawerProfileHeader extends ConsumerWidget {
  const DrawerProfileHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ Apply the same fix here to correctly access the user data.
    final asyncUser = ref.watch(authControllerProvider);
    final user = asyncUser.value;

    final storageBaseUrl = ref.watch(apiClientProvider).storageBaseUrl;
    
    final photoPath = user?.profilePhotoUrl;
    final fullPhotoUrl = (photoPath != null && photoPath.isNotEmpty) ? '$storageBaseUrl$photoPath' : null;

    return UserAccountsDrawerHeader(
      accountName: Text(
        user?.name ?? 'Not Logged In',
        style: const TextStyle(
          fontWeight: FontWeight.bold, 
          fontSize: 18,
          shadows: [Shadow(blurRadius: 2.0, color: Colors.black54)]
        ),
      ),
      accountEmail: Text(
        user?.role?.capitalize() ?? 'Staff Account',
        style: const TextStyle(
          shadows: [Shadow(blurRadius: 2.0, color: Colors.black54)]
        ),
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        image: fullPhotoUrl != null
            ? DecorationImage(
                image: NetworkImage(fullPhotoUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.5),
                  BlendMode.darken,
                ),
              )
            : null,
      ),
      currentAccountPicture: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        backgroundImage: fullPhotoUrl != null ? NetworkImage(fullPhotoUrl) : null,
        child: (user != null && fullPhotoUrl == null)
            ? Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 24,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              )
            : null,
      ),
    );
  }
}