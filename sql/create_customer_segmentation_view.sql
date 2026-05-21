-- SQL View to calculate Customer Segmentation (RFM model) in Supabase.
-- Run this query in the Supabase SQL Editor.

CREATE OR REPLACE VIEW view_customer_segmentation AS
WITH customer_stats AS (
  SELECT
    TRIM(customer) AS name,
    COALESCE(SUM(net_sales), 0) AS ltv,
    COALESCE(SUM(qty), 0) AS freq_qty,
    COUNT(DISTINCT trans_no) AS freq_invoice,
    MIN(transaction_date)::text AS first_visit,
    MAX(transaction_date)::text AS last_visit,
    (CURRENT_DATE - MAX(transaction_date)::date) AS recency_days
  FROM clean_master
  WHERE customer IS NOT NULL 
    AND TRIM(customer) != ''
    AND LOWER(TRIM(customer)) NOT IN ('customer', 'n/a', '-', 'walk in', 'walkin', 'tamu', 'guest')
  GROUP BY TRIM(customer)
)
SELECT
  name,
  ltv,
  freq_qty,
  freq_invoice,
  recency_days,
  first_visit,
  last_visit,
  CASE
    WHEN recency_days > 730 OR recency_days IS NULL THEN 'Inactive'
    WHEN ltv > 1350000000 THEN 'Top'
    WHEN ltv >= 200000000 THEN 'Elite'
    WHEN ltv >= 50000000 THEN 'High Potential'
    WHEN ltv > 0 THEN 'Potential'
    ELSE 'Prospect'
  END AS segment
FROM customer_stats;
