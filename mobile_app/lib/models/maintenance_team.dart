class MaintenanceTeam {
  final int teamId;
  final String teamName;
  final String teamType;
  final String teamTypeLabel;
  final String governorate;
  final int? teamLeaderId;
  final String? leaderName;
  final int memberCount;
  final int maxActiveTasks;
  final bool isActive;
  final String? createdAt;
  final List<TeamMember>? members;

  MaintenanceTeam({
    required this.teamId,
    required this.teamName,
    required this.teamType,
    required this.teamTypeLabel,
    required this.governorate,
    this.teamLeaderId,
    this.leaderName,
    this.memberCount = 0,
    this.maxActiveTasks = 5,
    this.isActive = true,
    this.createdAt,
    this.members,
  });

  factory MaintenanceTeam.fromJson(Map<String, dynamic> json) {
    return MaintenanceTeam(
      teamId: json['team_id'] ?? 0,
      teamName: json['team_name'] ?? '',
      teamType: json['team_type'] ?? '',
      teamTypeLabel: json['team_type_label'] ?? '',
      governorate: json['governorate'] ?? '',
      teamLeaderId: json['team_leader_id'],
      leaderName: json['leader_name'],
      memberCount: json['member_count'] ?? 0,
      maxActiveTasks: json['max_active_tasks'] ?? 5,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'],
      members: json['members'] != null
          ? (json['members'] as List).map((e) => TeamMember.fromJson(e)).toList()
          : null,
    );
  }

  static const List<Map<String, String>> teamTypes = [
    {'value': 'water_maintenance', 'label': 'صيانة خطوط المياه'},
    {'value': 'water_distribution', 'label': 'توزيع المياه'},
    {'value': 'sewage', 'label': 'الصرف الصحي'},
    {'value': 'theft_detection', 'label': 'تتبع سرقة المياه'},
  ];
}

class TeamMember {
  final int id;
  final int employeeId;
  final String employeeName;
  final String employeeNumber;
  final String role;

  TeamMember({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeNumber,
    required this.role,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      id: json['id'] ?? 0,
      employeeId: json['employee_id'] ?? 0,
      employeeName: json['employee_name'] ?? '',
      employeeNumber: json['employee_number'] ?? '',
      role: json['role'] ?? 'technician',
    );
  }
}

class MaintenanceComplaint {
  final int complaintId;
  final String? customerName;
  final String? customerPhone;
  final String description;
  final String category;
  final String categoryLabel;
  final String priority;
  final String priorityLabel;
  final String status;
  final String statusLabel;
  final String governorate;
  final String? district;
  final String? neighborhood;
  final int? teamId;
  final String? teamName;
  final int? assignedTo;
  final String? assignedName;
  final double? latitude;
  final double? longitude;
  final String? photoUrl;
  final String? createdAt;
  final String? assignedAt;
  final String? startedAt;
  final String? resolvedAt;
  final String? resolutionNotes;
  final int? customerSatisfaction;

  MaintenanceComplaint({
    required this.complaintId,
    this.customerName,
    this.customerPhone,
    required this.description,
    required this.category,
    required this.categoryLabel,
    required this.priority,
    required this.priorityLabel,
    required this.status,
    required this.statusLabel,
    required this.governorate,
    this.district,
    this.neighborhood,
    this.teamId,
    this.teamName,
    this.assignedTo,
    this.assignedName,
    this.latitude,
    this.longitude,
    this.photoUrl,
    this.createdAt,
    this.assignedAt,
    this.startedAt,
    this.resolvedAt,
    this.resolutionNotes,
    this.customerSatisfaction,
  });

  factory MaintenanceComplaint.fromJson(Map<String, dynamic> json) {
    return MaintenanceComplaint(
      complaintId: json['complaint_id'] ?? 0,
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      categoryLabel: json['category_label'] ?? '',
      priority: json['priority'] ?? 'medium',
      priorityLabel: json['priority_label'] ?? '',
      status: json['status'] ?? 'new',
      statusLabel: json['status_label'] ?? '',
      governorate: json['governorate'] ?? '',
      district: json['district'],
      neighborhood: json['neighborhood'],
      teamId: json['team_id'],
      teamName: json['team_name'],
      assignedTo: json['assigned_to'],
      assignedName: json['assigned_name'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      photoUrl: json['photo_url'],
      createdAt: json['created_at'],
      assignedAt: json['assigned_at'],
      startedAt: json['started_at'],
      resolvedAt: json['resolved_at'],
      resolutionNotes: json['resolution_notes'],
      customerSatisfaction: json['customer_satisfaction'],
    );
  }

  static const List<Map<String, String>> categories = [
    {'value': 'water_leak_main', 'label': 'تسريب رئيسي'},
    {'value': 'water_leak_neighborhood', 'label': 'تسريب في الحي'},
    {'value': 'sewage_blockage', 'label': 'انسداد صرف'},
    {'value': 'meter_leak', 'label': 'تسريب من العداد'},
    {'value': 'water_outage', 'label': 'انقطاع مياه'},
    {'value': 'sewage_overflow', 'label': 'رفع منسوب صرف'},
    {'value': 'water_theft', 'label': 'شبهة سرقة مياه'},
    {'value': 'pump_failure', 'label': 'عطل مضخة'},
    {'value': 'low_pressure', 'label': 'ضغط مياه منخفض'},
    {'value': 'other', 'label': 'أخرى'},
  ];

  static const List<Map<String, String>> priorities = [
    {'value': 'emergency', 'label': 'طارئ'},
    {'value': 'high', 'label': 'مرتفع'},
    {'value': 'medium', 'label': 'متوسط'},
    {'value': 'low', 'label': 'منخفض'},
  ];

  static const List<Map<String, String>> statuses = [
    {'value': 'new', 'label': 'جديد'},
    {'value': 'assigned', 'label': 'معيّن'},
    {'value': 'in_progress', 'label': 'قيد التنفيذ'},
    {'value': 'resolved', 'label': 'تم الحل'},
    {'value': 'closed', 'label': 'مغلق'},
  ];

  static const List<String> governorates = [
    'عمّان', 'إربد', 'الزرقاء', 'معان', 'العقبة', 'البلقاء', 'jerash', 'المفرق', 'الكرك', 'الطفيلة', 'Madaba',
  ];
}

class PeriodicTask {
  final int taskId;
  final int teamId;
  final String? teamName;
  final String taskName;
  final String? description;
  final String frequency;
  final String frequencyLabel;
  final int? dayOfWeek;
  final String? dayOfWeekLabel;
  final int? dayOfMonth;
  final String timeOfDay;
  final bool isActive;
  final String? lastCompleted;
  final String? nextDue;
  final String? createdAt;

  PeriodicTask({
    required this.taskId,
    required this.teamId,
    this.teamName,
    required this.taskName,
    this.description,
    required this.frequency,
    required this.frequencyLabel,
    this.dayOfWeek,
    this.dayOfWeekLabel,
    this.dayOfMonth,
    required this.timeOfDay,
    this.isActive = true,
    this.lastCompleted,
    this.nextDue,
    this.createdAt,
  });

  factory PeriodicTask.fromJson(Map<String, dynamic> json) {
    return PeriodicTask(
      taskId: json['task_id'] ?? 0,
      teamId: json['team_id'] ?? 0,
      teamName: json['team_name'],
      taskName: json['task_name'] ?? '',
      description: json['description'],
      frequency: json['frequency'] ?? 'weekly',
      frequencyLabel: json['frequency_label'] ?? '',
      dayOfWeek: json['day_of_week'],
      dayOfWeekLabel: json['day_of_week_label'],
      dayOfMonth: json['day_of_month'],
      timeOfDay: json['time_of_day'] ?? '08:00',
      isActive: json['is_active'] ?? true,
      lastCompleted: json['last_completed'],
      nextDue: json['next_due'],
      createdAt: json['created_at'],
    );
  }

  static const List<Map<String, String>> frequencies = [
    {'value': 'daily', 'label': 'يومي'},
    {'value': 'weekly', 'label': 'أسبوعي'},
    {'value': 'biweekly', 'label': 'كل أسبوعين'},
    {'value': 'monthly', 'label': 'شهري'},
    {'value': 'quarterly', 'label': 'كل 3 أشهر'},
  ];

  static const List<Map<String, String>> daysOfWeek = [
    {'value': '0', 'label': 'الاثنين'},
    {'value': '1', 'label': 'الثلاثاء'},
    {'value': '2', 'label': 'الأربعاء'},
    {'value': '3', 'label': 'الخميس'},
    {'value': '4', 'label': 'الجمعة'},
    {'value': '5', 'label': 'السبت'},
    {'value': '6', 'label': 'الأحد'},
  ];
}

class PeriodicTaskCompletion {
  final int completionId;
  final int taskId;
  final String? taskName;
  final int? employeeId;
  final String? employeeName;
  final String completedDate;
  final String? notes;
  final String? photoUrl;
  final String? createdAt;

  PeriodicTaskCompletion({
    required this.completionId,
    required this.taskId,
    this.taskName,
    this.employeeId,
    this.employeeName,
    required this.completedDate,
    this.notes,
    this.photoUrl,
    this.createdAt,
  });

  factory PeriodicTaskCompletion.fromJson(Map<String, dynamic> json) {
    return PeriodicTaskCompletion(
      completionId: json['completion_id'] ?? 0,
      taskId: json['task_id'] ?? 0,
      taskName: json['task_name'],
      employeeId: json['employee_id'],
      employeeName: json['employee_name'],
      completedDate: json['completed_date'] ?? '',
      notes: json['notes'],
      photoUrl: json['photo_url'],
      createdAt: json['created_at'],
    );
  }
}
