# 🛒 Zepto E-Commerce Inventory Analysis — SQL Project

## 📌 Project Overview

This project simulates how a real-world data analyst works behind the scenes at a quick-commerce company like **Zepto**. Starting from a raw, messy CSV export, the project covers the full analyst workflow — database setup, exploratory data analysis, data cleaning, and business-driven SQL queries to extract actionable insights.

---

## 📂 Dataset

| Property | Details |
|----------|---------|
| **Source** | Zepto product inventory export |
| **File** | `zepto.csv` |
| **Rows** | 3,732 products |
| **Categories** | 14 |
| **Fields** | SKU ID, Category, Name, MRP, Discount %, Available Quantity, Discounted Selling Price, Weight (gms), Out of Stock, Quantity |

> ⚠️ Prices in the raw dataset were stored in **paise** (1 rupee = 100 paise) and converted to rupees during the cleaning phase.

---

## 🛠️ Tools Used

| Tool | Purpose |
|------|---------|
| **MySQL 8.0** | Database engine |
| **MySQL Workbench** | Query execution & import wizard |
| **Python (pandas)** | CSV pre-processing before import |

---

## 🗂️ Project Structure

```
zepto-sql-project/
│
├── zepto.csv                  # Raw dataset
├── zepto_fixed.csv            # Cleaned CSV (post Python pre-processing)
├── zepto_analysis.sql         # Full SQL script (all phases)
└── README.md                  # This file
```

---

## 🔄 Workflow

### Phase 1 — Database Setup
- Designed and created the `zepto` table in MySQL
- Pre-processed CSV using Python (fixed boolean values, renamed columns)
- Imported data via MySQL Workbench

### Phase 2 — Exploratory Data Analysis (EDA)
- Checked row counts, NULL values, and duplicate entries
- Identified invalid rows (`mrp = 0`)
- Analysed out-of-stock distribution across the catalogue

### Phase 3 — Data Cleaning
- Created a safe working copy `zepto_cleaned`
- Converted all prices from paise → rupees
- Removed invalid entries where `mrp = 0`
- Fixed pricing anomalies where `discountedSellingPrice > mrp`
- Resolved `outOfStock` mismatches where `availableQuantity = 0`

### Phase 4 — Business Insights
- Pricing analysis — expensive, cheap, and best-value products
- Discount analysis — most discounted categories and zero-discount products
- Inventory analysis — low stock alerts, dead inventory, supply failures
- Revenue potential by category
- Weight vs price correlation — price per gram across categories

### Bonus Analysis
- **Pricing Buckets** — Budget / Mid-Range / Premium / Luxury segmentation
- **Discount Effectiveness** — 3 cases: discount not working, supply failure, discount working
- **Dead Inventory** — capital stuck in undiscounted, overstocked products
- **Category Health Scorecard** — executive-level summary per category

---

## 💡 Key Findings

1. **Fruits & Vegetables leads discounting** at an average of 15.46% — nearly double most other categories — yet it has the lowest revenue potential (₹10,846), suggesting high discounts on low-margin perishables.

2. **12.14% of products are out of stock** — roughly 1 in 8 SKUs unavailable at any given time. Biscuits (26 SKUs) and Cooking Essentials (20 SKUs) have the most supply failures — products out of stock with zero discount, meaning lost full-price revenue.

3. **Cooking Essentials and Munchies are the highest revenue opportunity categories**, each with a revenue potential of ₹3,37,369 — nearly 3x the next category.

4. **Paan Corner and Personal Care have the lowest average discounts (6.25%)** yet maintain strong revenue potential (₹2,70,849 each), indicating strong organic demand without needing price incentives.

5. **Several lightweight products (under 100g) are priced above ₹500**, pointing to premium specialty items like spices and health supplements where weight is a poor predictor of price — the category, not the size, drives value.

---

## 🚀 How to Run

1. Run the `CREATE TABLE` statement in MySQL Workbench
2. Pre-process the CSV using the Python script in `zepto_analysis.sql` comments
3. Import `zepto_fixed.csv` via the Workbench Import Wizard
4. Execute `zepto_analysis.sql` phase by phase

---
