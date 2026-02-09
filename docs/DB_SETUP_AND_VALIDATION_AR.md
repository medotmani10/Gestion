# تشغيل قاعدة البيانات والتحقق (Phase-1)

## المتطلبات
- Docker + Docker Compose
- psql

## التشغيل السريع
```bash
./scripts/run_db_setup.sh
```

## استعلامات تحقق سريعة
```sql
-- تحقق من الأدوار
SELECT code, name_ar FROM roles ORDER BY code;

-- تحقق من views
SELECT * FROM v_ar_aging LIMIT 10;
SELECT * FROM v_material_stock_on_hand LIMIT 10;
```

## ملاحظات
- ملف `002_phase1_views_and_triggers.sql` يضيف:
  - Trigger موحّد لتحديث `updated_at`.
  - View لتقرير أعمار الذمم المدينة `v_ar_aging`.
  - View للمخزون الحالي `v_material_stock_on_hand` مع تنبيه إعادة الطلب.
