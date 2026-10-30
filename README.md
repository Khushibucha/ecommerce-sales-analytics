# E-Commerce Sales Analytics

An end-to-end data analytics project on a full year of transactions from a UK-based online gift retailer. Raw Excel data is cleaned with **Python**, loaded into **MySQL** for analysis, and turned into an interactive **Tableau** dashboard.

**🔗 [View the live dashboard on Tableau Public](https://public.tableau.com/app/profile/khushi.bucha/viz/Ecommerce_Sales_Analytics_twbx/Dashboard1)**

---

## Table of Contents

- [Project Overview](#project-overview)
- [Dataset](#dataset)
- [Tools & Tech Stack](#tools--tech-stack)
- [Project Structure](#project-structure)
- [Workflow](#workflow)
- [Data Cleaning](#data-cleaning)
- [SQL Analysis](#sql-analysis)
- [Dashboard](#dashboard)
- [Key Insights](#key-insights)
- [Challenges & Lessons Learned](#challenges--lessons-learned)
- [Data Caveats](#data-caveats)
- [How to Run This Project](#how-to-run-this-project)
- [Future Improvements](#future-improvements)

---

## Project Overview

**Business question:** *How is the business performing, and where does its revenue come from?*

The project answers:

- What are total revenue, orders, customers and average order value?
- How do sales change month to month? Is there seasonality?
- Which countries, products and customers drive the most revenue?
- On which days and at which hours do customers buy the most?

---

## Dataset

| | |
|---|---|
| **Source** | [UCI Machine Learning Repository: Online Retail](https://archive.ics.uci.edu/dataset/352/online+retail) |
| **Business** | UK-based online retailer of giftware. Many customers are wholesalers. |
| **Period** | 01 Dec 2010 – 09 Dec 2011 |
| **Raw size** | 541,909 rows × 8 columns |
| **Cleaned size** | 530,104 rows × 11 columns |

**Original columns:** `InvoiceNo`, `StockCode`, `Description`, `Quantity`, `InvoiceDate`, `UnitPrice`, `CustomerID`, `Country`

**Columns added during cleaning:** `is_cancelled`, `revenue`, `duplicate_flag`

---

## Tools & Tech Stack

| Stage | Tool |
|---|---|
| Data exploration & cleaning | Python (pandas, NumPy, openpyxl) |
| Storage & analysis | MySQL 8 |
| Visualisation | Tableau Public |
| Editor | VS Code |

---

## Project Structure

```
ecommerce-sales-analytics/
├── data/
│   ├── raw/
│   │   └── Online Retail.xlsx          # Original dataset (untouched)
│   └── processed/
│       └── cleaned_sales.csv           # Output of the cleaning script
├── scripts/
│   ├── data_exploration.py             # First look: shape, types, nulls, duplicates
│   └── data_cleaning.py                # Cleans data and writes cleaned_sales.csv
├── sql/
│   └── sales_analysis.sql              # Table creation, load, validation and analysis queries
├── dashboard/
│   └── Ecommerce_Sales_Analytics.twbx.twb   # Tableau workbook
├── reports/                            # Reserved for written reports
├── requirements.txt
└── README.md
```

---

## Workflow

```
Online Retail.xlsx
      │
      ▼
data_exploration.py   →  understand the data (nulls, types, duplicates)
      │
      ▼
data_cleaning.py      →  cleaned_sales.csv
      │
      ├──────────────►  MySQL (ecommerce_db.sales)  →  SQL analysis & validation
      │
      └──────────────►  Tableau  →  interactive dashboard
```

---

## Data Cleaning

Script: [`scripts/data_cleaning.py`](scripts/data_cleaning.py)

| Step | What was done | Why |
|---|---|---|
| Standardise column names | Lowercase, no spaces (`InvoiceNo` → `invoiceno`) | Consistent naming in SQL and Tableau |
| Fix data types | Dates to `datetime`, quantity and price to numeric | Needed for time analysis and maths |
| Trim text | Removed extra spaces from description, country, stock code | Prevents "same" values being counted as different |
| Flag cancellations | `is_cancelled` = invoice starts with `C` | Cancelled orders are not real sales |
| Calculate revenue | `revenue = quantity × unitprice` | Core metric for the whole analysis |
| Filter to valid sales | Kept only non-cancelled rows with quantity > 0, price > 0, a date and a description | Removes returns, adjustments and incomplete rows |
| Flag duplicates | `duplicate_flag` for exact repeat line items | Flagged for investigation, **not deleted** |
| Prepare for MySQL | Booleans as `1/0`, customer ID as whole numbers, revenue rounded to 2 dp | MySQL strict mode rejects `True`/`False` in `TINYINT` columns |

**Result:** 541,909 raw rows → **530,104 clean sales rows**

---

## SQL Analysis

Script: [`sql/sales_analysis.sql`](sql/sales_analysis.sql) (fully commented)

The file is organised into sections:

1. **Create table:** schema with reasons for each data type (e.g. `DECIMAL` for money, `VARCHAR` for IDs)
2. **Load CSV:** the `LOAD DATA LOCAL INFILE` command used to import the data
3. **Data validation:** row counts, date range, missing values, duplicates and cancellations, each with expected values
4. **Headline KPIs:** total revenue, orders, customers and average order value (using a CTE)
5. **Trends over time:** revenue by month, weekday and hour
6. **Products & customers:** top 10 products and top 10 customers by revenue

SQL concepts used: aggregate functions, `GROUP BY`, `COUNT(DISTINCT)`, CTEs (`WITH`), date functions (`DATE_FORMAT`, `DAYNAME`, `DAYOFWEEK`, `HOUR`), conditional sums and `NULL` handling.

---

## Dashboard

**🔗 [E-Commerce Sales Analytics Dashboard (Tableau Public)](https://public.tableau.com/app/profile/khushi.bucha/viz/Ecommerce_Sales_Analytics_twbx/Dashboard1)**

The dashboard includes:

- **KPI cards:** Total Revenue, Total Orders, Unique Customers, Average Order Value
- **Monthly Revenue Trend (2010–2011):** line chart showing seasonality
- **Revenue by Country:** where sales come from
- **Top 10 Products by Revenue**
- **Top 10 Customers by Revenue**
- **Revenue by Weekday:** busiest trading days
- **Revenue by Hour:** peak shopping hours

<!-- Optional: add a screenshot of the dashboard here
![Dashboard preview](reports/dashboard_preview.png)
-->

---

## Key Insights

All figures are from the cleaned dataset (Dec 2010 – Dec 2011, revenue in GBP £).

### Headline numbers

| Metric | Value |
|---|---|
| Total Revenue | **£10.67M** |
| Total Orders | **19,960** |
| Unique Customers | **4,338** |
| Average Order Value | **£534.40** |
| Countries | 38 |
| Products (stock codes) | 3,812 |

### Findings

1. **Strong Q4 seasonality.** November 2011 was the best month (£1.51M), followed by October (£1.15M) and September (£1.06M). Sales build up ahead of the holiday season, as expected for a gift retailer.
2. **Heavily UK-dependent.** The United Kingdom brings in **84.6%** of revenue. The next biggest markets (Netherlands, Ireland, Germany, France) bring in only about 2–3% each, which leaves room to grow internationally.
3. **Midweek is the busiest time.** Thursday and Tuesday have the highest revenue. There are **no Saturday transactions** in the data.
4. **Late-morning to midday peak.** Revenue peaks at 10:00 and 12:00, with another strong hour at 15:00. This is useful timing for campaigns and email sends.
5. **Top products are home décor and party items,** such as the *Regency Cakestand 3 Tier*, *White Hanging Heart T-Light Holder* and *Party Bunting*.
6. **Guest checkouts matter.** About **25%** of line items (16.5% of revenue) have no customer ID, so customer-level metrics understate the true customer base.

---

## Challenges & Lessons Learned

**1. MySQL rejected the CSV: `True`/`False` vs `TINYINT`**
pandas writes booleans as the text `True`/`False`. MySQL's strict mode refused them for `TINYINT(1)` columns.
*Fix:* convert to `1/0` in Python before saving.

**2. The import stopped without an error after 37,402 rows**
The MySQL Workbench Import Wizard stopped without an error at the first `£` character ("Gift Voucher £40.00"). Only December 2010 data was loaded, so the analysis would have covered just 3 weeks instead of a full year.
*Fix:* reloaded with `LOAD DATA LOCAL INFILE ... CHARACTER SET utf8mb4`, which loaded all 530,104 rows in seconds.
*Lesson:* **always check row counts and date ranges after an import.** A successful-looking import can still be incomplete.

**3. Blank customer IDs**
Empty values were loaded as `''` instead of `NULL`, which breaks `IS NULL` checks.
*Fix:* `SET customerid = NULLIF(@customerid, '')` during the load.

**4. Customer IDs showing as `17850.0`**
pandas stores a column with missing values as floats.
*Fix:* cast to pandas' nullable `Int64` type.

---

## Data Caveats

- **Duplicates kept:** 5,228 rows are flagged as possible duplicates but kept in the data, so totals include them.
- **Large one-off orders:** a few single orders are very large. For example, invoice 581483 bought 80,995 units of *Paper Craft, Little Birdie* (£168K). These skew the "top product" and "top customer" rankings.
- **Non-product stock codes:** `DOT` (Dotcom postage), `POST`, `M` (manual), `BANK CHARGES` and `PADS` are not physical products. `DOTCOM POSTAGE` actually ranks #1 by revenue.
- **Partial final month:** December 2011 only runs to the 9th, so it looks low in trend charts.
- **Rounded prices:** 4 rows with a unit price of `0.001` are stored as `0.00` in MySQL (`DECIMAL(10,2)`).

---

## How to Run This Project

### 1. Set up Python

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 2. Explore and clean the data

Run from the project root:

```bash
python scripts/data_exploration.py
python scripts/data_cleaning.py      # creates data/processed/cleaned_sales.csv
```

### 3. Load into MySQL

Create the database and table (Section 1 of `sql/sales_analysis.sql`), then load the CSV:

```bash
mysql --local-infile=1 ecommerce_db
```

```sql
LOAD DATA LOCAL INFILE 'data/processed/cleaned_sales.csv'
INTO TABLE sales
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(invoiceno, stockcode, description, quantity, invoicedate, unitprice,
 @customerid, country, is_cancelled, revenue, duplicate_flag)
SET customerid = NULLIF(@customerid, '');
```

**Check the load:** you should see `530,104` rows from `2010-12-01` to `2011-12-09`.

### 4. Run the analysis

Run the queries in `sql/sales_analysis.sql` (Sections 3–6) in MySQL Workbench or VS Code.

### 5. Open the dashboard

Open `dashboard/Ecommerce_Sales_Analytics.twbx.twb` in Tableau, or use the [live version on Tableau Public](https://public.tableau.com/app/profile/khushi.bucha/viz/Ecommerce_Sales_Analytics_twbx/Dashboard1).

---

## Future Improvements

- **RFM segmentation:** group customers by Recency, Frequency and Monetary value
- **Cohort & retention analysis:** how many customers come back month after month
- **Cancellation analysis:** study the cancelled and returned orders that were removed in cleaning
- **Exclude non-product codes** (`DOT`, `POST`, `M`) from product rankings
- **Market basket analysis:** which products are often bought together
- **Connect Tableau directly to MySQL** instead of the CSV

---

## Author

**Khushi Bucha**
[Tableau Public profile](https://public.tableau.com/app/profile/khushi.bucha)
