/// All known permission keys the backend can grant via Spatie.
///
/// Each enum value maps 1:1 to a Spatie permission string.
/// Adding a new backend permission? Add it here and it's immediately
/// available for `PermissionService.can()` checks with compile-time safety.
enum AppPermission {
  // ── Academics ──────────────────────────────────────────────
  academicsDashboardView('academics.dashboard.view'),
  studentView('student.view'),
  attendanceTake('attendance.take'),
  homeworkManage('homework.manage'),
  examMarksEntry('exam_marks.entry'),
  timetableView('timetable.view'),

  // ── HR / Administration ────────────────────────────────────
  hrLeaveApprove('hr.leave.approve'),
  hrStaffView('hr.staff.view'),
  hrStaffAttendanceMark('hr.staff_attendance.mark'),
  hrStaffAttendanceReport('hr.staff_attendance.report'),

  // ── Finance ────────────────────────────────────────────────
  feesViewReport('fees.view_report'),

  // ── Communication ──────────────────────────────────────────
  noticeView('notice.view'),
  noticeCreate('notice.create'),
  communicationLogView('communication.log.view'),

  // ── Profile ────────────────────────────────────────────────
  profileView('profile.view'),
  profilePhotoUpload('profile.photo_upload'),

  // ── System ────────────────────────────────────────────────
  systemAuditTrailView('system.audit_trail.view'),
  
  // ── Transport ─────────────────────────────────────────────
  transportManage('transport.manage'),

  // ── Front Office ─────────────────────────────────────────
  frontOfficeManage('frontoffice.dashboard.view'),

  // ── Inventory ────────────────────────────────────────────
  inventoryDashboardView('inventory.dashboard.view'),

  // ── Asset Management ─────────────────────────────────────
  assetDashboardView('asset.dashboard.view'),

  // ── Library Management ───────────────────────────────────
  libraryManage('library.manage'),

  // ── Hostel Management ────────────────────────────────────
  hostelManage('hostel.manage'),

  // ── CBC Academics ────────────────────────────────────────
  cbcManage('cbc.strand.manage'),

  // ── PTM Meetings ─────────────────────────────────────────
  ptmManage('ptm.meeting.manage'),
  ptmAttendanceManage('ptm.attendance.manage'),
  ptmRemarkManage('ptm.remark.manage'),

  // ── Lesson Planner ─────────────────────────────────────────
  lessonPlanManage('lesson_plan.dashboard.view'),

  // ── Knowledge Base ────────────────────────────────────────
  kbManage('knowledge_base.manage'),

  // ── Self-service (available to all staff) ──────────────────
  selfAttendanceView('self.attendance.view'),
  selfLeaveApply('self.leave.apply'),
  selfLeaveView('self.leave.view');

  /// The exact key string used in the backend Spatie permissions table.
  final String backendKey;

  const AppPermission(this.backendKey);

  /// Resolve a backend permission string to the enum value, or null if unknown.
  static AppPermission? fromBackendKey(String key) {
    for (final p in values) {
      if (p.backendKey == key) return p;
    }
    return null;
  }

  /// Batch-convert a list of backend permission strings to a set of enums.
  /// Unknown keys are silently skipped — this keeps the app forward-compatible
  /// when the backend adds permissions the current app version doesn't know about.
  static Set<AppPermission> fromBackendKeys(List<String> keys) {
    final result = <AppPermission>{};
    for (final key in keys) {
      final p = fromBackendKey(key);
      if (p != null) result.add(p);
    }
    return result;
  }
}
