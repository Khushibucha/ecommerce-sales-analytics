/* =====================================================================
   E-COMMERCE SALES ANALYSIS
   =====================================================================
   Dataset : UCI "Online Retail" (UK online gift shop), Dec 2010 - Dec 2011
   Source  : data/raw/Online Retail.xlsx   (541,909 original rows)
   Cleaned : data/processed/cleaned_sales.csv  (530,104 rows)
             produced by scripts/data_cleaning.py
   Database: ecommerce_db   (NOT "ecommerce" - that database doesn't exist)
   Table   : sales

   PIPELINE
     1. Excel  -> scripts/data_cleaning.py -> cleaned_sales.csv
     2. CREATE TABLE (Section 1 below)
     3. Load the CSV with LOAD DATA (Section 2 below)
     4. Validate the load (Section 3)
     5. Business analysis (Sections 4-6)

   WHAT THE CLEANING SCRIPT ALREADY DID (so the SQL doesn't need to):
     - Removed cancelled invoices (invoice numbers starting with "C")
     - Removed rows with quantity <= 0 or unitprice <= 0
     - Removed rows with no date or no description
     - Added revenue = quantity * unitprice (rounded to 2 decimals)
     - Added duplicate_flag = 1 for exact repeat rows (flagged, NOT deleted)
     - Wrote True/False as 1/0 so MySQL TINYINT columns accept them

   THINGS TO REMEMBER ABOUT THIS DATA
     - ~132K rows have NO customer ID (guest checkouts). They are stored as
       NULL. Include them for revenue totals, exclude them for any
       customer-level analysis.
     - 5,228 rows are flagged as possible duplicates. They are still in the
       table, so revenue totals include them. Decide whether to filter with
       WHERE duplicate_flag = 0 depending on the question.
     - 4 rows have a unitprice of 0.001 in the CSV ("PADS TO MATCH ALL
       CUSHIONS" and "Bank Charges"). DECIMAL(10,2) stores them as 0.00.
       They are not real sales, so you may want to exclude them from
       product/price analysis.
     - Some stockcodes are not products (POST, DOT, M, BANK CHARGES, PADS).
       Keep this in mind for "top product" queries.
     - The last month (Dec 2011) only runs to the 9th, so it looks low in
       monthly trends. That's a partial month, not a sales drop.
   ===================================================================== */

USE ecommerce_db;


/* =====================================================================
   SECTION 1 - CREATE THE TABLE
   =====================================================================
   WARNING: DROP TABLE deletes the table AND all its data. Only run this
   block when rebuilding from scratch, then reload the CSV (Section 2).

   Why these data types:
     invoiceno   VARCHAR - looks numeric, but the original data has
                           letters (e.g. "C536379" = cancelled), so it's text
     stockcode   VARCHAR - mix of numbers and letters (e.g. "85123A")
     description TEXT    - product names vary in length
     invoicedate DATETIME- needed for month / weekday / hour analysis
     unitprice   DECIMAL - DECIMAL, not FLOAT, so money adds up exactly
     customerid  VARCHAR - an ID, not a number we do maths on; NULL allowed
     is_cancelled,
     duplicate_flag TINYINT(1) - MySQL's way of storing true/false (1/0)
   ===================================================================== */

DROP TABLE IF EXISTS sales;

CREATE TABLE sales (
    invoiceno VARCHAR(20),
    stockcode VARCHAR(30),
    description TEXT,
    quantity INT,
    invoicedate DATETIME,
    unitprice DECIMAL(10,2),
    customerid VARCHAR(20),
    country VARCHAR(100),
    is_cancelled TINYINT(1),
    revenue DECIMAL(12,2),
    duplicate_flag TINYINT(1)
);


/* =====================================================================
   SECTION 2 - LOAD THE CSV  (kept commented out - run from the terminal)
   =====================================================================
   LESSON LEARNED: the MySQL Workbench "Table Data Import Wizard" stopped
   silently after 37,402 rows. It hit the first "£" character
   ("Gift Voucher £40.00") and only Dec 2010 data got loaded. It also
   rejected "True"/"False" text for the TINYINT columns.

   This command loaded all 530,104 rows in seconds. Run it from the
   project folder:

     mysql --local-infile=1 ecommerce_db

   then paste:

   LOAD DATA LOCAL INFILE 'data/processed/cleaned_sales.csv'
   INTO TABLE sales
   CHARACTER SET utf8mb4                       -- reads "£" correctly
   FIELDS TERMINATED BY ','
       OPTIONALLY ENCLOSED BY '"'              -- keeps "AIRLINE LOUNGE,METAL SIGN" as one value
   LINES TERMINATED BY '\n'
   IGNORE 1 LINES                              -- skip the header row
   (invoiceno, stockcode, description, quantity, invoicedate, unitprice,
    @customerid, country, is_cancelled, revenue, duplicate_flag)
   SET customerid = NULLIF(@customerid, '');   -- blank ID -> real NULL, not ''

   To reload: TRUNCATE TABLE sales; then run the LOAD DATA again.
   Expected after load: 530,104 rows, 2010-12-01 to 2011-12-09.
   ===================================================================== */


/* =====================================================================
   SECTION 3 - DATA VALIDATION
   =====================================================================
   Always run these right after loading, BEFORE any analysis.
   If the numbers don't match the expected values, the import is broken.
   ===================================================================== */

-- Quick look at the raw rows.
-- Note: this returns all 530K rows. Workbench shows only the first 1000
-- by default. Add LIMIT 20 if you just want a peek.
SELECT * FROM SALES;

-- Missing values per key column.
-- Expected: 0 for invoice/product/date (cleaning removed them),
--           ~132,220 for customerid (guest checkouts).
-- SUM(condition) counts the rows where the condition is true (true = 1).
SELECT
    SUM(invoiceno IS NULL) AS missing_invoices,
    SUM(stockcode IS NULL) AS missing_products,
    SUM(customerid IS NULL) AS missing_customers,
    SUM(invoicedate IS NULL) AS missing_dates
FROM sales;

-- Total row count. Expected: 530,104 (must match the CSV row count).
SELECT
    COUNT(*) AS total_records
FROM sales;

-- Date range. Expected: 2010-12-01 to 2011-12-09.
-- If this ends in Dec 2010, the import stopped early (see Section 2).
SELECT
    MIN(invoicedate) AS first_transaction,
    MAX(invoicedate) AS last_transaction
FROM sales;

-- Rows and revenue per month. Every month from 2010-12 to 2011-12
-- should appear. A missing month means missing data.
SELECT
    DATE_FORMAT(invoicedate, '%Y-%m') AS sales_month,
    COUNT(*) AS total_records,
    ROUND(SUM(revenue), 2) AS monthly_revenue
FROM sales
GROUP BY sales_month
ORDER BY sales_month;

-- How many rows are flagged as possible duplicates. Expected: 5,228.
-- They are flagged, not deleted. Investigate before removing any.
SELECT
    SUM(duplicate_flag) AS duplicate_records,
    COUNT(*) AS total_records
FROM sales;

-- Cancelled rows. Expected: only is_cancelled = 0, because the cleaning
-- script already removed cancellations from this table.
SELECT
    is_cancelled,
    COUNT(*) AS total_records
FROM sales
GROUP BY is_cancelled;


/* =====================================================================
   SECTION 4 - HEADLINE KPIs
   =====================================================================
   The top-line numbers for a dashboard: revenue, orders, customers, AOV.
   ===================================================================== */

-- One-row summary of the whole dataset.
-- COUNT(*)                  = line items (one row = one product in an order)
-- COUNT(DISTINCT invoiceno) = orders (one invoice = one order)
-- COUNT(DISTINCT customerid) ignores NULLs automatically.
SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT invoiceno) AS total_orders,
    COUNT(DISTINCT customerid) AS unique_customers,
    MIN(invoicedate) AS first_date,
    MAX(invoicedate) AS last_date
FROM sales;

-- Total revenue (includes the flagged duplicates and guest orders).
SELECT
    ROUND(SUM(revenue), 2) AS total_revenue
FROM sales;

-- (Same query as above - a repeat, kept as written.)
SELECT
    ROUND(SUM(revenue), 2) AS total_revenue
FROM sales;

-- Number of orders. DISTINCT is needed because one invoice has many rows
-- (one per product).
SELECT
    COUNT(DISTINCT invoiceno) AS total_orders
FROM sales;

-- Number of real customers. The WHERE excludes guest checkouts (NULL).
-- COUNT(DISTINCT) skips NULLs anyway; the WHERE just makes it explicit.
SELECT
    COUNT(DISTINCT customerid) AS unique_customers
FROM sales
WHERE customerid IS NOT NULL;

-- Average Order Value (AOV) = average revenue per order.
-- Why a CTE (WITH ...)? Revenue is stored per product line, so we first
-- add up each invoice's lines into one order total, then average those
-- order totals. AVG(revenue) directly would give the average per LINE
-- instead, which is a different (and wrong) number.
WITH order_values AS (
    SELECT
        invoiceno,
        SUM(revenue) AS order_revenue
    FROM sales
    GROUP BY invoiceno
)
SELECT
    ROUND(AVG(order_revenue), 2) AS average_order_value
FROM order_values;


/* =====================================================================
   SECTION 5 - TRENDS OVER TIME
   =====================================================================
   When do people buy? Use for seasonality, staffing and campaign timing.
   ===================================================================== */

-- Monthly revenue trend.
-- DATE_FORMAT(..., '%Y-%m') turns a datetime into "2011-03", so all rows in
-- the same month group together. Ordering by that text works because
-- YYYY-MM sorts correctly as text.
-- Remember: 2011-12 is a partial month (ends on the 9th).
SELECT
    DATE_FORMAT(invoicedate, '%Y-%m') AS sales_month,
    ROUND(SUM(revenue), 2) AS monthly_revenue
FROM sales
GROUP BY sales_month
ORDER BY sales_month;

-- Revenue and orders by day of the week.
-- Why group by DAYOFWEEK too? DAYNAME alone would sort alphabetically
-- (Friday, Monday, ...). DAYOFWEEK gives 1=Sunday ... 7=Saturday, so the
-- days come out in calendar order.
-- (The shop has no Saturday orders in this dataset - that's normal for it.)
SELECT
    DAYNAME(invoicedate) AS weekday,
    ROUND(SUM(revenue), 2) AS total_revenue,
    COUNT(DISTINCT invoiceno) AS total_orders
FROM sales
GROUP BY DAYOFWEEK(invoicedate), DAYNAME(invoicedate)
ORDER BY DAYOFWEEK(invoicedate);

-- Revenue and orders by hour of the day (0-23). Shows peak shopping hours.
SELECT
    HOUR(invoicedate) AS order_hour,
    ROUND(SUM(revenue), 2) AS total_revenue,
    COUNT(DISTINCT invoiceno) AS total_orders
FROM sales
GROUP BY HOUR(invoicedate)
ORDER BY order_hour;


/* =====================================================================
   SECTION 6 - PRODUCTS AND CUSTOMERS
   =====================================================================
   Who and what drive the revenue?
   ===================================================================== */

-- Top 10 products by revenue.
-- Why group by stockcode and not description? The same product sometimes
-- has slightly different descriptions, so stockcode is the reliable ID.
-- MAX(description) just picks one name to display for each stockcode.
-- Watch for non-products in the results (POST, DOT, M = postage/manual).
SELECT
    stockcode,
    MAX(description) AS product_name,
    SUM(quantity) AS units_sold,
    ROUND(SUM(revenue), 2) AS total_revenue
FROM sales
GROUP BY stockcode
ORDER BY total_revenue DESC
LIMIT 10;

-- Top 10 customers by total spending.
-- Guest checkouts (NULL customerid) are excluded. Otherwise all of them
-- would be lumped together as one giant "customer".
SELECT
    customerid,
    ROUND(SUM(revenue), 2) AS total_spending,
    COUNT(DISTINCT invoiceno) AS total_orders
FROM sales
WHERE customerid IS NOT NULL
GROUP BY customerid
ORDER BY total_spending DESC
LIMIT 10;
