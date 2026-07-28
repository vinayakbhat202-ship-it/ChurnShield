-- ============================================================
-- ChurnShield — Step 3c: Top 10 Products by Revenue per Month
-- Uses RANK() not ROW_NUMBER() → ties handled correctly.
-- WHY RANK: Two products with equal revenue in a month should
-- share the same rank position, not have one arbitrarily ranked.
-- ============================================================
DROP TABLE IF EXISTS top_products;

CREATE TABLE top_products AS
WITH monthly_product AS (
  SELECT
    STRFTIME('%Y-%m', InvoiceDate) AS month,
    StockCode,
    MIN(Description) AS description,
    ROUND(SUM(revenue), 2) AS product_revenue,
    SUM(CAST(Quantity AS INTEGER)) AS units_sold
  FROM clean_transactions
  GROUP BY STRFTIME('%Y-%m', InvoiceDate), StockCode
),
ranked AS (
  SELECT *,
    RANK() OVER (PARTITION BY month ORDER BY product_revenue DESC) AS revenue_rank
  FROM monthly_product
)
SELECT * FROM ranked WHERE revenue_rank <= 10
ORDER BY month, revenue_rank;

SELECT COUNT(*) as rows_in_top_products FROM top_products;
SELECT * FROM top_products LIMIT 20;
