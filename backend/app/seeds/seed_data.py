from datetime import date
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.organization import OrganizationUnit, WorkType, Employee
from app.models.auth import User, Role, UserRole, Permission, RolePermission
from app.models.work_scope import WorkScopeType
from app.utils.security import hash_password


async def seed_data(db: AsyncSession):
    existing = await db.execute(select(OrganizationUnit).limit(1))
    if existing.scalar_one_or_none():
        return {"message": "Data already seeded"}

    gm_org = OrganizationUnit(unit_name="General Management", unit_name_en="GM", unit_code="GM", unit_type="DEPARTMENT")
    hr_org = OrganizationUnit(unit_name="HR Department", unit_name_en="HR", unit_code="HR", unit_type="DEPARTMENT")
    ops_org = OrganizationUnit(unit_name="Operations", unit_name_en="OPS", unit_code="OPS", unit_type="DEPARTMENT")
    db.add_all([gm_org, hr_org, ops_org])
    await db.flush()

    gm_org2 = OrganizationUnit(parent_id=gm_org.org_unit_id, unit_name="Executive Office", unit_code="GM-EXEC", unit_type="SECTION")
    hr_org2 = OrganizationUnit(parent_id=hr_org.org_unit_id, unit_name="Recruitment", unit_code="HR-REC", unit_type="SECTION")
    ops_org2 = OrganizationUnit(parent_id=ops_org.org_unit_id, unit_name="Field Operations", unit_code="OPS-FIELD", unit_type="SECTION")
    db.add_all([gm_org2, hr_org2, ops_org2])
    await db.flush()

    field_type = WorkType(type_name="FIELD", type_name_ar="ميداني", description="Field work with GPS tracking", is_field=True)
    office_type = WorkType(type_name="OFFICE", type_name_ar="مكتبي", description="Office work")
    hybrid_type = WorkType(type_name="HYBRID", type_name_ar="مختلط", description="Mix of field and office", is_field=True)
    db.add_all([field_type, office_type, hybrid_type])
    await db.flush()

    scope_types_data = [
        ("DIRECTORATE", "مديرية"),
        ("DEPARTMENT", "إدارة"),
        ("SECTION", "قسم"),
        ("SUBSECTION", "شعبة"),
        ("AREA", "منطقة"),
        ("NEIGHBORHOOD", "حي"),
        ("ROUTE", "مسار"),
        ("TASK", "مهمة"),
    ]
    scope_types = {}
    for type_name, type_name_ar in scope_types_data:
        st = WorkScopeType(type_name=type_name, type_name_ar=type_name_ar)
        db.add(st)
        await db.flush()
        scope_types[type_name] = st

    gm_emp = Employee(employee_number="EMP001", full_name="Ahmad Al-Rashid", full_name_en="Ahmad Al-Rashid",
                      job_title="General Manager", org_unit_id=gm_org.org_unit_id, work_type_id=office_type.work_type_id,
                      hire_date=date(2020, 1, 1), is_active=True, allow_field_tracking=False)
    hr_emp = Employee(employee_number="EMP002", full_name="Fatima Hassan", full_name_en="Fatima Hassan",
                      job_title="HR Manager", org_unit_id=hr_org.org_unit_id, work_type_id=office_type.work_type_id,
                      hire_date=date(2021, 3, 15), is_active=True, allow_field_tracking=False)
    field_emp = Employee(employee_number="EMP003", full_name="Omar Khalil", full_name_en="Omar Khalil",
                         job_title="Field Engineer", org_unit_id=ops_org2.org_unit_id, work_type_id=field_type.work_type_id,
                         hire_date=date(2022, 6, 1), is_active=True, allow_field_tracking=True)
    office_emp = Employee(employee_number="EMP004", full_name="Lina Mansour", full_name_en="Lina Mansour",
                          job_title="Office Clerk", org_unit_id=hr_org2.org_unit_id, work_type_id=office_type.work_type_id,
                          hire_date=date(2023, 1, 10), is_active=True, allow_field_tracking=False)
    db.add_all([gm_emp, hr_emp, field_emp, office_emp])
    await db.flush()

    gm_emp.direct_manager_id = gm_emp.employee_id
    hr_emp.direct_manager_id = gm_emp.employee_id
    field_emp.direct_manager_id = gm_emp.employee_id
    office_emp.direct_manager_id = hr_emp.employee_id
    db.add_all([gm_emp, hr_emp, field_emp, office_emp])
    await db.flush()

    roles_data = [
        ("general_manager", "General Manager"),
        ("hr_manager", "HR Manager"),
        ("field_supervisor", "Field Supervisor"),
        ("office_supervisor", "Office Supervisor"),
        ("employee", "Employee"),
    ]
    roles = {}
    for role_name, role_label in roles_data:
        role = Role(role_name=role_name, role_label=role_label)
        db.add(role)
        await db.flush()
        roles[role_name] = role

    permissions_data = [
        ("auth.login", "Login", "auth"),
        ("employees.view", "View Employees", "employees"),
        ("employees.manage", "Manage Employees", "employees"),
        ("attendance.check_in", "Check In", "attendance"),
        ("attendance.check_out", "Check Out", "attendance"),
        ("attendance.view_own", "View Own Attendance", "attendance"),
        ("attendance.view_all", "View All Attendance", "attendance"),
        ("leave.request", "Request Leave", "leave"),
        ("leave.view_own", "View Own Leaves", "leave"),
        ("leave.view_all", "View All Leaves", "leave"),
        ("leave.approve", "Approve Leaves", "leave"),
        ("maintenance.create", "Create Complaint", "maintenance"),
        ("maintenance.assign", "Assign Complaint", "maintenance"),
        ("maintenance.view", "View Complaints", "maintenance"),
        ("maintenance.track", "Track Complaints", "maintenance"),
        ("gps.track_own", "Track Own GPS", "gps"),
        ("gps.track_all", "Track All GPS", "gps"),
        ("gps.view_map", "View Map", "gps"),
        ("overtime_work.request", "Request Overtime", "overtime"),
        ("overtime_work.view_own", "View Own Overtime", "overtime"),
        ("overtime_work.view_all", "View All Overtime", "overtime"),
        ("overtime_work.approve", "Approve Overtime", "overtime"),
        ("overtime_work.extend", "Extend Overtime", "overtime"),
        ("overtime_work.report", "Submit Overtime Report", "overtime"),
        ("reports.view", "View Reports", "reports"),
        ("reports.export", "Export Reports", "reports"),
        ("notifications.view", "View Notifications", "notifications"),
        ("audit.view", "View Audit Logs", "audit"),
    ]
    perms = {}
    for perm_code, perm_name, module in permissions_data:
        perm = Permission(permission_code=perm_code, permission_name=perm_name, module=module)
        db.add(perm)
        await db.flush()
        perms[perm_code] = perm

    perm_codes = [p[0] for p in permissions_data]
    role_perms = {
        "general_manager": list(perms.values()),
        "hr_manager": [perms[p] for p in perm_codes if p not in ("maintenance.create", "maintenance.assign")],
        "field_supervisor": [perms[p] for p in perm_codes if "employee" not in p or "view" in p],
        "office_supervisor": [perms[p] for p in perm_codes if "gps" not in p],
        "employee": [perms[p] for p in ["auth.login", "attendance.check_in", "attendance.check_out",
                                         "attendance.view_own", "leave.request", "leave.view_own",
                                         "maintenance.create", "maintenance.view",
                                         "overtime_work.request", "overtime_work.view_own",
                                         "overtime_work.report", "notifications.view"]],
    }
    for role_name, role_perms_list in role_perms.items():
        for perm in role_perms_list:
            rp = RolePermission(role_id=roles[role_name].role_id, permission_id=perm.permission_id, scope_level="SELF")
            db.add(rp)

    users_data = [
        (gm_emp.employee_id, "EMP001", "general_manager"),
        (hr_emp.employee_id, "EMP002", "hr_manager"),
        (field_emp.employee_id, "EMP003", "employee"),
        (office_emp.employee_id, "EMP004", "employee"),
    ]
    for emp_id, username, role_name in users_data:
        user = User(
            employee_id=emp_id,
            username=username,
            password_hash=hash_password("Yarmouk@2025"),
            is_active=True,
        )
        db.add(user)
        await db.flush()
        ur = UserRole(user_id=user.user_id, role_id=roles[role_name].role_id)
        db.add(ur)

    await db.commit()
    return {"message": "Seed data created successfully"}
