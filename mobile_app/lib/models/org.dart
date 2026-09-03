class OrgUnit {
  final int orgUnitId;
  final int? parentId;
  final String unitName;
  final String? unitNameEn;
  final String? unitCode;
  final String unitType;
  final int? managerEmployeeId;
  final bool isActive;

  OrgUnit({
    required this.orgUnitId,
    this.parentId,
    required this.unitName,
    this.unitNameEn,
    this.unitCode,
    required this.unitType,
    this.managerEmployeeId,
    this.isActive = true,
  });

  factory OrgUnit.fromJson(Map<String, dynamic> json) {
    return OrgUnit(
      orgUnitId: json['org_unit_id'],
      parentId: json['parent_id'],
      unitName: json['unit_name'],
      unitNameEn: json['unit_name_en'],
      unitCode: json['unit_code'],
      unitType: json['unit_type'],
      managerEmployeeId: json['manager_employee_id'],
      isActive: json['is_active'] ?? true,
    );
  }
}

class RoleItem {
  final int roleId;
  final String roleName;
  final String roleLabel;

  RoleItem({
    required this.roleId,
    required this.roleName,
    required this.roleLabel,
  });

  factory RoleItem.fromJson(Map<String, dynamic> json) {
    return RoleItem(
      roleId: json['role_id'],
      roleName: json['role_name'],
      roleLabel: json['role_label'],
    );
  }
}

class WorkTypeItem {
  final int workTypeId;
  final String typeName;
  final String typeNameAr;
  final bool isField;

  WorkTypeItem({
    required this.workTypeId,
    required this.typeName,
    required this.typeNameAr,
    required this.isField,
  });

  factory WorkTypeItem.fromJson(Map<String, dynamic> json) {
    return WorkTypeItem(
      workTypeId: json['work_type_id'],
      typeName: json['type_name'],
      typeNameAr: json['type_name_ar'],
      isField: json['is_field'] ?? false,
    );
  }
}
