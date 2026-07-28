-- ============================================================
-- ChurnShield — Step 3e: Pareto Analysis (80/20 Rule)
-- Uses cumulative SUM window function.
-- WHY: Pareto analysis quantifies revenue concentration — the
-- "X% of customers generate 80% of revenue" headline number
-- is a standard C-suite metric and interview talking point.
-- ============================================================
DROP TABLE IF EXISTS pareto_analysis;

CREATE TABLE pareto_analysis AS
WITH customer_rev AS (
  SELECT Customer_ID,
         ROUND(SUM(revenue), 2) AS customer_revenue
  FROM clean_transactions
  GROUP BY Customer_ID
),
ranked AS (
  SELECT *,
    RANK() OVER (ORDER BY customer_revenue DESC) AS revenue_rank,
    SUM(customer_revenue) OVER (ORDER BY customer_revenue DESC
                                 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                                ) AS cumulative_revenue,
    SUM(customer_revenue) OVER () AS grand_total
  FROM customer_rev
),
pct AS (
  SELECT *,
    ROUND(cumulative_revenue / grand_total * 100.0, 4) AS cumulative_pct,
    ROUND(CAST(revenue_rank AS REAL) / COUNT(*) OVER () * 100.0, 4) AS customer_pct
  FROM ranked
)
SELECT * FROM pct ORDER BY revenue_rank;

-- Find the Pareto crossing point (where cumulative hits 80%)
SELECT 'PARETO_CROSSING' as metric,
       MIN(customer_pct) as pct_of_customers_needed,
       MIN(revenue_rank) as customers_needed,
       COUNT(*) OVER () as total_customers
FROM pareto_analysis
WHERE cumulative_pct >= 80.0
LIMIT 1;

SELECT 
  (SELECT COUNT(*) FROM pareto_analysis WHERE cumulative_pct <= 80.0) as customers_generating_80pct,
  COUNT(*) as total_customers,
  ROUND(100.0 * (SELECT COUNT(*) FROM pareto_analysis WHERE cumulative_pct <= 80.0) / COUNT(*), 2) as pct_of_customers
FROM pareto_analysis;
