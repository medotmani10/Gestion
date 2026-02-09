# بدء التنفيذ — نظام إدارة مشاريع البناء

هذا الملف يمثل **البدء الفعلي للتنفيذ** بعد مرحلة صياغة الـ Prompt، ويغطي:
1) الملخص التنفيذي
2) المعمارية التقنية المقترحة
3) ERD أولي عملي (MVP)
4) خطة تنفيذ أول 4 أسابيع كبداية تشغيلية

---

## 1) الملخص التنفيذي

سننفذ النظام على شكل منصة ويب متعددة الوحدات (Modular Monolith في البداية) لتسريع الإطلاق وتقليل التعقيد، مع تصميم يسمح بالتحول لاحقًا إلى Microservices عند الحاجة.

**نطاق MVP (الإصدار الأول):**
- إدارة المشاريع (المراحل، المهام، نسب الإنجاز)
- إدارة العملاء
- الفوترة الأساسية والتحصيل
- حضور العمال اليومي
- المشتريات والمخزون الأساسي
- التقارير المالية الأساسية (مقبوضات/مدفوعات + أعمار الديون)

**الهدف خلال 12 أسبوع:** إطلاق نسخة تشغيلية صالحة لشركة مقاولات متوسطة مع بيانات حقيقية وصلاحيات واضحة ولوحات مؤشرات للإدارة.

---

## 2) المعمارية التقنية المقترحة

## 2.1 المكونات
- **Frontend:** Next.js (App Router) + TypeScript + Tailwind + RTL جاهز.
- **Backend API:** NestJS + TypeScript.
- **Database:** PostgreSQL.
- **Cache/Queue:** Redis (للتنبيهات والمهام غير المتزامنة).
- **Storage:** S3-compatible (للمرفقات: عقود، فواتير، مستندات العمال).
- **Auth:** JWT + Refresh Tokens + RBAC.
- **Observability:** OpenTelemetry + Prometheus/Grafana + Sentry.
- **Docs:** OpenAPI/Swagger تلقائي.

## 2.2 نمط التصميم
- Modular Monolith مع الوحدات التالية:
  - Identity & Access
  - CRM (العملاء)
  - Projects
  - Workforce & Attendance
  - Procurement & Inventory
  - Invoicing
  - Finance
  - Reporting

## 2.3 أهم مبادئ التنفيذ
- كل عملية مالية حساسة تسجل في **Audit Log**.
- استخدام **idempotency keys** في عمليات الدفع والفوترة.
- كل حركة مخزون مرتبطة بمستند مرجعي (PO/GRN/Issue Note).
- كل مصروف/إيراد يمكن ربطه بمركز تكلفة (Project + Phase).

---

## 3) ERD أولي (MVP)

## 3.1 جداول الهوية والصلاحيات

### users
- id (PK)
- full_name
- email (UNIQUE)
- phone
- password_hash
- is_active
- created_at, updated_at

### roles
- id (PK)
- code (UNIQUE) — OWNER, FINANCE_MANAGER, PROJECT_MANAGER, ACCOUNTANT, SITE_SUPERVISOR, HR
- name_ar

### user_roles
- id (PK)
- user_id (FK -> users.id)
- role_id (FK -> roles.id)
- scope_type (global/project)
- scope_id (nullable)

### audit_logs
- id (PK)
- actor_user_id (FK -> users.id)
- action
- entity_type
- entity_id
- payload_json
- created_at

## 3.2 العملاء والمشاريع

### customers
- id (PK)
- name
- phone
- email
- address
- customer_tier
- credit_limit
- created_at, updated_at

### projects
- id (PK)
- customer_id (FK -> customers.id)
- code (UNIQUE)
- name
- location
- contract_value
- start_date
- end_date
- status (planned/in_progress/on_hold/completed/closed)
- created_at, updated_at

### project_phases
- id (PK)
- project_id (FK -> projects.id)
- name
- sequence_no
- planned_budget
- actual_cost
- progress_percent

### project_tasks
- id (PK)
- project_phase_id (FK -> project_phases.id)
- title
- assignee_user_id (FK -> users.id, nullable)
- start_date
- due_date
- status
- progress_percent
- planned_cost
- actual_cost

## 3.3 العمال والحضور

### workers
- id (PK)
- full_name
- national_id
- phone
- labor_type (daily/monthly/hourly)
- base_rate
- hire_date
- status

### worker_assignments
- id (PK)
- worker_id (FK -> workers.id)
- project_id (FK -> projects.id)
- project_phase_id (FK -> project_phases.id, nullable)
- start_date
- end_date (nullable)

### attendance_records
- id (PK)
- worker_id (FK -> workers.id)
- project_id (FK -> projects.id)
- attendance_date
- status (present/absent/leave/late/overtime)
- overtime_hours
- checkin_method (manual/qr/biometric)
- approved_by (FK -> users.id)

## 3.4 المشتريات والمخزون

### suppliers
- id (PK)
- name
- phone
- email
- payment_terms
- rating

### materials
- id (PK)
- sku (UNIQUE)
- name
- unit
- reorder_level
- standard_cost
- is_active

### purchase_requests
- id (PK)
- project_id (FK -> projects.id)
- requested_by (FK -> users.id)
- status (draft/submitted/approved/rejected)
- request_date

### purchase_request_items
- id (PK)
- purchase_request_id (FK -> purchase_requests.id)
- material_id (FK -> materials.id)
- qty
- estimated_unit_cost

### purchase_orders
- id (PK)
- supplier_id (FK -> suppliers.id)
- project_id (FK -> projects.id)
- po_number (UNIQUE)
- order_date
- expected_date
- status (draft/approved/partially_received/received/closed)

### goods_receipts
- id (PK)
- purchase_order_id (FK -> purchase_orders.id)
- receipt_date
- received_by (FK -> users.id)

### stock_movements
- id (PK)
- material_id (FK -> materials.id)
- project_id (FK -> projects.id, nullable)
- movement_type (in/out/adjustment)
- qty
- unit_cost
- reference_type
- reference_id
- moved_at

## 3.5 الفوترة والمالية

### invoices
- id (PK)
- project_id (FK -> projects.id)
- customer_id (FK -> customers.id)
- invoice_number (UNIQUE)
- invoice_type (advance/progress/final/service)
- issue_date
- due_date
- subtotal
- tax_amount
- discount_amount
- total_amount
- status (draft/approved/partially_paid/paid/overdue)

### invoice_items
- id (PK)
- invoice_id (FK -> invoices.id)
- description
- qty
- unit_price
- tax_rate
- line_total

### payments
- id (PK)
- invoice_id (FK -> invoices.id, nullable)
- customer_id (FK -> customers.id, nullable)
- supplier_id (FK -> suppliers.id, nullable)
- payment_type (receipt/disbursement)
- amount
- payment_date
- method (cash/bank/transfer)
- reference_no

### ledger_accounts
- id (PK)
- code (UNIQUE)
- name
- type (asset/liability/equity/revenue/expense)

### journal_entries
- id (PK)
- entry_no (UNIQUE)
- entry_date
- description
- project_id (FK -> projects.id, nullable)

### journal_entry_lines
- id (PK)
- journal_entry_id (FK -> journal_entries.id)
- account_id (FK -> ledger_accounts.id)
- debit
- credit

---

## 4) خطة التنفيذ العملية (أول 4 أسابيع)

## الأسبوع 1
- تأسيس المشروع (Monorepo: frontend + backend + shared types)
- إعداد PostgreSQL + Redis + Docker Compose
- بناء نظام المستخدمين والصلاحيات JWT/RBAC
- إنشاء migrations لأول 8 جداول أساسية (users/roles/customers/projects/phases/tasks/workers/attendance)

## الأسبوع 2
- CRUD كامل: العملاء + المشاريع + مراحل المشروع + المهام
- شاشة Dashboard أولية (عدد المشاريع، نسب الإنجاز، فواتير مستحقة)
- API توثيق تلقائي Swagger

## الأسبوع 3
- وحدة الفوترة الأساسية (invoice + items + statuses)
- تسجيل الدفعات (payments) + تحديث حالة الفاتورة تلقائيًا
- تقرير أعمار الديون (0-30 / 31-60 / 61-90 / 90+)

## الأسبوع 4
- المشتريات والمخزون: PR/PO/GRN + stock movements
- ربط المواد بالمشروع
- تنبيه إعادة الطلب عند تجاوز reorder_level

---

## 5) تعريف جاهزية التسليم (Definition of Done)
- كل endpoint مغطى باختبارات Integration أساسية.
- لا توجد عمليات مالية بدون Audit Log.
- كل شاشة رئيسية تدعم RTL بالكامل.
- توثيق API محدث مع كل إصدار.
- صلاحيات الوصول مفعلة فعليًا وليست شكلية.

---

## 6) الخطوة التالية المباشرة
**الآن نبدأ Sprint-1** عبر إنشاء:
1) مخطط قاعدة البيانات migrations
2) auth module
3) customers/projects module
4) seed للأدوار الأساسية

