import 'dart:typed_data';
import '../models/attendance.dart';
import '../models/employee.dart';
import '../models/org.dart';
import '../models/violation.dart';
import '../models/maintenance_team.dart';
import 'api_service.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String employeeNumber, String password) async {
    final result = await apiService.post('/auth/login', body: {
      'employee_number': employeeNumber,
      'password': password,
    });
    await apiService.setToken(result['access_token']);
    return result;
  }

  Future<void> logout() async {
    await apiService.clearToken();
  }

  Future<Profile> getProfile() async {
    final result = await apiService.get('/auth/me');
    return Profile.fromJson(result);
  }
}

class AttendanceService {
  Future<Map<String, dynamic>> checkIn({
    required double latitude,
    required double longitude,
    double? accuracy,
    String? deviceUuid,
    bool identityVerified = false,
    String identityMethod = 'pattern',
    String? identityHash,
  }) async {
    return await apiService.post('/attendance/check-in', body: {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'device_uuid': deviceUuid,
      'identity_verified': identityVerified,
      'identity_method': identityMethod,
      'identity_hash': identityHash,
    });
  }

  Future<Map<String, dynamic>> checkOut({
    required double latitude,
    required double longitude,
    double? accuracy,
  }) async {
    return await apiService.post('/attendance/check-out', body: {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
    });
  }

  Future<Map<String, dynamic>> getTodayAttendance() async {
    final result = await apiService.get('/attendance/today');
    return result;
  }

  Future<Map<String, dynamic>> setupPattern(String patternHash) async {
    return await apiService.post('/attendance/setup-pattern', body: {
      'pattern_hash': patternHash,
    });
  }

  Future<Map<String, dynamic>> verifyPattern(String patternHash) async {
    return await apiService.post('/attendance/verify-pattern', body: {
      'pattern_hash': patternHash,
    });
  }

  Future<Map<String, dynamic>> getIdentityStatus() async {
    return await apiService.get('/attendance/identity-status');
  }
}

class LeaveService {
  Future<Map<String, dynamic>> createLeave({
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
    String? leaveTypeCustom,
  }) async {
    final body = <String, dynamic>{
      'leave_type': leaveType,
      'start_date': '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
      'end_date': '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
    };
    if (reason != null) body['reason'] = reason;
    if (leaveTypeCustom != null) body['leave_type_custom'] = leaveTypeCustom;
    return await apiService.post('/leave/', body: body);
  }

  Future<List<LeaveRequest>> getMyLeaves() async {
    final result = await apiService.get('/leave/my');
    return (result['items'] as List)
        .map((e) => LeaveRequest.fromJson(e))
        .toList();
  }

  Future<List<LeaveRequest>> getAllLeaves({String? status, String? leaveType}) async {
    final params = <String>[];
    if (status != null) params.add('status=$status');
    if (leaveType != null) params.add('leave_type=$leaveType');
    final path = params.isEmpty ? '/leave/all' : '/leave/all?${params.join('&')}';
    final result = await apiService.get(path);
    return (result['items'] as List)
        .map((e) => LeaveRequest.fromJson(e))
        .toList();
  }

  Future<Map<String, dynamic>> reviewLeave(int requestId, String status, {String? note}) async {
    return await apiService.post('/leave/$requestId/review', body: {
      'status': status,
      'review_note': note,
    });
  }

  Future<Map<String, dynamic>> createShortLeave({
    required String leaveKind,
    required DateTime outingDate,
    required String departureTime,
    required String returnTime,
    String? destination,
    String? reason,
    bool trackingRequired = false,
    bool trackingAcknowledged = false,
  }) async {
    final body = <String, dynamic>{
      'leave_kind': leaveKind,
      'outing_date': '${outingDate.year}-${outingDate.month.toString().padLeft(2, '0')}-${outingDate.day.toString().padLeft(2, '0')}',
      'departure_time': departureTime,
      'return_time': returnTime,
      'tracking_required': trackingRequired,
      'tracking_acknowledged': trackingAcknowledged,
    };
    if (destination != null) body['destination'] = destination;
    if (reason != null) body['reason'] = reason;
    return await apiService.post('/leave/short', body: body);
  }

  Future<List<ShortLeaveRequest>> getMyShortLeaves() async {
    final result = await apiService.get('/leave/short/my');
    return (result['items'] as List)
        .map((e) => ShortLeaveRequest.fromJson(e))
        .toList();
  }

  Future<List<ShortLeaveRequest>> getAllShortLeaves({String? status, String? kind}) async {
    final params = <String>[];
    if (status != null) params.add('status=$status');
    if (kind != null) params.add('kind=$kind');
    final path = params.isEmpty ? '/leave/short/all' : '/leave/short/all?${params.join('&')}';
    final result = await apiService.get(path);
    return (result['items'] as List)
        .map((e) => ShortLeaveRequest.fromJson(e))
        .toList();
  }

  Future<Map<String, dynamic>> reviewShortLeave(int shortLeaveId, String status, {String? note}) async {
    return await apiService.post('/leave/short/$shortLeaveId/review', body: {
      'status': status,
      'review_note': note,
    });
  }
}

class OvertimeService {
  Future<Map<String, dynamic>> createRequest({
    required String taskDescription,
    required String areaName,
    required double areaLat,
    required double areaLng,
    required double requestedHours,
    String? workDate,
    String workType = 'field',
  }) async {
    return await apiService.post('/overtime-work/', body: {
      'task_description': taskDescription,
      'area_name': areaName,
      'area_lat': areaLat,
      'area_lng': areaLng,
      'requested_hours': requestedHours,
      'work_date': workDate,
      'work_type': workType,
    });
  }

  Future<List<OvertimeRequest>> getMyRequests() async {
    final result = await apiService.get('/overtime-work/my');
    return (result['items'] as List)
        .map((e) => OvertimeRequest.fromJson(e))
        .toList();
  }

  Future<List<OvertimeRequest>> getAllRequests({String? status}) async {
    final path = status != null ? '/overtime-work/all?status=$status' : '/overtime-work/all';
    final result = await apiService.get(path);
    return (result['items'] as List)
        .map((e) => OvertimeRequest.fromJson(e))
        .toList();
  }

  Future<Map<String, dynamic>> reviewRequest(int requestId, String status, {double? hours, String? note}) async {
    return await apiService.post('/overtime-work/$requestId/review', body: {
      'status': status,
      'total_approved_hours': hours,
      'review_note': note,
    });
  }

  Future<Map<String, dynamic>> extendRequest(int requestId, double additionalHours, {String? note}) async {
    return await apiService.post('/overtime-work/$requestId/extend', body: {
      'additional_hours': additionalHours,
      'review_note': note,
    });
  }

  Future<Map<String, dynamic>> completeRequest(int requestId, String workDone,
      {double? actualHours, double? actualLat, double? actualLng, String? photoUrl}) async {
    return await apiService.post('/overtime-work/$requestId/complete', body: {
      'work_done': workDone,
      'actual_hours': actualHours,
      'actual_lat': actualLat,
      'actual_lng': actualLng,
      'photo_url': photoUrl,
    });
  }

  Future<Map<String, dynamic>> submitReport(int requestId, String workDone,
      {double? actualHours, double? actualLat, double? actualLng, String? photoUrl}) async {
    return await apiService.post('/overtime-work/$requestId/report', body: {
      'work_done': workDone,
      'actual_hours': actualHours,
      'actual_lat': actualLat,
      'actual_lng': actualLng,
      'photo_url': photoUrl,
    });
  }

  Future<List<OvertimeReport>> getReports(int requestId) async {
    final result = await apiService.get('/overtime-work/$requestId/reports');
    return (result['items'] as List)
        .map((e) => OvertimeReport.fromJson(e))
        .toList();
  }

  Future<Map<String, dynamic>> getPrintData(int requestId) async {
    return await apiService.get('/overtime-work/$requestId/print');
  }
}

class ReportService {
  Future<DailyReport> getDailyReport({String? date}) async {
    final path = date != null ? '/reports/daily?date=$date' : '/reports/daily';
    final result = await apiService.get(path);
    return DailyReport.fromJson(result);
  }

  Future<Map<String, dynamic>> createDailyReport({
    required String title,
    required String description,
    String reportType = 'daily',
  }) async {
    return await apiService.post('/reports/', body: {
      'report_type': reportType,
      'title': title,
      'description': description,
    });
  }

  Future<List<ReportInboxItem>> getInbox(
      {String? status, String? date, String? employeeNumber}) async {
    final params = <String>[];
    if (status != null) params.add('status=$status');
    if (date != null) params.add('date=$date');
    if (employeeNumber != null) params.add('employee_number=$employeeNumber');
    final path = params.isEmpty ? '/reports/inbox' : '/reports/inbox?${params.join('&')}';
    final result = await apiService.get(path);
    return (result['items'] as List)
        .map((e) => ReportInboxItem.fromJson(e))
        .toList();
  }

  Future<Map<String, dynamic>> getAdminAttendanceReport({
    String? startDate,
    String? endDate,
    int? employeeId,
  }) async {
    final params = <String>[];
    if (startDate != null) params.add('start_date=$startDate');
    if (endDate != null) params.add('end_date=$endDate');
    if (employeeId != null) params.add('employee_id=$employeeId');
    final path = params.isEmpty ? '/reports-extended/admin/attendance' : '/reports-extended/admin/attendance?${params.join('&')}';
    return await apiService.get(path);
  }

  Future<Map<String, dynamic>> getAdminLeaveReport({
    int? year,
    int? employeeId,
  }) async {
    final params = <String>[];
    if (year != null) params.add('year=$year');
    if (employeeId != null) params.add('employee_id=$employeeId');
    final path = params.isEmpty ? '/reports-extended/admin/leave' : '/reports-extended/admin/leave?${params.join('&')}';
    return await apiService.get(path);
  }

  Future<Map<String, dynamic>> getAdminOvertimeReport({
    String? startDate,
    String? endDate,
    int? employeeId,
  }) async {
    final params = <String>[];
    if (startDate != null) params.add('start_date=$startDate');
    if (endDate != null) params.add('end_date=$endDate');
    if (employeeId != null) params.add('employee_id=$employeeId');
    final path = params.isEmpty ? '/reports-extended/admin/overtime' : '/reports-extended/admin/overtime?${params.join('&')}';
    return await apiService.get(path);
  }

  Future<Map<String, dynamic>> getAdminViolationsReport({
    String? startDate,
    String? endDate,
    int? employeeId,
  }) async {
    final params = <String>[];
    if (startDate != null) params.add('start_date=$startDate');
    if (endDate != null) params.add('end_date=$endDate');
    if (employeeId != null) params.add('employee_id=$employeeId');
    final path = params.isEmpty ? '/reports-extended/admin/violations' : '/reports-extended/admin/violations?${params.join('&')}';
    return await apiService.get(path);
  }

  Future<Map<String, dynamic>> getDashboardReport() async {
    return await apiService.get('/reports-extended/dashboard');
  }
}

class ViolationService {
  Future<Map<String, dynamic>> createViolation({
    required int employeeId,
    required String violationType,
    required String violationDate,
    required String violationTime,
    required String penalty,
    String? notes,
  }) async {
    return await apiService.post('/violations/', body: {
      'employee_id': employeeId,
      'violation_type': violationType,
      'violation_date': violationDate,
      'violation_time': violationTime,
      'penalty': penalty,
      if (notes != null) 'notes': notes,
    });
  }

  Future<List<Violation>> getMyViolations() async {
    final result = await apiService.get('/violations/me');
    return (result['items'] as List).map((e) => Violation.fromJson(e)).toList();
  }

  Future<List<Violation>> getAll({String? status, int? employeeId}) async {
    final params = <String>[];
    if (status != null) params.add('status=$status');
    if (employeeId != null) params.add('employee_id=$employeeId');
    final path = params.isEmpty ? '/violations/' : '/violations/?${params.join('&')}';
    final result = await apiService.get(path);
    return (result['items'] as List).map((e) => Violation.fromJson(e)).toList();
  }

  Future<List<Violation>> getTeamViolations({String? status}) async {
    final path = status != null ? '/violations/team?status=$status' : '/violations/team';
    final result = await apiService.get(path);
    return (result['items'] as List).map((e) => Violation.fromJson(e)).toList();
  }

  Future<List<Violation>> getPendingReview() async {
    final result = await apiService.get('/violations/pending-review');
    return (result['items'] as List).map((e) => Violation.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getStats({String? startDate, String? endDate}) async {
    final params = <String>[];
    if (startDate != null) params.add('start_date=$startDate');
    if (endDate != null) params.add('end_date=$endDate');
    final path = params.isEmpty ? '/violations/stats' : '/violations/stats?${params.join('&')}';
    return await apiService.get(path);
  }

  Future<Violation> acknowledge(int violationId) async {
    final result = await apiService.post('/violations/$violationId/acknowledge');
    return Violation.fromJson(result);
  }

  Future<Violation> respond(int violationId, String response) async {
    final result = await apiService.post('/violations/$violationId/respond', body: {
      'response': response,
    });
    return Violation.fromJson(result);
  }

  Future<Violation> hrReview(int violationId, {required String hrNotes, String status = 'reviewed'}) async {
    final result = await apiService.post('/violations/$violationId/hr-review', body: {
      'hr_notes': hrNotes,
      'status': status,
    });
    return Violation.fromJson(result);
  }

  Future<Violation> getViolation(int violationId) async {
    final result = await apiService.get('/violations/$violationId');
    return Violation.fromJson(result);
  }
}

class MaintenanceService {
  Future<Map<String, dynamic>> createComplaint({
    required String description,
    String priority = 'NORMAL',
    double? latitude,
    double? longitude,
  }) async {
    return await apiService.post('/maintenance/complaints', body: {
      'description': description,
      'priority': priority,
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  Future<List<dynamic>> getComplaints({String? status}) async {
    final path = status != null ? '/maintenance/complaints?status=$status' : '/maintenance/complaints';
    final result = await apiService.get(path);
    return result['items'];
  }
}

class GpsService {
  Future<Map<String, dynamic>> startTracking({
    required int targetEmployeeId,
    required String mode,
    required int interval,
    String type = 'FIELD_WORK',
    String? trackColor,
  }) async {
    return await apiService.post('/gps/start', body: {
      'target_employee_id': targetEmployeeId,
      'mode': mode,
      'interval': interval,
      'tracking_type': type,
      'track_color': trackColor,
    });
  }

  Future<Map<String, dynamic>> stopTracking({int? sessionId}) async {
    return await apiService.post(
        '/gps/stop', body: sessionId != null ? {'session_id': sessionId} : {});
  }

  Future<Map<String, dynamic>> addPoint({
    required int sessionId,
    required double latitude,
    required double longitude,
    double? accuracy,
    int? batteryLevel,
  }) async {
    return await apiService.post('/gps/point', body: {
      'session_id': sessionId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'battery_level': batteryLevel,
    });
  }

  Future<Map<String, dynamic>> myActive() async {
    return await apiService.get('/gps/my-active');
  }

  Future<Map<String, dynamic>> getView() async {
    return await apiService.get('/gps/view');
  }

  Future<Map<String, dynamic>> getHistory(int employeeId) async {
    return await apiService.get('/gps/history?employee_id=$employeeId');
  }

  Future<Map<String, dynamic>> getEmployees() async {
    return await apiService.get('/gps/employees');
  }

  Future<Map<String, dynamic>> getViewer() async {
    return await apiService.get('/gps/viewer');
  }

  Future<Map<String, dynamic>> setViewer(int employeeId) async {
    return await apiService.post('/gps/set-viewer', body: {'employee_id': employeeId});
  }

  Future<Map<String, dynamic>> getBreaches({int? employeeId}) async {
    final q = employeeId != null ? '?employee_id=$employeeId' : '';
    return await apiService.get('/gps/breaches$q');
  }

  Future<Map<String, dynamic>> simulatePoint({
    required int sessionId,
    required double latitude,
    required double longitude,
  }) async {
    return await apiService.post('/gps/simulate-point', body: {
      'session_id': sessionId,
      'latitude': latitude,
      'longitude': longitude,
    });
  }
}

class OrgService {
  Future<List<dynamic>> getOrgTree() async {
    final result = await apiService.get('/organization/tree');
    return result['tree'];
  }

  Future<List<OrgUnit>> getOrgUnits() async {
    final result = await apiService.get('/organization/units');
    return (result['items'] as List)
        .map((e) => OrgUnit.fromJson(e))
        .toList();
  }

  Future<Map<String, dynamic>> createUnit(Map<String, dynamic> body) async {
    return await apiService.post('/organization/units', body: body);
  }

  Future<Map<String, dynamic>> updateUnit(int id, Map<String, dynamic> body) async {
    return await apiService.patch('/organization/units/$id', body: body);
  }

  Future<Map<String, dynamic>> deleteUnit(int id) async {
    return await apiService.delete('/organization/units/$id');
  }
}

class EmployeeService {
  Future<List<Employee>> listEmployees() async {
    final result = await apiService.get('/employees/all');
    return (result['items'] as List)
        .map((e) => Employee.fromJson(e))
        .toList();
  }

  Future<Employee> getMyEmployee() async {
    final result = await apiService.get('/employees/me');
    return Employee.fromJson(result);
  }

  Future<Employee> getEmployee(int id) async {
    final result = await apiService.get('/employees/$id');
    return Employee.fromJson(result);
  }

  Future<Map<String, dynamic>> createEmployee(Map<String, dynamic> body) async {
    return await apiService.post('/employees/', body: body);
  }

  Future<Map<String, dynamic>> updateEmployee(int id, Map<String, dynamic> body) async {
    return await apiService.patch('/employees/$id', body: body);
  }

  Future<Map<String, dynamic>> deleteEmployee(int id) async {
    return await apiService.delete('/employees/$id');
  }

  Future<Map<String, dynamic>> hardDeleteEmployee(int id) async {
    return await apiService.delete('/employees/$id/hard');
  }

  Future<List<RoleItem>> listRoles() async {
    final result = await apiService.get('/employees/roles');
    return (result['items'] as List)
        .map((e) => RoleItem.fromJson(e))
        .toList();
  }

  Future<List<WorkTypeItem>> listWorkTypes() async {
    final result = await apiService.get('/employees/work-types');
    return (result['items'] as List)
        .map((e) => WorkTypeItem.fromJson(e))
        .toList();
  }

  Future<Map<String, dynamic>> bulkImport(String filePath) async {
    return await apiService.uploadFile('/employees/bulk-import', filePath);
  }

  Future<List<int>> downloadTemplateBytes({bool dynamic = false}) async {
    final path = dynamic ? '/employees/template-dynamic' : '/employees/template';
    final response = await apiService.downloadFile(path);
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to download template (${response.statusCode})');
    }
  }
}

class ReportExtendedService {
  /// Attendance report (returns JSON map)
  Future<Map<String, dynamic>> getAttendanceReport({
    String? from,
    String? to,
    int? employeeId,
    String format = 'json',
  }) async {
    final params = <String>[];
    if (from != null) params.add('from=$from');
    if (to != null) params.add('to=$to');
    if (employeeId != null) params.add('employee_id=$employeeId');
    params.add('format=$format');
    final path = '/reports-extended/attendance?${params.join('&')}';
    return await apiService.get(path);
  }

  /// Leave report
  Future<Map<String, dynamic>> getLeaveReport({
    String? from,
    String? to,
    String? status,
    int? employeeId,
    String format = 'json',
  }) async {
    final params = <String>[];
    if (from != null) params.add('from=$from');
    if (to != null) params.add('to=$to');
    if (status != null) params.add('status=$status');
    if (employeeId != null) params.add('employee_id=$employeeId');
    params.add('format=$format');
    final path = '/reports-extended/leave?${params.join('&')}';
    return await apiService.get(path);
  }

  /// Overtime report
  Future<Map<String, dynamic>> getOvertimeReport({
    String? from,
    String? to,
    String? status,
    int? employeeId,
    String format = 'json',
  }) async {
    final params = <String>[];
    if (from != null) params.add('from=$from');
    if (to != null) params.add('to=$to');
    if (status != null) params.add('status=$status');
    if (employeeId != null) params.add('employee_id=$employeeId');
    params.add('format=$format');
    final path = '/reports-extended/overtime?${params.join('&')}';
    return await apiService.get(path);
  }

  /// Violations report
  Future<Map<String, dynamic>> getViolationsReport({
    String? from,
    String? to,
    String? penalty,
    int? employeeId,
    String format = 'json',
  }) async {
    final params = <String>[];
    if (from != null) params.add('from=$from');
    if (to != null) params.add('to=$to');
    if (penalty != null) params.add('penalty=$penalty');
    if (employeeId != null) params.add('employee_id=$employeeId');
    params.add('format=$format');
    final path = '/reports-extended/violations?${params.join('&')}';
    return await apiService.get(path);
  }

  /// Audit log report
  Future<Map<String, dynamic>> getAuditReport({
    String? from,
    String? to,
    int? employeeId,
    String? action,
    String format = 'json',
  }) async {
    final params = <String>[];
    if (from != null) params.add('from=$from');
    if (to != null) params.add('to=$to');
    if (employeeId != null) params.add('employee_id=$employeeId');
    if (action != null) params.add('action=$action');
    params.add('format=$format');
    final path = '/reports-extended/audit?${params.join('&')}';
    return await apiService.get(path);
  }

  /// Dashboard KPI summary
  Future<Map<String, dynamic>> getDashboardReport({int? orgUnitId, String? from, String? to}) async {
    final params = <String>[];
    if (orgUnitId != null) params.add('org_unit_id=$orgUnitId');
    if (from != null) params.add('from=$from');
    if (to != null) params.add('to=$to');
    final path = params.isEmpty
        ? '/reports-extended/dashboard'
        : '/reports-extended/dashboard?${params.join('&')}';
    return await apiService.get(path);
  }

  /// Full employee profile
  Future<Map<String, dynamic>> getFullProfile(int employeeId, {String format = 'json'}) async {
    return await apiService.get('/reports-extended/full-profile/$employeeId?format=$format');
  }
}

class NotificationService {
  Future<List<dynamic>> getNotifications({bool? isRead}) async {
    final path = isRead != null ? '/notifications/?is_read=$isRead' : '/notifications/';
    final result = await apiService.get(path);
    return result['items'];
  }

  Future<void> markRead(int notificationId) async {
    await apiService.post('/notifications/$notificationId/read');
  }

  Future<void> markAllRead() async {
    await apiService.post('/notifications/read-all');
  }
}

class TeamService {
  Future<List<MaintenanceTeam>> getTeams({String? teamType, String? governorate}) async {
    final params = <String>[];
    if (teamType != null) params.add('team_type=$teamType');
    if (governorate != null) params.add('governorate=$governorate');
    final path = params.isEmpty ? '/maintenance/teams' : '/maintenance/teams?${params.join('&')}';
    final result = await apiService.get(path);
    return (result['items'] as List).map((e) => MaintenanceTeam.fromJson(e)).toList();
  }

  Future<MaintenanceTeam> getTeam(int teamId) async {
    final result = await apiService.get('/maintenance/teams/$teamId');
    return MaintenanceTeam.fromJson(result);
  }

  Future<MaintenanceTeam> createTeam({
    required String teamName,
    required String teamType,
    required String governorate,
    int? teamLeaderId,
    int maxActiveTasks = 5,
  }) async {
    final result = await apiService.post('/maintenance/teams', body: {
      'team_name': teamName,
      'team_type': teamType,
      'governorate': governorate,
      if (teamLeaderId != null) 'team_leader_id': teamLeaderId,
      'max_active_tasks': maxActiveTasks,
    });
    return MaintenanceTeam.fromJson(result);
  }

  Future<MaintenanceTeam> updateTeam(int teamId, {String? teamName, String? teamType, String? governorate, int? teamLeaderId, int? maxActiveTasks, bool? isActive}) async {
    final result = await apiService.put('/maintenance/teams/$teamId', body: {
      if (teamName != null) 'team_name': teamName,
      if (teamType != null) 'team_type': teamType,
      if (governorate != null) 'governorate': governorate,
      if (teamLeaderId != null) 'team_leader_id': teamLeaderId,
      if (maxActiveTasks != null) 'max_active_tasks': maxActiveTasks,
      if (isActive != null) 'is_active': isActive,
    });
    return MaintenanceTeam.fromJson(result);
  }

  Future<void> addMember(int teamId, int employeeId, {String role = 'technician'}) async {
    await apiService.post('/maintenance/teams/$teamId/members', body: {
      'employee_id': employeeId,
      'role': role,
    });
  }

  Future<void> removeMember(int teamId, int memberId) async {
    await apiService.delete('/maintenance/teams/$teamId/members/$memberId');
  }
}

class TeamComplaintService {
  Future<List<MaintenanceComplaint>> getComplaints({
    String? status,
    String? category,
    String? priority,
    int? teamId,
    String? governorate,
  }) async {
    final params = <String>[];
    if (status != null) params.add('status=$status');
    if (category != null) params.add('category=$category');
    if (priority != null) params.add('priority=$priority');
    if (teamId != null) params.add('team_id=$teamId');
    if (governorate != null) params.add('governorate=$governorate');
    final path = params.isEmpty ? '/maintenance/complaints' : '/maintenance/complaints?${params.join('&')}';
    final result = await apiService.get(path);
    return (result['items'] as List).map((e) => MaintenanceComplaint.fromJson(e)).toList();
  }

  Future<List<MaintenanceComplaint>> getMyTeamComplaints({String? status}) async {
    final path = status != null ? '/maintenance/complaints/my-team?status=$status' : '/maintenance/complaints/my-team';
    final result = await apiService.get(path);
    return (result['items'] as List).map((e) => MaintenanceComplaint.fromJson(e)).toList();
  }

  Future<MaintenanceComplaint> createComplaint({
    String? customerName,
    String? customerPhone,
    required String description,
    required String category,
    required String priority,
    required String governorate,
    String? district,
    String? neighborhood,
    double? latitude,
    double? longitude,
  }) async {
    final result = await apiService.post('/maintenance/complaints', body: {
      if (customerName != null) 'customer_name': customerName,
      if (customerPhone != null) 'customer_phone': customerPhone,
      'description': description,
      'category': category,
      'priority': priority,
      'governorate': governorate,
      if (district != null) 'district': district,
      if (neighborhood != null) 'neighborhood': neighborhood,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
    return MaintenanceComplaint.fromJson(result);
  }

  Future<MaintenanceComplaint> getComplaint(int complaintId) async {
    final result = await apiService.get('/maintenance/complaints/$complaintId');
    return MaintenanceComplaint.fromJson(result);
  }

  Future<MaintenanceComplaint> assignComplaint(int complaintId, int teamId, {int? assignedTo}) async {
    final result = await apiService.post('/maintenance/complaints/$complaintId/assign', body: {
      'team_id': teamId,
      if (assignedTo != null) 'assigned_to': assignedTo,
    });
    return MaintenanceComplaint.fromJson(result);
  }

  Future<MaintenanceComplaint> updateComplaint(int complaintId, {
    String? status,
    String? priority,
    String? resolutionNotes,
    int? customerSatisfaction,
  }) async {
    final result = await apiService.post('/maintenance/complaints/$complaintId/update', body: {
      if (status != null) 'status': status,
      if (priority != null) 'priority': priority,
      if (resolutionNotes != null) 'resolution_notes': resolutionNotes,
      if (customerSatisfaction != null) 'customer_satisfaction': customerSatisfaction,
    });
    return MaintenanceComplaint.fromJson(result);
  }

  Future<Map<String, dynamic>> getStats({String? governorate}) async {
    final path = governorate != null ? '/maintenance/stats?governorate=$governorate' : '/maintenance/stats';
    return await apiService.get(path);
  }
}

class PeriodicMaintenanceService {
  Future<List<PeriodicTask>> getTasks({int? teamId}) async {
    final path = teamId != null ? '/periodic-maintenance/tasks?team_id=$teamId' : '/periodic-maintenance/tasks';
    final result = await apiService.get(path);
    return (result['items'] as List).map((e) => PeriodicTask.fromJson(e)).toList();
  }

  Future<List<PeriodicTask>> getMyTeamTasks() async {
    final result = await apiService.get('/periodic-maintenance/tasks/my-team');
    return (result['items'] as List).map((e) => PeriodicTask.fromJson(e)).toList();
  }

  Future<List<PeriodicTask>> getUpcomingTasks({int days = 7}) async {
    final result = await apiService.get('/periodic-maintenance/tasks/upcoming?days=$days');
    return (result['items'] as List).map((e) => PeriodicTask.fromJson(e)).toList();
  }

  Future<PeriodicTask> getTask(int taskId) async {
    final result = await apiService.get('/periodic-maintenance/tasks/$taskId');
    return PeriodicTask.fromJson(result);
  }

  Future<PeriodicTask> createTask({
    required int teamId,
    required String taskName,
    String? description,
    required String frequency,
    int? dayOfWeek,
    int? dayOfMonth,
    String timeOfDay = '08:00',
  }) async {
    final result = await apiService.post('/periodic-maintenance/tasks', body: {
      'team_id': teamId,
      'task_name': taskName,
      if (description != null) 'description': description,
      'frequency': frequency,
      if (dayOfWeek != null) 'day_of_week': dayOfWeek,
      if (dayOfMonth != null) 'day_of_month': dayOfMonth,
      'time_of_day': timeOfDay,
    });
    return PeriodicTask.fromJson(result);
  }

  Future<PeriodicTask> updateTask(int taskId, {
    String? taskName,
    String? description,
    String? frequency,
    int? dayOfWeek,
    int? dayOfMonth,
    String? timeOfDay,
    bool? isActive,
  }) async {
    final result = await apiService.put('/periodic-maintenance/tasks/$taskId', body: {
      if (taskName != null) 'task_name': taskName,
      if (description != null) 'description': description,
      if (frequency != null) 'frequency': frequency,
      if (dayOfWeek != null) 'day_of_week': dayOfWeek,
      if (dayOfMonth != null) 'day_of_month': dayOfMonth,
      if (timeOfDay != null) 'time_of_day': timeOfDay,
      if (isActive != null) 'is_active': isActive,
    });
    return PeriodicTask.fromJson(result);
  }

  Future<PeriodicTaskCompletion> completeTask(int taskId, {String? notes}) async {
    final result = await apiService.post('/periodic-maintenance/tasks/$taskId/complete', body: {
      if (notes != null) 'notes': notes,
    });
    return PeriodicTaskCompletion.fromJson(result);
  }

  Future<List<PeriodicTaskCompletion>> getTaskCompletions(int taskId) async {
    final result = await apiService.get('/periodic-maintenance/tasks/$taskId/completions');
    return (result['items'] as List).map((e) => PeriodicTaskCompletion.fromJson(e)).toList();
  }
}

class AdminService {
  Future<Map<String, dynamic>> resetPassword(int employeeId, String newPassword) async {
    return await apiService.post('/security/admin/reset-password', body: {
      'employee_id': employeeId,
      'new_password': newPassword,
    });
  }
}
