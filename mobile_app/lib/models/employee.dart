class Employee {
  final int employeeId;
  final String employeeNumber;
  final String fullName;
  final String? fullNameEn;
  final String? jobTitle;
  final String? phone;
  final String? email;
  final int? orgUnitId;
  final String? orgUnitName;
  final int? workTypeId;
  final String? workTypeName;
  final int? directManagerId;
  final String? directManagerName;
  final bool allowFieldTracking;
  final double? geofenceLat;
  final double? geofenceLng;
  final int? geofenceRadiusM;
  final bool geofenceExempt;
  final bool isActive;
  final String? hireDate;
  final List<String> roles;
  final bool hasPattern;

  Employee({
    required this.employeeId,
    required this.employeeNumber,
    required this.fullName,
    this.fullNameEn,
    this.jobTitle,
    this.phone,
    this.email,
    this.orgUnitId,
    this.orgUnitName,
    this.workTypeId,
    this.workTypeName,
    this.directManagerId,
    this.directManagerName,
    this.allowFieldTracking = false,
    this.geofenceLat,
    this.geofenceLng,
    this.geofenceRadiusM,
    this.geofenceExempt = false,
    this.isActive = true,
    this.hireDate,
    this.roles = const [],
    this.hasPattern = false,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      employeeId: json['employee_id'],
      employeeNumber: json['employee_number'],
      fullName: json['full_name'],
      fullNameEn: json['full_name_en'],
      jobTitle: json['job_title'],
      phone: json['phone'],
      email: json['email'],
      orgUnitId: json['org_unit_id'],
      orgUnitName: json['org_unit_name'],
      workTypeId: json['work_type_id'],
      workTypeName: json['work_type_name'],
      directManagerId: json['direct_manager_id'],
      directManagerName: json['direct_manager_name'],
      allowFieldTracking: json['allow_field_tracking'] ?? false,
      geofenceLat: json['geofence_lat']?.toDouble(),
      geofenceLng: json['geofence_lng']?.toDouble(),
      geofenceRadiusM: json['geofence_radius_m'],
      geofenceExempt: json['geofence_exempt'] ?? false,
      isActive: json['is_active'] ?? true,
      hireDate: json['hire_date'],
      roles: List<String>.from(json['roles'] ?? []),
      hasPattern: json['has_pattern'] ?? false,
    );
  }

  String? get primaryRole => roles.isNotEmpty ? roles.first : null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Employee &&
          runtimeType == other.runtimeType &&
          employeeId == other.employeeId;

  @override
  int get hashCode => employeeId.hashCode;
}

class Profile {
  final int employeeId;
  final String employeeNumber;
  final String fullName;
  final String? jobTitle;
  final String? orgUnitName;
  final List<String> roles;
  final List<String> permissions;
  final bool allowFieldTracking;

  Profile({
    required this.employeeId,
    required this.employeeNumber,
    required this.fullName,
    this.jobTitle,
    this.orgUnitName,
    this.roles = const [],
    this.permissions = const [],
    this.allowFieldTracking = false,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      employeeId: json['employee_id'],
      employeeNumber: json['employee_number'],
      fullName: json['full_name'],
      jobTitle: json['job_title'],
      orgUnitName: json['org_unit_name'],
      roles: List<String>.from(json['roles'] ?? []),
      permissions: List<String>.from(json['permissions'] ?? []),
      allowFieldTracking: json['allow_field_tracking'] ?? false,
    );
  }

  bool get isGM => roles.contains('general_manager');
  bool get isHR => roles.contains('hr_manager');
  bool get isManager => isGM || isHR || roles.contains('field_supervisor') || roles.contains('office_supervisor');
}
