-- ============================================================
-- ChurnShield — Step 3b: Repeat Rate
-- WHY: Repeat rate = % of customers who purchased more than once.
-- Key loyalty metric that distinguishes one-time buyers from
-- returning customers. Directly informs retention strategy.
-- ============================================================
SELECT 'REPEAT_RATE_PCT',
  ROUND(
    100.0 * SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END)
    / COUNT(DISTINCT Customer_ID),
    2
  ) AS repeat_rate_pct
FROM (
  SELECT Customer_ID, COUNT(DISTINCT Invoice) AS order_count
  FROM clean_transactions
  GROUP BY Customer_ID
);
