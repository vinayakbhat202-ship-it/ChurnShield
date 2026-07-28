-- ============================================================
-- ChurnShield — Step 2 Final: Materialise clean_transactions
-- All filters applied in one CTE chain. Revenue column added.
-- raw_transactions is never touched.
-- ============================================================

DROP TABLE IF EXISTS clean_transactions;

CREATE TABLE clean_transactions AS
SELECT *,
       ROUND(CAST(Quantity AS REAL) * CAST(Price AS REAL), 2) AS revenue
FROM (
  SELECT *,
         ROW_NUMBER() OVER (
           PARTITION BY Invoice, StockCode, Quantity, InvoiceDate, Customer_ID
           ORDER BY rowid
         ) AS rn
  FROM raw_transactions
  WHERE
    -- 2.1 Remove cancellations
    Invoice NOT LIKE 'C%'
    -- 2.2 Remove missing Customer ID
    AND (Customer_ID IS NOT NULL AND TRIM(Customer_ID) != '')
    -- 2.3 Remove non-product StockCodes
    AND StockCode NOT IN ('POST','M','DOT','BANK CHARGES','AMAZONFEE',
                          'TEST001','TEST002','PADS','S','D','C2','m',
                          'CRUK','B','SP1002','DCGS0076','DCGSSBOY','DCGSSGIRL')
    AND StockCode NOT LIKE 'TEST%'
    AND StockCode NOT LIKE 'gift%'
    -- 2.3 Remove invalid Price and Quantity
    AND CAST(Price AS REAL) > 0
    AND CAST(Quantity AS INTEGER) > 0
)
-- 2.4 Keep only first occurrence of each duplicate group
WHERE rn = 1;

-- Verify final count
SELECT 'clean_transactions final row count:', COUNT(*) FROM clean_transactions;
SELECT 'Min InvoiceDate:', MIN(InvoiceDate), 'Max InvoiceDate:', MAX(InvoiceDate)
FROM clean_transactions;
