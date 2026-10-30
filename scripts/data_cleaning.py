
import pandas as pd
from pathlib import Path

# Load data
df = pd.read_excel("data/raw/Online Retail.xlsx")

# Standardise column names
df.columns = (
    df.columns
    .str.strip()
    .str.lower()
    .str.replace(" ", "_")
)

# Convert data types
df["invoicedate"] = pd.to_datetime(
    df["invoicedate"],
    errors="coerce"
)

df["quantity"] = pd.to_numeric(
    df["quantity"],
    errors="coerce"
)

df["unitprice"] = pd.to_numeric(
    df["unitprice"],
    errors="coerce"
)

# Remove whitespace from text fields
for col in ["description", "country", "stockcode"]:
    df[col] = df[col].astype("string").str.strip()

# Standardise invoice number
df["invoiceno"] = df["invoiceno"].astype("string").str.strip()

# Identify cancelled invoices
df["is_cancelled"] = (
    df["invoiceno"]
    .str.upper()
    .str.startswith("C", na=False)
)

# Calculate transaction value
df["revenue"] = df["quantity"] * df["unitprice"]

# Separate positive sales records
sales = df[
    (~df["is_cancelled"])
    & (df["quantity"] > 0)
    & (df["unitprice"] > 0)
    & (df["invoicedate"].notna())
    & (df["description"].notna())
].copy()

# Flag exact duplicates for investigation
sales["duplicate_flag"] = sales.duplicated(
    subset=[
        "invoiceno",
        "stockcode",
        "quantity",
        "invoicedate",
        "unitprice",
        "customerid",
        "country"
    ],
    keep="first"
)
  # Prepare columns for MySQL
sales["is_cancelled"] = sales["is_cancelled"].astype(int)       # True/False -> 1/0
sales["duplicate_flag"] = sales["duplicate_flag"].astype(int)   # True/False -> 1/0
sales["customerid"] = sales["customerid"].astype("Int64")       # 17850.0 -> 17850
sales["revenue"] = sales["revenue"].round(2)                    # 15.299999999999999 -> 15.3


# Save cleaned data
output_path = Path("data/processed/cleaned_sales.csv")

sales.to_csv(output_path, index=False)

# Display summary
print("DATA CLEANING SUMMARY")
print("----------------------")

print("Original rows:", len(df))
print("Clean sales rows:", len(sales))
print("Potential duplicate rows:",
      sales["duplicate_flag"].sum())

print("Missing customer IDs:",
      sales["customerid"].isna().sum())

print("Total positive sales:",
      round(sales["revenue"].sum(), 2))

print("\nCleaned file saved successfully!")
