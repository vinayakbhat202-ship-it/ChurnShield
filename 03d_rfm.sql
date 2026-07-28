-- ============================================================
-- ChurnShield — Step 3d: RFM Segmentation
-- Snapshot date = MAX(InvoiceDate) + 1 day
-- WHY +1 day: Prevents the most recent customer from having
-- Recency = 0, keeping NTILE() scores meaningful.
--
-- WHY NTILE(5) over hand-picked thresholds:
-- NTILE adapts to the actual data distribution. Hard thresholds
-- (e.g., Recency < 30 days = 5) are business-rule assumptions
-- that may not fit this dataset's purchase cadence. NTILE ensures
-- equal-sized buckets by actual data, not by assumption.
--
-- RECENCY DIRECTION: Lower days = more recent = HIGHER score.
-- We flip via (6 - NTILE()) so NTILE rank 1 (lowest recency)
-- maps to score 5 (best). All other metrics: higher = higher score.
-- ============================================================
DROP TABLE IF EXISTS rfm_raw;
DROP TABLE IF EXISTS rfm_segments;

-- Snapshot date
CREATE TABLE rfm_raw AS
WITH snapshot AS (
  SELECT DATE(MAX(InvoiceDate), '+1 day') AS snap_date
  FROM clean_transactions
),
customer_rfm AS (
  SELECT
    c.Customer_ID,
    CAST(JULIANDAY((SELECT snap_date FROM snapshot)) -
         JULIANDAY(MAX(c.InvoiceDate)) AS INTEGER)  AS recency_days,
    COUNT(DISTINCT c.Invoice)                        AS frequency,
    ROUND(SUM(c.revenue), 2)                         AS monetary
  FROM clean_transactions c
  GROUP BY c.Customer_ID
)
SELECT * FROM customer_rfm;

-- Score with NTILE(5)
CREATE TABLE rfm_segments AS
WITH scored AS (
  SELECT *,
    -- RECENCY: lower recency_days = more recent = higher score.
    -- NTILE(ORDER BY ASC) gives rank 1 to smallest days (most recent).
    -- 6 - rank maps that to score 5 (best). Rank 5 (oldest) → score 1 (worst).
    6 - NTILE(5) OVER (ORDER BY recency_days ASC)   AS r_score,
    NTILE(5) OVER (ORDER BY frequency ASC)           AS f_score,
    NTILE(5) OVER (ORDER BY monetary ASC)            AS m_score
  FROM rfm_raw
),
segmented AS (
  SELECT *,
    r_score + f_score + m_score AS rfm_total,
    CASE
      WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4  THEN 'Champions'
      WHEN r_score >= 3 AND f_score >= 3                   THEN 'Loyal'
      WHEN r_score >= 4 AND f_score <= 2                   THEN 'New'
      WHEN r_score <= 2 AND m_score >= 4                   THEN 'At Risk - High Value'
      WHEN r_score <= 2 AND f_score >= 3                   THEN 'At Risk - High Value'
      WHEN r_score = 1 AND f_score <= 2 AND m_score <= 2   THEN 'Churned'
      ELSE 'Needs Attention'
    END AS segment
  FROM scored
)
SELECT * FROM segmented;

-- ── Prove recency direction is correct (sample) ──────────────
SELECT 'DIRECTION CHECK — lowest recency_days should have r_score=5:' as note;
SELECT Customer_ID, recency_days, r_score, f_score, m_score, segment
FROM rfm_segments
ORDER BY recency_days ASC
LIMIT 5;

SELECT 'DIRECTION CHECK — highest recency_days should have r_score=1:' as note;
SELECT Customer_ID, recency_days, r_score, f_score, m_score, segment
FROM rfm_segments
ORDER BY recency_days DESC
LIMIT 5;

-- ── Segment summary ───────────────────────────────────────────
SELECT segment,
       COUNT(*) AS customer_count,
       ROUND(SUM(monetary), 2) AS total_revenue,
       ROUND(AVG(monetary), 2) AS avg_revenue_per_customer,
       ROUND(AVG(recency_days), 1) AS avg_recency_days
FROM rfm_segments
GROUP BY segment
ORDER BY total_revenue DESC;
