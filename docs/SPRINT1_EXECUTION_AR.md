# Sprint-1 التنفيذي (جاهز للتطبيق)

## الهدف
بناء نواة عاملة للنظام خلال Sprint-1 (أسبوعين) تشمل:
- Auth + RBAC
- Customers + Projects + Phases + Tasks
- Workers + Attendance
- إعداد قاعدة البيانات الأساسية

## Backlog قابل للتنفيذ

1. **DB Foundation**
   - تطبيق migration: `database/migrations/001_init_phase1.sql`
   - تطبيق seed: `database/seeds/001_roles_seed.sql`
   - قبول: نجاح إنشاء كل الجداول بدون أخطاء.

2. **Auth Module**
   - تسجيل الدخول JWT + Refresh Token
   - Middleware للتحقق من الدور
   - قبول: endpoint محمي يرفض/يقبل حسب الدور.

3. **Customers API**
   - CRUD العملاء
   - قبول: إنشاء + تعديل + استرجاع + حذف منطقي.

4. **Projects API**
   - CRUD المشاريع
   - إدارة مراحل المشروع والمهام
   - قبول: مشروع واحد يحتوي مراحل ومهام مع نسب إنجاز.

5. **Workers & Attendance API**
   - CRUD العمال
   - تسجيل حضور يومي
   - قبول: منع تكرار سجل حضور لنفس العامل/اليوم/المشروع.

## أوامر تحقق مقترحة
- `psql "$DATABASE_URL" -f database/migrations/001_init_phase1.sql`
- `psql "$DATABASE_URL" -f database/seeds/001_roles_seed.sql`

## ملاحظات
- أي عملية مالية في الـ Sprint القادم يجب ربطها بـ `audit_logs`.
- يفضّل بدء كتابة اختبارات Integration مع أول Endpoint.
