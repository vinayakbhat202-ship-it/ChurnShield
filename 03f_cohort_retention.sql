-- ============================================================
-- ChurnShield — Step 3f: Cohort Retention Analysis
-- Cohort = calendar month of a customer's FIRST purchase.
-- WHY calendar month (not exact date):
-- Daily cohorts create too many tiny cohorts with noisy retention.
-- Monthly cohorts are the industry standard — large enough to be
-- statistically stable, granular enough to detect seasonal effects.
-- ============================================================
DROP TABLE IF EXISTS cohort_retention;

CREATE TABLE cohort_retention AS
WITH first_purchase AS (
  SELECT Customer_ID,
         STRFTIME('%Y-%m', MIN(InvoiceDate)) AS cohort_month
  FROM clean_transactions
  GROUP BY Customer_ID
),
customer_activity AS (
  SELECT
    fp.Customer_ID,
    fp.cohort_month,
    STRFTIME('%Y-%m', ct.InvoiceDate) AS activity_month,
    -- Month offset: 0 = acquisition month, 1 = one month later, etc.
    CAST(
      (STRFTIME('%Y', ct.InvoiceDate) - STRFTIME('%Y', fp.cohort_month || '-01')) * 12
      + (STRFTIME('%m', ct.InvoiceDate) - STRFTIME('%m', fp.cohort_month || '-01'))
    AS INTEGER) AS month_offset
  FROM clean_transactions ct
  JOIN first_purchase fp ON ct.Customer_ID = fp.Customer_ID
),
cohort_sizes AS (
  SELECT cohort_month, COUNT(DISTINCT Customer_ID) AS cohort_size
  FROM first_purchase
  GROUP BY cohort_month
),
retention_raw AS (
  SELECT
    ca.cohort_month,
    ca.month_offset,
    COUNT(DISTINCT ca.Customer_ID) AS customers_active
  FROM customer_activity ca
  GROUP BY ca.cohort_month, ca.month_offset
)
SELECT
  rr.cohort_month,
  rr.month_offset,
  cs.cohort_size,
  rr.customers_active,
  ROUND(100.0 * rr.customers_active / cs.cohort_size, 2) AS retention_pct
FROM retention_raw rr
JOIN cohort_sizes cs ON rr.cohort_month = cs.cohort_month
ORDER BY rr.cohort_month, rr.month_offset;

SELECT COUNT(*) as cohort_rows FROM cohort_retention;
SELECT * FROM cohort_retention LIMIT 30;
