
import pandas as pd

# Load dataset
df = pd.read_excel("data/raw/Online Retail.xlsx")

# Display basic information
print("\nDATASET OVERVIEW")
print("----------------------")

print("Total rows:", len(df))
print("Total columns:", len(df.columns))

# First five rows
print("\nFIRST FIVE RECORDS")
print(df.head())

# Column names
print("\nCOLUMN NAMES")
print(df.columns.tolist())

# Data types
print("\nDATA TYPES")
print(df.dtypes)

# Missing values
print("\nMISSING VALUES")
print(df.isnull().sum())

# Duplicate records
print("\nDUPLICATE RECORDS")
print(df.duplicated().sum())

# Unique customers and products
print("\nUNIQUE CUSTOMERS")
print(df["CustomerID"].nunique())

print("\nUNIQUE PRODUCTS")
print(df["StockCode"].nunique())

print("\nUNIQUE COUNTRIES")
print(df["Country"].nunique())

# Statistical summary
print("\nSTATISTICAL SUMMARY")
print(df.describe())
