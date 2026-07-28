-- ============================================================
-- ChurnShield — Step 3a: Core KPIs
-- ============================================================

-- ── 3a-1: Total Revenue ──────────────────────────────────────
SELECT 'TOTAL REVENUE', ROUND(SUM(revenue), 2) FROM clean_transactions;

-- ── 3a-2: Revenue by Month ───────────────────────────────────
DROP TABLE IF EXISTS kpis_monthly;

CREATE TABLE kpis_monthly AS
WITH monthly AS (
  SELECT
    STRFTIME('%Y-%m', InvoiceDate) AS month,
    ROUND(SUM(revenue), 2)        AS total_revenue,
    COUNT(DISTINCT Customer_ID)   AS active_customers,
    COUNT(DISTINCT Invoice)       AS total_orders,
    ROUND(SUM(revenue) / COUNT(DISTINCT Invoice), 2) AS avg_order_value
  FROM clean_transactions
  GROUP BY STRFTIME('%Y-%m', InvoiceDate)
),
with_growth AS (
  SELECT
    month,
    total_revenue,
    active_customers,
    total_orders,
    avg_order_value,
    LAG(total_revenue) OVER (ORDER BY month) AS prev_month_revenue,
    ROUND(
      (total_revenue - LAG(total_revenue) OVER (ORDER BY month))
      / LAG(total_revenue) OVER (ORDER BY month) * 100.0,
      2
    ) AS mom_revenue_growth_pct
  FROM monthly
)
SELECT * FROM with_growth
ORDER BY month;

SELECT * FROM kpis_monthly;
