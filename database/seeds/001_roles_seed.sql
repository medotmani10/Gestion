-- Seed core RBAC roles
INSERT INTO roles (code, name_ar)
VALUES
  ('OWNER', 'مالك النظام'),
  ('FINANCE_MANAGER', 'مدير مالي'),
  ('PROJECT_MANAGER', 'مدير مشروع'),
  ('ACCOUNTANT', 'محاسب'),
  ('SITE_SUPERVISOR', 'مشرف موقع'),
  ('HR', 'موظف موارد بشرية')
ON CONFLICT (code) DO NOTHING;
