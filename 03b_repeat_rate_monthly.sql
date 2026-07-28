DROP TABLE IF EXISTS monthly_repeat_rate;

CREATE TABLE monthly_repeat_rate AS
WITH first_purchase AS (
  SELECT Customer_ID,
         MIN(STRFTIME('%Y-%m', InvoiceDate)) AS first_month
  FROM clean_transactions
  GROUP BY Customer_ID
),
monthly_customers AS (
  SELECT DISTINCT
         STRFTIME('%Y-%m', ct.InvoiceDate) AS month,
         ct.Customer_ID,
         fp.first_month
  FROM clean_transactions ct
  JOIN first_purchase fp ON ct.Customer_ID = fp.Customer_ID
),
monthly_flagged AS (
  SELECT month, Customer_ID,
         CASE WHEN month = first_month THEN 0 ELSE 1 END AS is_repeat
  FROM monthly_customers
)
SELECT
  month,
  COUNT(*) AS active_customers,
  SUM(is_repeat) AS repeat_customers,
  ROUND(100.0 * SUM(is_repeat) / COUNT(*), 2) AS repeat_rate_pct
FROM monthly_flagged
GROUP BY month
ORDER BY month;
