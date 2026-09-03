class AttendanceRecord {
  final int attendanceId;
  final String? checkInTime;
  final String? checkOutTime;
  final double? workDurationHours;
  final String status;
  final bool identityVerified;

  AttendanceRecord({
    required this.attendanceId,
    this.checkInTime,
    this.checkOutTime,
    this.workDurationHours,
    required this.status,
    required this.identityVerified,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      attendanceId: json['attendance_id'],
      checkInTime: json['check_in_time'],
      checkOutTime: json['check_out_time'],
      workDurationHours: json['work_duration_hours']?.toDouble(),
      status: json['status'],
      identityVerified: json['identity_verified'] ?? false,
    );
  }
}

class LeaveRequest {
  final int requestId;
  final int employeeId;
  final String? employeeNumber;
  final String? employeeName;
  final String leaveType;
  final String? leaveTypeCustom;
  final String? leaveTypeLabel;
  final String startDate;
  final String startDay;
  final String endDate;
  final String endDay;
  final String? reason;
  final String status;
  final String? reviewNote;
  final String createdAt;

  LeaveRequest({
    required this.requestId,
    this.employeeId = 0,
    this.employeeNumber,
    this.employeeName,
    required this.leaveType,
    this.leaveTypeCustom,
    this.leaveTypeLabel,
    required this.startDate,
    required this.startDay,
    required this.endDate,
    required this.endDay,
    this.reason,
    required this.status,
    this.reviewNote,
    required this.createdAt,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      requestId: json['request_id'],
      employeeId: json['employee_id'] ?? 0,
      employeeNumber: json['employee_number'],
      employeeName: json['employee_name'],
      leaveType: json['leave_type'],
      leaveTypeCustom: json['leave_type_custom'],
      leaveTypeLabel: json['leave_type_label'],
      startDate: json['start_date'] ?? '',
      startDay: json['start_day'] ?? '',
      endDate: json['end_date'] ?? '',
      endDay: json['end_day'] ?? '',
      reason: json['reason'],
      status: json['status'],
      reviewNote: json['review_note'],
      createdAt: json['created_at'],
    );
  }
}

class ShortLeaveRequest {
  final int shortLeaveId;
  final int employeeId;
  final String? employeeNumber;
  final String? employeeName;
  final String leaveKind;
  final String? leaveKindLabel;
  final String outingDate;
  final String outingDay;
  final String departureTime;
  final String returnTime;
  final String? destination;
  final String? reason;
  final bool trackingRequired;
  final int? trackingSessionId;
  final bool trackingAcknowledged;
  final String status;
  final String? reviewNote;
  final String createdAt;

  ShortLeaveRequest({
    required this.shortLeaveId,
    this.employeeId = 0,
    this.employeeNumber,
    this.employeeName,
    required this.leaveKind,
    this.leaveKindLabel,
    required this.outingDate,
    required this.outingDay,
    required this.departureTime,
    required this.returnTime,
    this.destination,
    this.reason,
    required this.trackingRequired,
    this.trackingSessionId,
    required this.trackingAcknowledged,
    required this.status,
    this.reviewNote,
    required this.createdAt,
  });

  factory ShortLeaveRequest.fromJson(Map<String, dynamic> json) {
    return ShortLeaveRequest(
      shortLeaveId: json['short_leave_id'],
      employeeId: json['employee_id'] ?? 0,
      employeeNumber: json['employee_number'],
      employeeName: json['employee_name'],
      leaveKind: json['leave_kind'],
      leaveKindLabel: json['leave_kind_label'],
      outingDate: json['outing_date'] ?? '',
      outingDay: json['outing_day'] ?? '',
      departureTime: json['departure_time'] ?? '',
      returnTime: json['return_time'] ?? '',
      destination: json['destination'],
      reason: json['reason'],
      trackingRequired: json['tracking_required'] ?? false,
      trackingSessionId: json['tracking_session_id'],
      trackingAcknowledged: json['tracking_acknowledged'] ?? false,
      status: json['status'],
      reviewNote: json['review_note'],
      createdAt: json['created_at'],
    );
  }
}

class OvertimeRequest {
  final int requestId;
  final int employeeId;
  final String? employeeNumber;
  final String? employeeName;
  final String? workDate;
  final String? workType;
  final String taskDescription;
  final String areaName;
  final double areaLat;
  final double areaLng;
  final double requestedHours;
  final double totalApprovedHours;
  final double extendedHours;
  final double? actualHours;
  final String status;
  final int? trackingSessionId;
  final String? trackingStartsAt;
  final String? trackingEndsAt;
  final String? completedAt;
  final double? completedLat;
  final double? completedLng;
  final String? completedPhotoUrl;
  final String? reviewNote;
  final String? createdAt;

  OvertimeRequest({
    required this.requestId,
    this.employeeId = 0,
    this.employeeNumber,
    this.employeeName,
    this.workDate,
    this.workType,
    required this.taskDescription,
    required this.areaName,
    this.areaLat = 0,
    this.areaLng = 0,
    required this.requestedHours,
    this.totalApprovedHours = 0,
    this.extendedHours = 0,
    this.actualHours,
    required this.status,
    this.trackingSessionId,
    this.trackingStartsAt,
    this.trackingEndsAt,
    this.completedAt,
    this.completedLat,
    this.completedLng,
    this.completedPhotoUrl,
    this.reviewNote,
    this.createdAt,
  });

  factory OvertimeRequest.fromJson(Map<String, dynamic> json) {
    return OvertimeRequest(
      requestId: json['request_id'],
      employeeId: json['employee_id'] ?? 0,
      employeeNumber: json['employee_number'],
      employeeName: json['employee_name'],
      workDate: json['work_date'],
      workType: json['work_type'],
      taskDescription: json['task_description'],
      areaName: json['area_name'],
      areaLat: (json['area_lat'] ?? 0).toDouble(),
      areaLng: (json['area_lng'] ?? 0).toDouble(),
      requestedHours: (json['requested_hours'] ?? 0).toDouble(),
      totalApprovedHours: (json['total_approved_hours'] ?? 0).toDouble(),
      extendedHours: (json['extended_hours'] ?? 0).toDouble(),
      actualHours: json['actual_hours']?.toDouble(),
      status: json['status'],
      trackingSessionId: json['tracking_session_id'],
      trackingStartsAt: json['tracking_starts_at'],
      trackingEndsAt: json['tracking_ends_at'],
      completedAt: json['completed_at'],
      completedLat: json['completed_lat']?.toDouble(),
      completedLng: json['completed_lng']?.toDouble(),
      completedPhotoUrl: json['completed_photo_url'],
      reviewNote: json['review_note'],
      createdAt: json['created_at'],
    );
  }
}

class OvertimeReport {
  final int reportId;
  final String workDone;
  final double? actualHours;
  final double? actualLat;
  final double? actualLng;
  final String? photoUrl;
  final String submittedAt;

  OvertimeReport({
    required this.reportId,
    required this.workDone,
    this.actualHours,
    this.actualLat,
    this.actualLng,
    this.photoUrl,
    required this.submittedAt,
  });

  factory OvertimeReport.fromJson(Map<String, dynamic> json) {
    return OvertimeReport(
      reportId: json['report_id'],
      workDone: json['work_done'],
      actualHours: json['actual_hours']?.toDouble(),
      actualLat: json['actual_lat']?.toDouble(),
      actualLng: json['actual_lng']?.toDouble(),
      photoUrl: json['photo_url'],
      submittedAt: json['submitted_at'],
    );
  }
}

class DailyReport {
  final String date;
  final Map<String, dynamic> employee;
  final Map<String, dynamic> attendance;
  final List<dynamic> overtimeItems;
  final Map<String, dynamic> signatures;

  DailyReport({
    required this.date,
    required this.employee,
    required this.attendance,
    required this.overtimeItems,
    required this.signatures,
  });

  factory DailyReport.fromJson(Map<String, dynamic> json) {
    return DailyReport(
      date: json['date'],
      employee: json['employee'],
      attendance: json['attendance'],
      overtimeItems: json['overtime_items'] ?? [],
      signatures: json['signatures'] ?? {},
    );
  }
}

class ReportInboxItem {
  final int reportId;
  final String reportType;
  final String title;
  final String? description;
  final String? reportDate;
  final String status;
  final String authorName;
  final String authorNumber;
  final String createdAt;

  ReportInboxItem({
    required this.reportId,
    required this.reportType,
    required this.title,
    this.description,
    this.reportDate,
    required this.status,
    required this.authorName,
    required this.authorNumber,
    required this.createdAt,
  });

  factory ReportInboxItem.fromJson(Map<String, dynamic> json) {
    return ReportInboxItem(
      reportId: json['report_id'],
      reportType: json['report_type'],
      title: json['title'],
      description: json['description'],
      reportDate: json['report_date'],
      status: json['status'],
      authorName: json['author_name'],
      authorNumber: json['author_number'],
      createdAt: json['created_at'],
    );
  }
}
