// lib/features/dashboard/presentation/widgets/analytics_widgets.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_erp_staff_app/core/config/app_colors.dart';
import 'package:school_erp_staff_app/core/api/api_providers.dart';
import 'package:school_erp_staff_app/features/auth/presentation/auth_controller.dart';
import 'package:school_erp_staff_app/utils/string_helpers.dart';

class AnalyticsHeroHeader extends ConsumerWidget {
  final Map<String, dynamic> data;
  const AnalyticsHeroHeader({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawRole = data['role'] ?? 'staff';
    final String displayRole;
    if (rawRole == 'school_admin') {
      displayRole = 'Administrator';
    } else if (rawRole == 'teacher') {
      displayRole = 'Teacher';
    } else {
      displayRole = rawRole.toString().capitalize();
    }

    final user = ref.watch(authControllerProvider).value;
    final storageBaseUrl = ref.watch(apiClientProvider).storageBaseUrl;
    final photoPath = user?.profilePhotoUrl;
    final fullPhotoUrl = (photoPath != null && photoPath.isNotEmpty) ? '$storageBaseUrl$photoPath' : null;

    final userName = (data['name'] ?? 'Staff Member').toString().toUpperCase();

    return Stack(
      children: [
        // Blue Background with Pattern
        Container(
          width: double.infinity,
          height: 135 + MediaQuery.of(context).padding.top,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary], // Dark navy gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Large overlapping translucent circles
              Positioned(
                top: -30,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(20),
                  ),
                ),
              ),
              Positioned(
                bottom: -80,
                right: 80,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(15),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Foreground Content
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 16.0, top: 16.0, bottom: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar with Hamburger Badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withAlpha(50),
                      backgroundImage: fullPhotoUrl != null ? NetworkImage(fullPhotoUrl) : null,
                      child: fullPhotoUrl == null 
                        ? Text(
                            userName.isNotEmpty ? userName[0] : 'S',
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                          )
                        : null,
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: GestureDetector(
                        onTap: () => Scaffold.of(context).openDrawer(),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0096C7),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.menu, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                
                // Name and Role
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayRole,
                        style: TextStyle(
                          color: Colors.white.withAlpha(200),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Icons (Search, Notifications)
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white, size: 28),
                  onPressed: () {
                    final links = AnalyticsQuickLinksRow.getQuickLinks(context, ref, data);
                    showSearch(context: context, delegate: MenuSearchDelegate(allLinks: links));
                  },
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none, color: Colors.white, size: 28),
                      onPressed: () => context.go('/notices'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // White Curved Bottom Overlapping the Blue
        Positioned(
          bottom: -1, // -1 to prevent any 1px gap line
          left: 0,
          right: 0,
          child: Container(
            height: 24,
            decoration: const BoxDecoration(
              color: AppColors.background, // Match the scaffold background
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
          ),
        ),
      ],
    );
  }
}

class AnalyticsTopMetricsRow extends StatelessWidget {
  final Map<String, dynamic> data;
  const AnalyticsTopMetricsRow({super.key, required this.data});

  List<_HeroChipData> _getMetrics() {
    final role = data['role'];
    if (role == 'school_admin') {
      return [
        _HeroChipData(Icons.check_circle_outline, '${data['student_attendance_percentage'] ?? 0}%', 'Attendance'),
        _HeroChipData(Icons.account_balance_wallet_outlined, '${data['currency_symbol'] ?? ''}${data['monthly_fee_collected']?.toStringAsFixed(0) ?? 0}', 'Collected'),
      ];
    } else if (role == 'teacher') {
      return [
        _HeroChipData(Icons.class_outlined, '${data['classes_today'] ?? 0}', 'Classes'),
        _HeroChipData(Icons.group_outlined, '${data['total_assigned_students'] ?? 0}', 'Students'),
      ];
    } else {
      return [
        _HeroChipData(Icons.fingerprint, '${data['my_attendance_percentage'] ?? 100}%', 'Attendance'),
        _HeroChipData(Icons.check_circle_outline, '${data['my_approved_leave'] ?? 0}', 'Leaves'),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _getMetrics();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: metrics.map((m) => Expanded(
          child: Container(
            margin: EdgeInsets.only(right: m == metrics.last ? 0 : 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(20),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(m.icon, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.value,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        m.label,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }
}

class _HeroChipData {
  final IconData icon;
  final String value;
  final String label;
  const _HeroChipData(this.icon, this.value, this.label);
}

class GlassmorphicCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const GlassmorphicCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onTap,
          splashColor: color.withAlpha((0.3 * 255).round()),
          highlightColor: color.withAlpha((0.1 * 255).round()),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withAlpha((0.15 * 255).round()), color.withAlpha((0.02 * 255).round())],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withAlpha((0.2 * 255).round()), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha((0.05 * 255).round()),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(Icons.chevron_right, color: color.withAlpha((0.5 * 255).round()), size: 16),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withAlpha((0.2 * 255).round()),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    const SizedBox(height: 8), 
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: TextStyle(
                          color: color.withAlpha((0.9 * 255).round()),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WeeklyTrendChart extends StatelessWidget {
  final List<dynamic> trendData;
  final String title;
  final Color color;
  final bool isPercentage;

  const WeeklyTrendChart({
    super.key,
    required this.trendData,
    required this.title,
    required this.color,
    this.isPercentage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.1 * 255).round()),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white24,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value < 0 || value >= trendData.length) return const SizedBox();
                        return Text(
                          trendData[value.toInt()]['day'],
                          style: const TextStyle(fontSize: 10, color: Colors.white70),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: trendData.asMap().entries.map((e) {
                      final val = isPercentage 
                          ? (e.value['percentage'] ?? 0).toDouble() 
                          : (e.value['amount'] ?? 0).toDouble();
                      return FlSpot(e.key.toDouble(), val);
                    }).toList(),
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: color,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: false, // In the reference dark theme, area is empty
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class AnalyticsQuickLinksRow extends ConsumerWidget {
  final Map<String, dynamic> data;

  const AnalyticsQuickLinksRow({super.key, required this.data});

  static List<QuickLinkItem> getQuickLinks(BuildContext context, WidgetRef ref, Map<String, dynamic> data) {
    final role = data['role']?.toString().toLowerCase() ?? '';
    final isAdmin = role == 'school_admin';
    final isTeacher = role == 'teacher';
    final isAcademic = isAdmin || isTeacher;

    final List<QuickLinkItem> quickLinks = [];

    // --- ACADEMIC / DAILY LINKS ---
    if (!isAdmin) {
      quickLinks.add(QuickLinkItem(icon: Icons.fingerprint, label: 'My Attend.', color: AppColors.iconFgNotices, onTap: () => context.go('/dashboard/self-attendance')));
    }
    if (isAcademic) {
      quickLinks.add(QuickLinkItem(icon: Icons.calendar_month_outlined, label: 'Attendance', color: AppColors.iconFgAttendance, onTap: () => context.go('/dashboard/attendance')));
      quickLinks.add(QuickLinkItem(icon: Icons.grading_outlined, label: 'Marks', color: AppColors.iconFgHomework, onTap: () => context.go('/dashboard/exam-marks')));
    }
    if (isAdmin) {
      quickLinks.add(QuickLinkItem(icon: Icons.how_to_reg_outlined, label: 'Staff Attend.', color: AppColors.accent, onTap: () => context.go('/dashboard/mark-staff-attendance')));
    } else if (isTeacher) {
      quickLinks.add(QuickLinkItem(icon: Icons.edit_document, label: 'Homework', color: AppColors.accent, onTap: () => context.go('/dashboard/homework')));
    }

    // --- MANAGEMENT LINKS ---
    if (isAcademic) {
      quickLinks.add(QuickLinkItem(icon: Icons.person_search, label: 'Students', color: AppColors.iconFgStudents, onTap: () => context.go('/dashboard/student-search')));
    }
    if (isAdmin) {
      quickLinks.add(QuickLinkItem(icon: Icons.badge_outlined, label: 'Staff List', color: AppColors.iconFgStaff, onTap: () => context.go('/dashboard/staff-list')));
    }
    
    // --- PERSONAL / HR LINKS ---
    if (isAdmin) {
      quickLinks.add(QuickLinkItem(icon: Icons.analytics_outlined, label: 'Logs', color: AppColors.iconFgChatbot, onTap: () => context.go('/staff-reports')));
    } else {
      quickLinks.add(QuickLinkItem(icon: Icons.analytics_outlined, label: 'My Logs', color: AppColors.iconFgChatbot, onTap: () => context.go('/staff-reports')));
      quickLinks.add(QuickLinkItem(icon: Icons.check_circle_outline, label: 'Leaves', color: AppColors.iconFgLeave, onTap: () => context.go('/dashboard/my-leave')));
    }
    if (isAdmin) {
      quickLinks.add(QuickLinkItem(icon: Icons.approval_outlined, label: 'Staff Leave', color: AppColors.accent, onTap: () => context.go('/dashboard/staff-leave-approval')));
    }
    quickLinks.add(QuickLinkItem(icon: Icons.person_outline, label: 'Profile', color: AppColors.iconFgProfile, onTap: () => context.go('/my-profile')));
    
    if (isTeacher) {
      quickLinks.add(QuickLinkItem(icon: Icons.schedule, label: 'Timetable', color: AppColors.iconFgTimetable, onTap: () => context.go('/my-timetable')));
    }
    if (isAdmin) {
      quickLinks.add(QuickLinkItem(icon: Icons.account_balance_wallet_outlined, label: 'Fees Due', color: AppColors.iconFgFees, onTap: () => context.go('/dashboard/fees-reports')));
    }

    // --- SYSTEM LINKS ---
    quickLinks.add(QuickLinkItem(icon: Icons.campaign_outlined, label: 'Notices', color: AppColors.iconFgComms, onTap: () => context.go('/notices')));
    quickLinks.add(QuickLinkItem(icon: Icons.logout, label: 'Logout', color: AppColors.error, onTap: () => ref.read(authControllerProvider.notifier).logout()));

    return quickLinks;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quickLinks = getQuickLinks(context, ref, data);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 4 items per row
          final itemWidth = constraints.maxWidth / 4;
          return Wrap(
            runSpacing: 20.0,
            alignment: WrapAlignment.start,
            children: quickLinks.map((link) {
              return SizedBox(
                width: itemWidth,
                child: link,
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class QuickLinkItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  const QuickLinkItem({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    Widget iconWidget = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha((0.12 * 255).round()),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 26),
    );

    if (badge != null && badge != '0' && badge!.isNotEmpty) {
      iconWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          iconWidget,
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                badge!,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class MenuSearchDelegate extends SearchDelegate<String> {
  final List<QuickLinkItem> allLinks;

  MenuSearchDelegate({required this.allLinks}) : super(searchFieldLabel: 'Search menus...');

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildList();

  @override
  Widget buildSuggestions(BuildContext context) => _buildList();

  Widget _buildList() {
    final results = allLinks
        .where((link) => link.label.toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (results.isEmpty) {
      return const Center(child: Text('No menus match your search.'));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / 4;
          return Wrap(
            runSpacing: 20.0,
            alignment: WrapAlignment.start,
            children: results.map((link) {
              return SizedBox(
                width: itemWidth,
                child: QuickLinkItem(
                  icon: link.icon,
                  label: link.label,
                  color: link.color,
                  badge: link.badge,
                  onTap: () {
                    close(context, link.label);
                    link.onTap();
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
