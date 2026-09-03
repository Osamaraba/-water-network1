# Yarmouk Water Management Pro - التوثيق الكامل

## نظرة عامة
نظام إدارة شركة مياه اليرموك - تطبيق متكامل لإدارة الموظفين و OPTIONAL العمليات الميدانية والإدارية.
يتكون من خادم FastAPI + قاعدة بيانات SQLite + تطبيق Flutter للويندوز.

---

## معلومات النظام
| البند | التفاصيل |
|-------|----------|
| **اسم النظام** | Yarmouk Water Management Pro |
| **إصدار API** | 1.0.0 |
| **خادم Backend** | FastAPI + SQLAlchemy Async |
| **قاعدة البيانات** | SQLite (`yarmouk_water_pro.db`) |
| **تطبيق Flutter** | Windows Desktop (.exe) |
| **منفذ الخادم** | 8000 |
| **العنوان** | http://localhost:8000 |

---

## بيانات الدخول
| حقل | قيمة |
|------|------|
| **رقم الموظف** | `EMP001` |
| **كلمة المرور** | `Yarmouk@2025` |
| **الصلاحية** | General Manager (مدير عام) |

---

## إحصائيات النظام
| البند | العدد |
|-------|-------|
| **إجمالي نقاط النهاية (Endpoints)** | 138 |
| **الموظفين المسجلين** | 89 |
| **المستخدمين النشطين** | 83 |
| **الأدوار (Roles)** | 5 |
| **أنواع العمل** | 8 |
| **الوحدات التنظيمية** | 14 |

---

## الأدوار والصلاحيات (RBAC)

### الدور 1: المدير العام (General Manager)
- **الرمز**: `general_manager`
- **الصلاحية**: صلاحيات كاملة على النظام
- **يمكنه**:
  - إدارة جميع الموظفين
  - الاطلاع على جميع التقارير
  - الموافقة على الإجازات والعمل الإضافي
  - متابعة المخالفات
  - تتبع الميداني للموظفين
  - إعادة تعيين كلمات المرور
  - إدارة الفرق

### الدور 2: مدير الموارد البشرية (HR Manager)
- **الرمز**: `hr_manager`
- **يمكنه**:
  - إدارة بيانات الموظفين
  - مراجعة طلبات الإجازة
  - مراجعة المخالفات
  - إنشاء التقارير الإدارية
  - معالجة شكاوى الموظفين

### الدور 3: مشرف الميدان (Field Supervisor)
- **الرمز**: `field_supervisor`
- **يمكنه**:
  - تتبع موظفي الميدان عبر GPS
  - بدء/إيقاف جلسات التتبع
  - عرض خرائط العمل
  - إنشاء مخالفات ميدانية

### الدور 4: مشرف المكتب (Office Supervisor)
- **الرمز**: `office_supervisor`
- **يمكنه**:
  - متابعة حضور الموظفين
  - مراجعة العمل الإضافي
  - عرض التقارير
  - إدارة شكاوى الصيانة

### الدور 5: موظف (Employee)
- **الرمز**: `employee`
- **يمكنه**:
  - تسجيل الحضور والانصراف
  - طلب إجازات
  - طلب عمل إضافي
  - عرض ملفه الشخصي
  - استلام الإشعارات

---

## واجهة برمجة التطبيقات (API Endpoints)

### 1. المصادقة (Authentication) - `/auth`
| الطريقة | المس الوظيفي | الوصف | الصلاحيات |
|---------|-------------|-------|----------|
| POST | `/auth/login` | تسجيل الدخول | عام |
| POST | `/auth/refresh` | تحديث التوكن | عام |
| POST | `/auth/logout` | تسجيل الخروج | عام |
| GET | `/auth/me` | بيانات المستخدم الحالي | عام |

### 2. الموظفين (Employees) - `/employees`
| الطريقة | المس الوظيفي | الوصف | الصلاحيات |
|---------|-------------|-------|----------|
| GET | `/employees/` | قائمة الموظفين | المدير العام، الموارد البشرية |
| GET | `/employees/all` | جميع الموظفين | المدير العام |
| GET | `/employees/me` | بيانات الموظف الحالي | عام |
| GET | `/employees/{id}` | بيانات موظف محدد | المدير العام |
| PUT | `/employees/{id}` | تحديث بيانات موظف | المدير العام |
| DELETE | `/employees/{id}` | حذف موظف | المدير العام |
| POST | `/employees/bulk-import` | استيراد جماعي من Excel | المدير العام |
| GET | `/employees/template` | نموذج Excel للاستيراد | المدير العام |
| GET | `/employees/roles` | قائمة الأدوار | عام |
| GET | `/employees/work-types` | قائمة أنواع العمل | عام |

### 3. الحضور والانصراف (Attendance) - `/attendance`
| الطريقة | المس الوظيفي | الوصف | الصلاحيات |
|---------|-------------|-------|----------|
| POST | `/attendance/check-in` | تسجيل حضور | عام |
| POST | `/attendance/check-out` | تسجيل انصراف | عام |
| GET | `/attendance/today` | حضور اليوم | عام |
| GET | `/attendance/` | سجل الحضور | المدير العام |
| GET | `/attendance/me` | حضوري | عام |
| POST | `/attendance/setup-pattern` | إعداد نمط الحضور | المدير العام |
| POST | `/attendance/verify-pattern` | التحقق من النمط | عام |
| GET | `/attendance/identity-status` | حالة الهوية | عام |

### 4. الإجازات (Leave) - `/leave/` و `/leave_requests/`
| الطريقة | المس الوظيفي | الوصف | الصلاحيات |
|---------|-------------|-------|----------|
| POST | `/leave/` | طلب إجازة | عام |
| GET | `/leave/my` | إجازاتي | عام |
| GET | `/leave/all` | جميع الإجازات | المدير العام |
| POST | `/leave/{id}/review` | مراجعة طلب إجازة | المدير العام |
| POST | `/leave/short` | إجازة قصيرة | عام |
| GET | `/leave/short/my` | إجازاتي القصيرة | عام |
| POST | `/leave/short/{id}/review` | مراجعة إجازة قصيرة | المدير العام |
| GET | `/leave_requests/` | طلبات الإجازة | المدير العام |
| GET | `/leave_requests/my` | طلباتي | عام |
| GET | `/leave_requests/all` | جميع الطلبات | المدير العام |
| GET | `/leave_requests/{id}` | طلب محدد | عام |

### 5. العمل الإضافي (Overtime) - `/overtime-work/`
| الطريقة | المس الوظيفي | الوصف | الصلاحيات |
|---------|-------------|-------|----------|
| POST | `/overtime-work/` | طلب عمل إضافي | عام |
| GET | `/overtime-work/my` | طلباتي | عام |
| GET | `/overtime-work/all` | جميع الطلبات | المدير العام |
| POST | `/overtime-work/{id}/review` | مراجعة الطلب | المدير العام |
| POST | `/overtime-work/{id}/extend` | تمديد العمل | المدير العام |
| POST | `/overtime-work/{id}/complete` | إكمال العمل | المدير العام |
| GET | `/overtime-work/{id}/reports` | تقارير العمل | المدير العام |
| GET | `/overtime-work/{id}/print` | طباعة التقرير | المدير العام |

### 6. المخالفات (Violations) - `/violations/`
| الطريقة | المس الوظيفي | الوصف | الصلاحيات |
|---------|-------------|-------|----------|
| POST | `/violations/` | إنشاء مخالفة | المدير العام، الموارد البشرية |
| GET | `/violations/my` | مخالفاتي | عام |
| GET | `/violations/team` | مخالفات الفريق | المشرفون |
| GET | `/violations/pending-review` | مراجعة المخالفات | الموارد البشرية |
| GET | `/violations/stats` | إحصائيات المخالفات | المدير العام |
| POST | `/violations/{id}/acknowledge` | تأكيد المخالفة | عام |
| POST | `/violations/{id}/respond` | الرد على المخالفة | عام |
| POST | `/violations/{id}/hr-review` | مراجعة الموارد البشرية | الموارد البشرية |
| GET | `/violations/{id}/print` | طباعة المخالفة | عام |

### 7. التتبع الميداني (GPS) - `/gps/`
| الطريقة | المس الوظيفي | الوصف | الصلاحيات |
|---------|-------------|-------|----------|
| POST | `/gps/start` | بدء جلسة تتبع | مشرف الميدان |
| POST | `/gps/stop` | إيقاف الجلسة | مشرف الميدان |
| POST | `/gps/point` | إرسال نقطة | مشرف الميدان |
| GET | `/gps/my-active` | جلستي النشطة | مشرف الميدان |
| GET | `/gps/view` | عرض تتبع | المدير العام |
| GET | `/gps/employees` | موظفون للمتابعة | المدير العام |
| GET | `/gps/sessions` | جميع الجلسات | المدير العام |
| GET | `/gps/sessions/me` | جلساتي | مشرف الميدان |
| GET | `/gps/breaches` | انتهاكات الحد | المدير العام |
| GET | `/gps/viewer` | عارض التتبع | المدير العام |
| POST | `/gps/set-viewer` | تعيين عارض | المدير العام |
| GET | `/gps/history` | سجل التتبع | المدير العام |
| POST | `/gps/simulate-point` | محاكاة نقطة | المدير العام |

### 8. الصيانة (Maintenance) - `/maintenance/`
| الطريقة | المس الوظيفي | الوصف | الصلاحيات |
|---------|-------------|-------|----------|
| GET | `/maintenance/` | شكاوى الصيانة | عام |
| GET | `/maintenance/me` | صيانتي | عام |

### 9. فرق الصيانة (Maintenance Teams) - `/maintenance-teams/`
| الطريقة | المس الوظيفي | الوصف | الصلاحيات |
|---------|-------------|-------|----------|
| GET | `/maintenance-teams/teams` | الفرق | المدير العام |
| GET | `/maintenance-teams/teams/{id}` | فريق محدد | المدير العام |
| GET | `/maintenance-teams/teams/{id}/members` | أعضاء الفريق | المدير العام |
| POST | `/maintenance-teams/teams/{id}/members` | إضافة عضو | المدير عام |
| DELETE | `/maintenance-teams/teams/{id}/members/{mid}` | حذف عضو | المدير العام |
| GET | `/maintenance-teams/complaints` | الشكاوى | المدير العام |
| GET | `/maintenance-teams/complaints/my-team` | شكاوى فريقي | مشرف الفرقة |
| POST | `/maintenance-teams/complaints/{id}/assign` | تعيين شكوى | المدير العام |
| POST | `/maintenance-teams/complaints/{id}/update` | تحديث شكوى | مشرف الفرقة |
| GET | `/maintenance-teams/stats` | إحصائيات الصيانة | المدير العام |

### 10. الصيانة الدورية (Periodic Maintenance) - `/periodic-maintenance/`
| الطريقة | المس الوظيفي | الوصف | الصلاحيات |
|---------|-------------|-------|----------|
| GET | `/periodic-maintenance/tasks` | المهام | المدير العام |
| GET | `/periodic-maintenance/tasks/my-team` | مهام فريقي | مشرف الفرقة |
| GET | `/periodic-maintenance/tasks/upcoming` | المهام القادمة | عام |
| POST | `/periodic-maintenance/tasks/{id}/complete` | إكمال مهمة | مشرف الفرقة |
| GET | `/periodic-maintenance/tasks/{id}/completions` | سجل الإكمال | المدير العام |

### 11. التقارير (Reports) - `/reports/` و `/reports-extended/`
| الطريقة | المس الوظيفي | الوصف | الصلاحيات |
|---------|-------------|-------|----------|
| GET | `/reports/inbox` | صندوق الوارد | المدير العام |
| GET | `/reports/daily` | تقرير يومي | المدير العام |
| GET | `/reports/{id}` | تقرير محدد | المدير العام |
| GET | `/reports-extended/full-profile/{id}` | ملف شامل | المدير العام |
| GET | `/reports-extended/attendance` | تقرير الحضور | المدير العام |
| GET | `/reports-extended/leave` | تقرير الإجازات | المدير العام |
| GET | `/reports-extended/overtime` | تقرير العمل الإضافي | المدير العام |
| GET | `/reports-extended/violations` | تقرير المخالفات | المدير العام |
| GET | `/reports-extended/audit` | سجل التدقيق | المدير العام |
| GET | `/reports-extended/dashboard` | لوحة التحكم | المدير العام |
| GET | `/reports-extended/attendance/summary` | ملخص الحضور | المدير العام |
| GET | `/reports-extended/leave/summary` | ملخص الإجازات | المدير العام |
| GET | `/reports-extended/overtime/summary` | ملخص العمل الإضافي | المدير العام |
| GET | `/reports-extended/employees/directory` | دليل الموظفين | المدير العام |
| GET | `/reports-extended/export/attendance` | تصدير الحضور | المدير العام |
| GET | `/reports-extended/admin/attendance` | إدارة الحضور | المدير العام |
| GET | `/reports-extended/admin/leave` | إدارة الإجازات | المدير العام |
| GET | `/reports-extended/admin/overtime` | إدارة العمل الإضافي | المدير العام |
| GET | `/reports-extended/admin/violations` | إدارة المخالفات | المدير العام |

### 12. الإشعارات (Notifications) - `/notifications/`
| الطريقة | المس الوظيفي | الوصف | الصلاحيات |
|---------|-------------|-------|----------|
| GET | `/notifications/` | الإشعارات | عام |
| GET | `/notifications/unread` | الإشعارات غير المقروءة | عام |
| POST | `/notifications/{id}/read` | تحديد كمقروء | عام |
| POST | `/notifications/read-all` | تحديد الكل كمقروء | عام |
| POST | `/notifications/bulk` | إشعارات جماعية | المدير العام |

### 13. الأمان (Security) - `/security`
| الطريقة | المس الوظيفي | الوصف | الصلاحيات |
|---------|-------------|-------|----------|
| POST | `/security/change-password` | تغيير كلمة المرور | عام |
| POST | `/security/admin/reset-password` | إعادة تعيين (الأدمن) | المدير العام |
| GET | `/security/sessions` | الجلسات النشطة | عام |
| POST | `/security/revoke-all-sessions` | إلغاء جميع الجلسات | عام |
| GET | `/security/security-status` | حالة الأمان | عام |

### 14. التنظيم (Organization) - `/organization/`
| الطريقة | المس الوظيفي | الوصف | الصلاحيات |
|---------|-------------|-------|----------|
| GET | `/organization/units` | الوحدات التنظيمية | عام |
| GET | `/organization/units/{id}` | وحدة محددة | عام |
| GET | `/organization/tree` | الشجرة التنظيمية | عام |
| GET | `/organization/` | الإدارية | المدير العام |
| PUT | `/organization/{id}` | تحديث وحدة | المدير العام |

### 15. الإجراءات الجماعية (Bulk Actions) - `/bulk`
| الطريقة | المس الوظيفي | الوصف | الصلاحيات |
|---------|-------------|-------|----------|
| POST | `/bulk/leave/approve` | موافقة جماعية على الإجازات | المدير العام |
| POST | `/bulk/overtime/approve` | موافقة جماعية على العمل الإضافي | المدير العام |

### 16. النطاقات (Work Scopes) - `/work_scopes/`
| الطريقة | المس الوظيفي | الوصف | الصلاحيات |
|---------|-------------|-------|----------|
| GET | `/work_scopes/` | نطاقات العمل | المدير العام |

### 17. خدمة العملاء (Customer Service) - `/customer_service/`
| الطريقة | المس الوظيفي | الوصف | الصلاحيات |
|---------|-------------|-------|----------|
| GET | `/customer_service/` | خدمة العملاء | المدير العام |

### 18. توزيع المياه (Water Distribution) - `/water_distribution/`
| الطريقة | المس الوظيفي | الوصف | الصلاحيات |
|---------|-------------|-------|----------|
| GET | `/water_distribution/` | توزيع المياه | المدير العام |

### 19. التدقيق (Audit) - `/audit/`
| الطريقة | المس الوظيفي | الوصف | الصلاحيات |
|---------|-------------|-------|----------|
| GET | `/audit/` | سجل التدقيق | المدير العام |

### 20. المهام (Tasks) - `/tasks/`
| الطريقة | المس الوظيفي | الوصف | الصلاحيات |
|---------|-------------|-------|----------|
| GET | `/tasks/` | المهام | المدير العام |
| GET | `/tasks/{id}` | مهمة محددة | المدير العام |
| POST | `/tasks/{id}/cancel` | إلغاء مهمة | المدير العام |
| POST | `/tasks/trigger/{name}` | تشغيل مهمة | المدير العام |

### 21. مفاتيح API (API Keys) - `/api-keys/`
| الطريقة | المس الوظيفي | الوصف | الصلاحيات |
|---------|-------------|-------|----------|
| GET | `/api-keys/` | المفاتيح | المدير العام |
| POST | `/api-keys/` | إنشاء مفتاح | المدير العام |
| DELETE | `/api-keys/{id}` | حذف مفتاح | المدير العام |
| POST | `/api-keys/{id}/regenerate` | إعادة إنشاء | المدير العام |

---

## هيكل قاعدة البيانات

### الجداول الرئيسية
1. **employees** - بيانات الموظفين (89 سجل)
2. **users** - حسابات المستخدمين (83 حساب)
3. **roles** - الأدوار (5 أدوار)
4. **user_roles** - ربط المستخدمين بالأدوار
5. **permissions** - الصلاحيات
6. **role_permissions** - ربط الأدوار بالصلاحيات
7. **attendance** - سجلات الحضور والانصراف
8. **leave_requests** - طلبات الإجازة
9. **overtime_requests** - طلبات العمل الإضافي
10. **violation_notices** - المخالفات
11. **maintenance_complaints** - شكاوى الصيانة
12. **maintenance_teams** - فرق الصيانة
13. **team_members** - أعضاء الفرق
14. **periodic_maintenance_tasks** - المهام الدورية
15. **periodic_task_completions** - سجل إكمال المهام
16. **field_tracking_sessions** - جلسات التتبع الميداني
17. **field_tracking_points** - نقاط التتبع
18. **geofence_breaches** - انتهاكات الحد الجغرافي
19. **notifications** - الإشعارات
20. **audit_logs** - سجلات التدقيق
21. **work_scopes** - نطاقات العمل
22. **organization_units** - الوحدات التنظيمية
23. **work_types** - أنواع العمل
24. **customer_service_records** - سجلات خدمة العملاء
25. **water_distribution_records** - سجلات توزيع المياه
26. **api_keys** - مفاتيح API
27. **background_tasks** - المهام في الخلفية
28. **sessions** - جلسات المستخدمين

---

## شاشات Flutter

### الشاشات الرئيسية
1. **شاشة تسجيل الدخول** (`LoginScreen`)
2. **لوحة التحكم** (`DashboardScreen`)
3. **الحضور والانصراف** (`AttendanceScreen`)
4. **الإجازات** (`LeaveScreen`)
5. **العمل الإضافي** (`OvertimeScreen`)
6. **التتبع الميداني** (`GpsScreen`)
7. **الملف الشخصي** (`ProfileScreen`)
8. **التقارير** (`ReportsScreen`)

### شاشات الإدارة
1. **إدارة الموظفين** (`EmployeesScreen`)
2. **استيراد الموظفين** (`EmployeeImportScreen`)
3. **الهيكل التنظيمي** (`OrgStructureScreen`)
4. **المخالفات** (`ViolationScreen`)
5. **مراجعة مخالفات الموارد البشرية** (`HrViolationReviewScreen`)
6. **مخالفات فريق المدير** (`ManagerTeamViolationsScreen`)
7. **ملف الموظف الكامل** (`EmployeeFullProfileScreen`)
8. **التقارير الإدارية** (`ManagementReportsScreen`)
9. **إعادة تعيين كلمة المرور** (`AdminResetPasswordScreen`)

### شاشات الصيانة
1. **لوحة تحكم الصيانة** (`MaintenanceDashboardScreen`)
2. **إدارة الفرق** (`TeamsManagementScreen`)
3. **عرض الفرقة** (`TeamMobileViewScreen`)
4. **الصيانة الدورية** (`PeriodicMaintenanceScreen`)
5. **الصيانة** (`MaintenanceScreen`)

### شاشات التقارير
1. **صندوق الوارد** (`ReportInboxScreen`)
2. **تقرير الحضور** (`ReportAttendanceScreen`)
3. **تقرير الإجازات** (`ReportLeaveScreen`)
4. **تقرير العمل الإضافي** (`ReportOvertimeScreen`)
5. **تقرير المخالفات** (`ReportViolationsScreen`)

### شاشات أخرى
1. **الإشعارات** (`NotificationsScreen`)
2. **المخالفات** (`MyViolationsScreen`)

---

## الميزات الرئيسية

### 1. نظام المصادقة والصلاحيات
- تسجيل الدخول برقم الموظف وكلمة المرور
- توكن JWT مع صلاحية محددة
- نظام الأدوار RBAC مع 5 أدوار
- إعادة تعيين كلمة المرور من المدير العام
- تغيير كلمة المرور من المستخدم

### 2. إدارة الموظفين
- قائمة شاملة بجميع الموظفين (89)
- استيراد جماعي من ملف Excel
- ملف شخصي شامل لكل موظف
- البحث والفلترة
- ربط المشرف المباشر
- ربط الوحدة التنظيمية ونوع العمل

### 3. الحضور والانصراف
- تسجيل حضور وانصراف بضغطة زر
- سجل يومي وشهري
- نمط حضور قابل للإعداد
- التحقق من الهوية

### 4. نظام الإجازات
- طلب إجازة بأنواعها (سنوية، مرضية، بدون راتب، أمومة، أبوة)
- إجازات قصيرة
- سير عمل الموافقة
- إشعارات للموافقة/الرفض

### 5. العمل الإضافي
- طلب عمل إضافي
- سير عمل الموافقة
- تمديد العمل
- تقارير العمل الإضافي
- طباعة التقارير

### 6. نظام المخالفات
- إنشاء مخالفات بأسباب مختلفة
- مراجعة الموارد البشرية
- رد الموظف على المخالفة
- إحصائيات المخالفات
- طباعة المخالفات

### 7. التتبع الميداني (GPS)
- بدء/إيقاف جلسة تتبع
- إرسال مواقع فورية
- خرائط تفاعلية
- نظام حد جغرافي (Geofence)
- كشف خروج عن النطاق
- تتبع الألوان حسب الدور
- عرض تاريخ التتبع

### 8. نظام الصيانة
- شكاوى الصيانة
- إدارة الفرق
- المهام الدورية
- سجل الإكمال

### 9. التقارير الشاملة
- تقارير الحضور والإجازات والعمل الإضافي
- تقارير المخالفات
- لوحة تحكم إدارية
- ملف شامل لكل موظف
- تصدير البيانات

### 10. الإشعارات
- إشعارات فورية
- إشعارات غير مقروءة
- إشعارات جماعية

### 11. الأمان
- تغيير كلمة المرور
- إدارة الجلسات النشطة
- سجل التدقيق
- مفاتيح API

---

## الهيكل التنظيمي

### الوحدات التنظيمية
| الرمز | اسم الوحدة | النوع |
|-------|-----------|-------|
| GM | المديرية العامة | إدارية |
| HR | الموارد البشرية | إدارية |
| FIN | المالية | إدارية |
| OPS | العمليات | إدارية |
| DIST-T | التوزيع - فرع طبرب | إدارية |
| DIST-S | التوزيع - فرع السكاكبة | إدارية |
| DIST-Q | التوزيع - فرع القWhiteSpace | إدارية |
| MAINT | الصيانة | إدارية |
| CS | خدمة العملاء | إدارية |
| FIELD-G | الميداني - الجSED | ميدانية |
| FIELD-S | الميداني - السMISSA | ميدانية |
| FIELD-Q | الميداني - القWhiteSpace | ميدانية |
| FIELD-M | الميداني - المخازن | ميدانية |
| FIELD-H | الميداني - الحSNAN | ميدانية |

### أنواع العمل
| الرمز | الاسم | ميداني؟ |
|-------|-------|---------|
| ADMIN | إداري | لا |
| FIELD | ميداني | نعم |
| SUPERVISOR | مشرف | نعم |
| TECHNICIAN | فني | نعم |
| DRIVER | سائق | نعم |
| OPERATOR | مشغل | نعم |
| CLERK | كاتب | لا |
| ENGINEER | مهندس | لا |

---

## تتبع الميداني (GPS) بالتفصيل

### أنواع الألوان حسب الدور
| اللون | الدور |
|-------|-------|
| أزرق | مشرف الميدان |
| أخضر | سائق |
| برتقالي | فني |
| أحمر | مشغل |
| بنفسجي | موظف ميداني |

### نظام الحد الجغرافي (Geofence)
- يتم كشف الخروج عن النطاق على الخادم
- يتم تسجيل كل نقطة مع حالة `is_outside`
- يمكن للمدير العام عرض م违theses الحد الجغرافي

---

## ملفات المشروع الرئيسية

### Backend
```
D:\yarmouk_water_management_pro\backend\
├── app/
│   ├── main.py                    # نقطة الدخول الرئيسية
│   ├── config.py                  # إعدادات النظام
│   ├── database.py                # قاعدة البيانات
│   ├── models/                    # النماذج
│   │   ├── organization.py        # الموظفين والوحدات
│   │   ├── auth.py                # المصادقة
│   │   ├── field_tracking.py      # التتبع الميداني
│   │   └── ...
│   ├── routers/                   # نقاط النهاية
│   │   ├── auth.py                # المصادقة
│   │   ├── employees.py           # الموظفين
│   │   ├── attendance.py          # الحضور
│   │   ├── leave_requests.py      # الإجازات
│   │   ├── overtime_work.py       # العمل الإضافي
│   │   ├── violations.py          # المخالفات
│   │   ├── gps.py                 # التتبع الميداني
│   │   ├── maintenance.py         # الصيانة
│   │   ├── maintenance_teams.py   # فرق الصيانة
│   │   ├── periodic_maintenance.py # الصيانة الدورية
│   │   ├── reports.py             # التقارير
│   │   ├── reports_extended.py    # التقارير الموسعة
│   │   ├── notifications.py       # الإشعارات
│   │   ├── security.py            # الأمان
│   │   ├── organization.py        # التنظيم
│   │   ├── compatibility.py       # التوافق
│   │   ├── flutter_compat.py      # توافق Flutter
│   │   ├── audit.py               # التدقيق
│   │   ├── bulk_actions.py        # الإجراءات الجماعية
│   │   ├── tasks.py               # المهام
│   │   └── api_keys.py            # مفاتيح API
│   ├── middleware/                 # الوسيطات
│   │   └── auth.py                # مصادقة المستخدم
│   ├── services/                  # الخدمات
│   │   └── notifications.py       # خدمة الإشعارات
│   └── utils/                     # الأدوات المساعدة
│       ├── security.py            # الأمان
│       └── excel_export.py        # تصدير Excel
└── yarmouk_water_pro.db           # قاعدة البيانات
```

### Flutter
```
D:\yarmouk_water_management_pro\mobile_app\
├── lib/
│   ├── main.dart                  # نقطة الدخول
│   ├── config/
│   │   └── api_config.dart        # إعدادات API
│   ├── models/
│   │   ├── employee.dart          # نموذج الموظف
│   │   └── org.dart               # النماذج التنظيمية
│   ├── services/
│   │   ├── auth_provider.dart     # مزود المصادقة
│   │   └── services.dart          # خدمات API
│   ├── screens/
│   │   ├── auth/                  # شاشات الدخول
│   │   ├── dashboard/             # لوحة التحكم
│   │   ├── attendance/            # الحضور
│   │   ├── leave/                 # الإجازات
│   │   ├── overtime/              # العمل الإضافي
│   │   ├── gps/                   # التتبع الميداني
│   │   ├── maintenance/           # الصيانة
│   │   ├── admin/                 # الإدارة
│   │   ├── reports/               # التقارير
│   │   ├── notifications/         # الإشعارات
│   │   └── profile/               # الملف الشخصي
│   └── theme/
│       └── app_theme.dart         # تصميم التطبيق
└── build\windows\x64\runner\Release\
    └── yarmouk_water_pro.exe      # التطبيق
```

---

## أوامر التشغيل

### تشغيل الخادم
```bash
cd D:\yarmouk_water_management_pro\backend
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### تشغيل التطبيق
```bash
D:\yarmouk_water_management_pro\mobile_app\build\windows\x64\runner\Release\yarmouk_water_pro.exe
```

### بناء التطبيق
```bash
cd D:\yarmouk_water_management_pro\mobile_app
flutter pub get
flutter build windows --release
```

### اختبار API
```bash
cd D:\yarmouk_water_management_pro
python test_all.py
```

---

## ملخص الإصلاحات الأخيرة

### إصلاحات حرجة (PHASE 2)
1. ✅ **compatibility.py** - إزالة مسار POST /leave/ المكرر
2. ✅ **violations.py** - إصلاح `Employee.reporting_to` → `Employee.direct_manager_id`
3. ✅ **reports_extended.py** - إصلاح `log.user_id` و `log.details` → `log.employee_id` و `log.old_values`/`log.new_values`
4. ✅ **maintenance_teams.py** - تغيير البادئة من `/maintenance` إلى `/maintenance-teams` لتجنب التعارض

### إصلاحات Flutter
1. ✅ **main.dart** - إضافة مسار `/maintenance-complaints` المفقود
2. ✅ **gps_screen.dart** - إصلاح أخطاء الترجمة ( roles getter، syntax errors)

### نتائج الفحص النهائي (PHASE 3)
- ✅ **73/73** نقطة نهاية تعمل بشكل صحيح
- ✅ **138** نقطة نهاية مسجلة في OpenAPI
- ✅ **89** موظف في قاعدة البيانات
- ✅ جميع الأدوار والصلاحيات تعمل

---

## معلومات الاتصال
- **Backend**: http://localhost:8000
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **OpenAPI JSON**: http://localhost:8000/openapi.json
