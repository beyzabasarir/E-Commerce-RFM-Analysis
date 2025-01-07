-- Step 1: Determine the last invoice date for recency calculation
SELECT MAX(invoicedate) AS max_invoice_date FROM rfm;
-- max_invoice_date is '2011-12-09 12:50:00'

-- Step 2: Recency Calculation
WITH max_dates AS (
  SELECT 
    customer_id, 
    MAX(invoicedate) AS last_purchase_date
  FROM rfm
  WHERE quantity > 0 AND customer_id IS NOT NULL
  GROUP BY customer_id
)
SELECT 
  customer_id,
  last_purchase_date,
  EXTRACT(DAY FROM ('2011-12-09 12:50:00'::DATE - last_purchase_date)) AS recency
FROM max_dates;

-- Step 3: Frequency Calculation
SELECT 
  customer_id,
  COUNT(*) AS frequency
FROM rfm
WHERE quantity > 0 AND customer_id IS NOT NULL
GROUP BY customer_id;

-- Step 4: Monetary Calculation
SELECT 
  customer_id, 
  ROUND(SUM(quantity * unitprice)::NUMERIC, 0) AS monetary
FROM rfm
WHERE quantity > 0 AND customer_id IS NOT NULL
GROUP BY customer_id
HAVING ROUND(SUM(quantity * unitprice)::NUMERIC, 0) BETWEEN 10 AND 10000;

-- Step 5: Combine Recency, Frequency, and Monetary (RFM)
WITH recency AS (
  WITH max_dates AS (
    SELECT 
      customer_id, 
      MAX(invoicedate) AS last_purchase_date
    FROM rfm
    WHERE quantity > 0 AND customer_id IS NOT NULL
    GROUP BY customer_id
  )
  SELECT 
    customer_id,
    EXTRACT(DAY FROM ('2011-12-09 12:50:00'::DATE - last_purchase_date)) AS recency
  FROM max_dates
),
frequency AS (
  SELECT 
    customer_id,
    COUNT(*) AS frequency
  FROM rfm
  WHERE quantity > 0 AND customer_id IS NOT NULL
  GROUP BY customer_id
),
monetary AS (
  SELECT 
    customer_id, 
    ROUND(SUM(quantity * unitprice)::NUMERIC, 0) AS monetary
  FROM rfm
  WHERE quantity > 0 AND customer_id IS NOT NULL
  GROUP BY customer_id
  HAVING ROUND(SUM(quantity * unitprice)::NUMERIC, 0) BETWEEN 10 AND 10000
)
SELECT 
  r.customer_id,
  r.recency,
  f.frequency,
  m.monetary
FROM recency r
INNER JOIN frequency f ON r.customer_id = f.customer_id
INNER JOIN monetary m ON r.customer_id = m.customer_id;

-- Step 6: RFM Scoring
WITH recency AS (
  WITH max_dates AS (
    SELECT 
      customer_id, 
      MAX(invoicedate) AS last_purchase_date
    FROM rfm
    WHERE quantity > 0 AND customer_id IS NOT NULL
    GROUP BY customer_id
  )
  SELECT 
    customer_id,
    EXTRACT(DAY FROM ('2011-12-09 12:50:00'::DATE - last_purchase_date)) AS recency
  FROM max_dates
),
frequency AS (
  SELECT 
    customer_id,
    COUNT(*) AS frequency
  FROM rfm
  WHERE quantity > 0 AND customer_id IS NOT NULL
  GROUP BY customer_id
),
monetary AS (
  SELECT 
    customer_id, 
    ROUND(SUM(quantity * unitprice)::NUMERIC, 0) AS monetary
  FROM rfm
  WHERE quantity > 0 AND customer_id IS NOT NULL
  GROUP BY customer_id
  HAVING ROUND(SUM(quantity * unitprice)::NUMERIC, 0) BETWEEN 10 AND 10000
)
SELECT 
  r.customer_id,
  NTILE(5) OVER (ORDER BY r.recency DESC) AS recency_score,
  CASE
    WHEN f.frequency >= 1 AND f.frequency <= 10 THEN 1
    WHEN f.frequency > 10 AND f.frequency <= 50 THEN 2
    WHEN f.frequency > 50 AND f.frequency <= 200 THEN 3
    WHEN f.frequency > 200 AND f.frequency <= 1000 THEN 4
    ELSE 5
  END AS frequency_score,
  NTILE(5) OVER (ORDER BY m.monetary ASC) AS monetary_score
FROM recency r
INNER JOIN frequency f ON r.customer_id = f.customer_id
INNER JOIN monetary m ON r.customer_id = m.customer_id
ORDER BY r.customer_id;

-- Step 7: RFM Score Distribution
SELECT rfm_score, COUNT(customer_id) 
FROM (
  SELECT 
    customer_id, 
    recency_score::TEXT || '-' || frequency_score::TEXT || '-' || monetary_score::TEXT AS rfm_score
  FROM (
    WITH recency AS (
      WITH max_dates AS (
        SELECT 
          customer_id, 
          MAX(invoicedate) AS last_purchase_date
        FROM rfm
        WHERE quantity > 0 AND customer_id IS NOT NULL
        GROUP BY customer_id
      )
      SELECT 
        customer_id,
        EXTRACT(DAY FROM ('2011-12-09 12:50:00'::DATE - last_purchase_date)) AS recency
      FROM max_dates
    ),
    frequency AS (
      SELECT 
        customer_id,
        COUNT(*) AS frequency
      FROM rfm
      WHERE quantity > 0 AND customer_id IS NOT NULL
      GROUP BY customer_id
    ),
    monetary AS (
      SELECT 
        customer_id, 
        ROUND(SUM(quantity * unitprice)::NUMERIC, 0) AS monetary
      FROM rfm
      WHERE quantity > 0 AND customer_id IS NOT NULL
      GROUP BY customer_id
      HAVING ROUND(SUM(quantity * unitprice)::NUMERIC, 0) BETWEEN 10 AND 10000
    )
    SELECT 
      r.customer_id,
      NTILE(5) OVER (ORDER BY r.recency DESC) AS recency_score,
      CASE
        WHEN f.frequency >= 1 AND f.frequency <= 10 THEN 1
        WHEN f.frequency > 10 AND f.frequency <= 50 THEN 2
        WHEN f.frequency > 50 AND f.frequency <= 200 THEN 3
        WHEN f.frequency > 200 AND f.frequency <= 1000 THEN 4
        ELSE 5
      END AS frequency_score,
      NTILE(5) OVER (ORDER BY m.monetary ASC) AS monetary_score
    FROM recency r
    INNER JOIN frequency f ON r.customer_id = f.customer_id
    INNER JOIN monetary m ON r.customer_id = m.customer_id
  ) AS rfm
) AS rfm_scores
GROUP BY rfm_score
ORDER BY rfm_score;

-- Step 8 : Segmentation

WITH recency AS (
  WITH max_dates AS (
    SELECT 
      customer_id, 
      MAX(invoicedate) AS last_purchase_date
    FROM rfm
    WHERE quantity > 0 AND customer_id IS NOT NULL
    GROUP BY customer_id
  )
  SELECT 
    customer_id,
    EXTRACT(DAY FROM ('2011-12-09 12:50:00'::DATE - last_purchase_date)) AS recency
  FROM max_dates
),
frequency AS (
  SELECT 
    customer_id,
    COUNT(*) AS frequency
  FROM rfm
  WHERE quantity > 0 AND customer_id IS NOT NULL
  GROUP BY customer_id
),
monetary AS (
  SELECT 
    customer_id, 
    ROUND(SUM(quantity * unitprice)::NUMERIC, 0) AS monetary
  FROM rfm
  WHERE quantity > 0 AND customer_id IS NOT NULL
  GROUP BY customer_id
  HAVING ROUND(SUM(quantity * unitprice)::NUMERIC, 0) BETWEEN 10 AND 10000
)
-- Segmenting the customers based on RFM scores
SELECT 
  Segment,
  COUNT(customer_id) AS customer_count
FROM (
  SELECT 
    customer_id,
    recency_score::TEXT || '-' || frequency_score::TEXT || '-' || monetary_score::TEXT AS rfm_score,
    CASE
      WHEN recency_score = 5 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'High-Value Customers'
      WHEN recency_score >= 4 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'Loyal Customers'
      WHEN recency_score <= 3 AND frequency_score >= 2 AND monetary_score >= 2 THEN 'At-Risk Customers'
      ELSE 'Low-Value Customers'
    END AS Segment
  FROM (
    SELECT 
      r.customer_id,
      NTILE(5) OVER (ORDER BY r.recency DESC) AS recency_score,
      CASE
        WHEN f.frequency >= 1 AND f.frequency <= 10 THEN 1
        WHEN f.frequency > 10 AND f.frequency <= 50 THEN 2
        WHEN f.frequency > 50 AND f.frequency <= 200 THEN 3
        WHEN f.frequency > 200 AND f.frequency <= 1000 THEN 4
        ELSE 5
      END AS frequency_score,
      NTILE(5) OVER (ORDER BY m.monetary ASC) AS monetary_score
    FROM recency r
    INNER JOIN frequency f ON r.customer_id = f.customer_id
    INNER JOIN monetary m ON r.customer_id = m.customer_id
  ) AS rfm_scores
) AS segmented_customers
GROUP BY Segment
ORDER BY customer_count DESC;