# Первая покупка
CREATE OR REPLACE VIEW `mytestproject1-477512.clean_retail_data.customer_first_purchase` AS
SELECT
  customerid,
  MIN(DATE(invoicedate)) AS first_purchase_date,
  FORMAT_DATE('%Y-%m', MIN(DATE(invoicedate))) AS cohort_month
 FROM `mytestproject1-477512.clean_retail_data.clean_retail`
 GROUP BY customerid

# Запрос когортного анализа
WITH customer_first_purchase AS (
  SELECT
  customerid,
  MIN(invoicedate) AS first_purchase_date,
  FORMAT_DATE('%Y-%m', MIN(invoicedate)) AS cohort_month
  FROM mytestproject1-477512.clean_retail_data.clean_retail
  GROUP BY customerid
)
SELECT
 cfp.cohort_month,
    FORMAT_DATE('%Y-%m', rd.invoicedate) AS purchase_month,
    COUNT(DISTINCT rd.customerid) AS customers
FROM `mytestproject1-477512.clean_retail_data.clean_retail` rd
JOIN customer_first_purchase cfp
    ON rd.customerid = cfp.customerid
GROUP BY cfp.cohort_month, purchase_month
ORDER BY cfp.cohort_month, purchase_month;

# Retention по месяцам
WITH
customer_first_purchase AS (
  SELECT
    customerid,
    MIN(invoicedate) AS first_purchase_date,
    FORMAT_DATE('%Y-%m', MIN(invoicedate)) AS cohort_month
FROM `mytestproject1-477512.clean_retail_data.clean_retail`
GROUP BY customerid
),
cohort_data AS (
   SELECT
    cfp.cohort_month,
    rd.customerid,
   DATE_DIFF(
    DATE(rd.invoicedate),
    DATE(cfp.first_purchase_date),
    MONTH
    ) AS months_since_first
  FROM `mytestproject1-477512.clean_retail_data.clean_retail` rd
  JOIN customer_first_purchase cfp
    ON rd.customerid = cfp.customerid
),
cohort_size AS (
  SELECT
   cohort_month,
    COUNT(DISTINCT customerid) AS cohort_customers
  FROM customer_first_purchase
  GROUP BY cohort_month
)
SELECT
  cd.cohort_month,
  cd.months_since_first,
  COUNT(DISTINCT cd.customerid) AS customers,
  cs.cohort_customers,
  ROUND(COUNT(DISTINCT cd.customerid) * 100 / cs.cohort_customers, 2) AS retention_rate
FROM cohort_data cd
JOIN cohort_size cs
ON cd.cohort_month=cs.cohort_month
WHERE cd.months_since_first BETWEEN 0 AND 12
GROUP BY
cd.cohort_month,
cd.months_since_first,
cs.cohort_customers
ORDER BY
cd.cohort_month,
cd.months_since_first;

# LTV
WITH
customer_first_purchase AS (
SELECT
  customerid,
  FORMAT_DATE('%Y-%m', MIN(CAST(invoicedate AS DATE))) AS cohort_month
FROM `mytestproject1-477512.clean_retail_data.clean_retail`
GROUP BY customerid
),
customer_revenue AS (
  SELECT
    customerid,
    SUM(quantity * unitprice) AS total_revenue,
  FROM `mytestproject1-477512.clean_retail_data.clean_retail`
  GROUP BY customerid
)
SELECT
  cfp.cohort_month,
  COUNT(DISTINCT cfp.customerid) as customers,
  ROUND(SUM(cr.total_revenue), 2) AS total_revenue,
  ROUND(AVG(cr.total_revenue),2) AS avg_ltv
  FROM customer_first_purchase cfp
JOIN customer_revenue cr ON
cfp.customerid=cr.customerid
GROUP BY
cfp.cohort_month
ORDER BY
cfp.cohort_month
