-- Phase 1 utility objects: updated_at triggers + reporting views
BEGIN;

-- Generic trigger function to keep updated_at current
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach updated_at trigger to tables that include updated_at
CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_customers_updated_at BEFORE UPDATE ON customers
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_projects_updated_at BEFORE UPDATE ON projects
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_project_phases_updated_at BEFORE UPDATE ON project_phases
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_project_tasks_updated_at BEFORE UPDATE ON project_tasks
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_workers_updated_at BEFORE UPDATE ON workers
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_worker_assignments_updated_at BEFORE UPDATE ON worker_assignments
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_suppliers_updated_at BEFORE UPDATE ON suppliers
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_materials_updated_at BEFORE UPDATE ON materials
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_purchase_requests_updated_at BEFORE UPDATE ON purchase_requests
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_purchase_orders_updated_at BEFORE UPDATE ON purchase_orders
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_invoices_updated_at BEFORE UPDATE ON invoices
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Accounts receivable aging (customer invoices only)
CREATE OR REPLACE VIEW v_ar_aging AS
SELECT
  i.id AS invoice_id,
  i.invoice_number,
  i.customer_id,
  c.name AS customer_name,
  i.issue_date,
  i.due_date,
  i.total_amount,
  COALESCE(SUM(CASE WHEN p.payment_type = 'receipt' THEN p.amount ELSE 0 END), 0) AS amount_received,
  (i.total_amount - COALESCE(SUM(CASE WHEN p.payment_type = 'receipt' THEN p.amount ELSE 0 END), 0)) AS outstanding_amount,
  GREATEST((CURRENT_DATE - i.due_date), 0) AS days_overdue,
  CASE
    WHEN (i.total_amount - COALESCE(SUM(CASE WHEN p.payment_type = 'receipt' THEN p.amount ELSE 0 END), 0)) <= 0 THEN 'paid'
    WHEN GREATEST((CURRENT_DATE - i.due_date), 0) BETWEEN 0 AND 30 THEN '0-30'
    WHEN GREATEST((CURRENT_DATE - i.due_date), 0) BETWEEN 31 AND 60 THEN '31-60'
    WHEN GREATEST((CURRENT_DATE - i.due_date), 0) BETWEEN 61 AND 90 THEN '61-90'
    ELSE '90+'
  END AS aging_bucket
FROM invoices i
JOIN customers c ON c.id = i.customer_id
LEFT JOIN payments p ON p.invoice_id = i.id
GROUP BY i.id, i.invoice_number, i.customer_id, c.name, i.issue_date, i.due_date, i.total_amount;

-- On-hand stock by material
CREATE OR REPLACE VIEW v_material_stock_on_hand AS
SELECT
  m.id AS material_id,
  m.sku,
  m.name,
  m.unit,
  m.reorder_level,
  COALESCE(SUM(CASE WHEN sm.movement_type = 'in' THEN sm.qty WHEN sm.movement_type = 'out' THEN -sm.qty ELSE sm.qty END), 0) AS qty_on_hand,
  CASE
    WHEN COALESCE(SUM(CASE WHEN sm.movement_type = 'in' THEN sm.qty WHEN sm.movement_type = 'out' THEN -sm.qty ELSE sm.qty END), 0) <= m.reorder_level
      THEN TRUE
    ELSE FALSE
  END AS below_reorder_level
FROM materials m
LEFT JOIN stock_movements sm ON sm.material_id = m.id
GROUP BY m.id, m.sku, m.name, m.unit, m.reorder_level;

COMMIT;
