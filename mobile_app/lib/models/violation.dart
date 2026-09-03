class Violation {
  final int violationId;
  final int? issuerId;
  final String? issuerName;
  final int employeeId;
  final String? employeeName;
  final String violationType;
  final String violationDate;
  final String violationTime;
  final String penalty;
  final String penaltyLabel;
  final String? notes;
  final String status;
  final String statusLabel;
  final bool acknowledged;
  final String? acknowledgedAt;
  final String? employeeResponse;
  final String? employeeResponseAt;
  final bool hrReviewed;
  final String? hrReviewedAt;
  final int? hrReviewerId;
  final String? hrNotes;
  final String createdAt;

  Violation({
    required this.violationId,
    this.issuerId,
    this.issuerName,
    required this.employeeId,
    this.employeeName,
    required this.violationType,
    required this.violationDate,
    required this.violationTime,
    required this.penalty,
    required this.penaltyLabel,
    this.notes,
    this.status = 'pending',
    this.statusLabel = 'قيد الانتظار',
    this.acknowledged = false,
    this.acknowledgedAt,
    this.employeeResponse,
    this.employeeResponseAt,
    this.hrReviewed = false,
    this.hrReviewedAt,
    this.hrReviewerId,
    this.hrNotes,
    required this.createdAt,
  });

  factory Violation.fromJson(Map<String, dynamic> json) {
    return Violation(
      violationId: json['violation_id'] ?? 0,
      issuerId: json['issuer_id'],
      issuerName: json['issuer_name'],
      employeeId: json['employee_id'] ?? 0,
      employeeName: json['employee_name'],
      violationType: json['violation_type'] ?? '',
      violationDate: json['violation_date'] ?? '',
      violationTime: json['violation_time'] ?? '',
      penalty: json['penalty'] ?? 'alert1',
      penaltyLabel: json['penalty_label'] ?? '',
      notes: json['notes'],
      status: json['status'] ?? 'pending',
      statusLabel: json['status_label'] ?? 'قيد الانتظار',
      acknowledged: json['acknowledged'] ?? false,
      acknowledgedAt: json['acknowledged_at'],
      employeeResponse: json['employee_response'],
      employeeResponseAt: json['employee_response_at'],
      hrReviewed: json['hr_reviewed'] ?? false,
      hrReviewedAt: json['hr_reviewed_at'],
      hrReviewerId: json['hr_reviewer_id'],
      hrNotes: json['hr_notes'],
      createdAt: json['created_at'] ?? '',
    );
  }

  static const List<Map<String, String>> penaltyOptions = [
    {'value': 'alert1', 'label': 'تنبيه'},
    {'value': 'alert2', 'label': 'تنبيه ثاني'},
    {'value': 'warning', 'label': 'انذار'},
    {'value': 'interrogation', 'label': 'استجواب'},
  ];

  static const List<Map<String, String>> statusOptions = [
    {'value': 'pending', 'label': 'قيد الانتظار'},
    {'value': 'acknowledged', 'label': 'مستلمة'},
    {'value': 'disputed', 'label': 'معلقة'},
    {'value': 'reviewed', 'label': 'تمت المراجعة'},
    {'value': 'closed', 'label': 'مغلقة'},
  ];
}
