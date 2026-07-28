-- ============================================================
-- ChurnShield — Step 2: Full Cleaning Pipeline
-- All cleaning in SQL. raw_transactions is never mutated.
-- Each step builds on the previous CTE/table.
-- ============================================================

-- ── STEP 2.1: Cancellation removal ──────────────────────────
-- WHY DROP: Cancellations reverse a prior sale. Netting them
-- requires matching Invoice-to-C-Invoice pairs, which is
-- unreliable without a FK in this dataset. For revenue analytics
-- and RFM, we only want completed purchase behaviour.
SELECT 'CANCELLATIONS' as step,
       COUNT(*) as removed_count,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM raw_transactions), 2) as pct_of_total
FROM raw_transactions
WHERE Invoice LIKE 'C%';

-- ── STEP 2.2: Missing Customer ID count ─────────────────────
SELECT 'MISSING_CUSTOMER_ID' as step,
       COUNT(*) as removed_count,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM raw_transactions), 2) as pct_of_total
FROM raw_transactions
WHERE Customer_ID IS NULL OR TRIM(Customer_ID) = '';

-- ── STEP 2.3a: Suspicious StockCodes — see before dropping ──
SELECT StockCode,
       COUNT(*) as frequency,
       MIN(Description) as sample_description
FROM raw_transactions
WHERE StockCode IN ('POST','M','DOT','BANK CHARGES','AMAZONFEE',
                    'TEST001','TEST002','PADS','S','gift_0001_40',
                    'gift_0001_10','gift_0001_20','gift_0001_30',
                    'DCGS0076','DCGSSBOY','DCGSSGIRL','D','C2','m',
                    'CRUK','SP1002','B')
   OR StockCode LIKE 'TEST%'
   OR StockCode LIKE 'gift%'
   OR (CAST(Price AS REAL) <= 0)
   OR (CAST(Quantity AS INTEGER) <= 0)
GROUP BY StockCode
ORDER BY frequency DESC;

-- ── STEP 2.3b: Price <= 0 count ─────────────────────────────
SELECT 'PRICE_LEQ_0' as step, COUNT(*) as count
FROM raw_transactions
WHERE CAST(Price AS REAL) <= 0;

-- ── STEP 2.3c: Quantity <= 0 (non-cancellations) ────────────
SELECT 'QUANTITY_LEQ_0_NON_CANCEL' as step, COUNT(*) as count
FROM raw_transactions
WHERE CAST(Quantity AS INTEGER) <= 0
  AND Invoice NOT LIKE 'C%';

-- ── STEP 2.4: Duplicate detection via ROW_NUMBER() ───────────
-- WHY ROW_NUMBER not DISTINCT: DISTINCT hides the duplicate
-- count. ROW_NUMBER lets us audit exactly how many dupes exist
-- and which rows they are, giving a traceable cleaning log.
SELECT 'EXACT_DUPLICATES' as step, COUNT(*) - COUNT(DISTINCT row_num) as dupes
FROM (
  SELECT ROW_NUMBER() OVER (
    PARTITION BY Invoice, StockCode, Quantity, InvoiceDate, Customer_ID
    ORDER BY rowid
  ) as row_num
  FROM raw_transactions
  WHERE Invoice NOT LIKE 'C%'
    AND (Customer_ID IS NOT NULL AND TRIM(Customer_ID) != '')
    AND StockCode NOT IN ('POST','M','DOT','BANK CHARGES','AMAZONFEE',
                          'TEST001','TEST002','PADS','S','D','C2','m',
                          'CRUK','B')
    AND StockCode NOT LIKE 'TEST%'
    AND StockCode NOT LIKE 'gift%'
    AND CAST(Price AS REAL) > 0
    AND CAST(Quantity AS INTEGER) > 0
);
