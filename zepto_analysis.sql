create database zepto;
use zepto;
CREATE TABLE zepto (
    sku_id INT AUTO_INCREMENT PRIMARY KEY,
    category VARCHAR(120),
    name VARCHAR(150) NOT NULL,
    mrp DECIMAL(8,2),
    discountPercent DECIMAL(5,2),
    availableQuantity INT,
    discountedSellingPrice DECIMAL(8,2),
    weightInGms INT,
    outOfStock BOOLEAN,
    quantity INT
);
#drop database zepto;

-- Exploratory Data Analysis --

# 1. Total rows & distinct categories
SELECT COUNT(*) AS total_products,
       COUNT(DISTINCT category) AS total_categories
FROM zepto;

# 2. Check for NULL values
SELECT
    SUM(CASE WHEN sku_id IS NULL THEN 1 ELSE 0 END) AS null_sku,
    SUM(CASE WHEN category IS NULL THEN 1 ELSE 0 END) AS null_category,
    SUM(CASE WHEN name IS NULL THEN 1 ELSE 0 END) AS null_name,
    SUM(CASE WHEN mrp IS NULL THEN 1 ELSE 0 END) AS null_mrp,
    SUM(CASE WHEN discountPercent IS NULL THEN 1 ELSE 0 END) AS null_discount,
    SUM(CASE WHEN availableQuantity IS NULL THEN 1 ELSE 0 END) AS null_qty,
    SUM(CASE WHEN discountedSellingPrice IS NULL THEN 1 ELSE 0 END) AS null_price,
    SUM(CASE WHEN weightInGms IS NULL THEN 1 ELSE 0 END) AS null_weight,
    SUM(CASE WHEN outOfStock IS NULL THEN 1 ELSE 0 END) AS null_stock
FROM zepto;

# 3. Duplicate product names
SELECT name, COUNT(*) AS occurrences
FROM zepto
GROUP BY name
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;

# 4. Products with MRP = 0 (invalid entries)
SELECT * FROM zepto
WHERE mrp = 0;

# 5. Out-of-stock breakdown
SELECT 
    CASE WHEN outOfStock = 0 THEN 'In Stock' ELSE 'Out of Stock' END AS stock_status,
    COUNT(*) AS total,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM zepto), 2) AS percentage
FROM zepto
GROUP BY outOfStock;

# 6. Category-wise product count
SELECT category,
       COUNT(*) AS total_products
FROM zepto
GROUP BY category
ORDER BY total_products DESC;

-- checking purpose : SELECT mrp FROM zepto WHERE mrp > 0;
SET SQL_SAFE_UPDATES = 0;
-- Data Cleaning --

# 1. create a clean working copy (never alter raw data)
CREATE TABLE zepto_cleaned AS
SELECT * FROM zepto;

# 2. Convert prices from paise to rupees
-- As we spotted earlier, mrp = 2500 for Onion is actually ₹25.00. All prices are stored in paise, so divide by 100:
UPDATE zepto_cleaned
SET mrp = ROUND(mrp / 100.0, 2),
    discountedSellingPrice = ROUND(discountedSellingPrice / 100.0, 2);

# 3. Delete rows where MRP = 0 (invalid/corrupt entries)
DELETE FROM zepto_cleaned
WHERE mrp = 0;

# 4. Fix rows where discountedSellingPrice > mrp (pricing anomaly)
-- First, let's see how many such rows exist:
SELECT COUNT(*) AS anomalies
FROM zepto_cleaned
WHERE discountedSellingPrice > mrp;

-- Then fix them by setting discount price = mrp (0% effective discount):
UPDATE zepto_cleaned
SET discountedSellingPrice = mrp
WHERE discountedSellingPrice > mrp;

# 5. Fix outOfStock mismatches
-- Products marked in stock but availableQuantity = 0 is contradictory:
UPDATE zepto_cleaned
SET outOfStock = 1
WHERE availableQuantity = 0 AND outOfStock = 0;

# 6. Verify the cleaned table
SELECT COUNT(*) AS total_rows FROM zepto_cleaned;

SELECT MIN(mrp), MAX(mrp), 
       MIN(discountedSellingPrice), MAX(discountedSellingPrice)
FROM zepto_cleaned;

-- Phase 4 — Business Insights

# 1. Most expensive products by category
SELECT category, name, mrp
FROM zepto_cleaned
WHERE mrp = (
    SELECT MAX(mrp) FROM zepto_cleaned z2
    WHERE z2.category = zepto_cleaned.category
)
ORDER BY mrp DESC;

# 2. Average MRP and selling price per category
SELECT category,
       ROUND(AVG(mrp), 2) AS avg_mrp,
       ROUND(AVG(discountedSellingPrice), 2) AS avg_selling_price,
       ROUND(AVG(discountPercent), 2) AS avg_discount_pct
FROM zepto_cleaned
GROUP BY category
ORDER BY avg_discount_pct DESC;

# 3. Top 10 most discounted products
SELECT name, category, mrp, discountedSellingPrice, discountPercent
FROM zepto_cleaned
ORDER BY discountPercent DESC
LIMIT 10;

# 4. Products with zero discount
SELECT category, COUNT(*) AS zero_discount_products
FROM zepto_cleaned
WHERE discountPercent = 0
GROUP BY category
ORDER BY zero_discount_products DESC;

# 5. Revenue potential per category
SELECT category,
       ROUND(SUM(discountedSellingPrice * availableQuantity), 2) AS revenue_potential
FROM zepto_cleaned
GROUP BY category
ORDER BY revenue_potential DESC;

-- Inventory & Stock Analysis

# 6. Out-of-stock % per category
SELECT category,
       COUNT(*) AS total_products,
       SUM(outOfStock) AS out_of_stock,
       ROUND(SUM(outOfStock) * 100.0 / COUNT(*), 2) AS oos_percentage
FROM zepto_cleaned
GROUP BY category
ORDER BY oos_percentage DESC;

# 7. Low stock alert — in stock but quantity dangerously low
SELECT name, category, availableQuantity, discountedSellingPrice
FROM zepto_cleaned
WHERE outOfStock = 0 AND availableQuantity <= 5
ORDER BY availableQuantity ASC;

# 8. Best value products — lowest price per gram
SELECT name, category,
       discountedSellingPrice,
       weightInGms,
       ROUND(discountedSellingPrice / weightInGms, 2) AS price_per_gram
FROM zepto_cleaned
WHERE weightInGms > 0
ORDER BY price_per_gram ASC
LIMIT 10;

# 9. Most stocked category — total available inventory
SELECT category,
       SUM(availableQuantity) AS total_inventory
FROM zepto_cleaned
GROUP BY category
ORDER BY total_inventory DESC;

# 10. Products where discount is high but still expensive
SELECT name, category, mrp, discountedSellingPrice, discountPercent
FROM zepto_cleaned
WHERE discountPercent >= 30
AND discountedSellingPrice >= 300
ORDER BY discountedSellingPrice DESC
LIMIT 10;

-- Pricing Buckets
SELECT category, name, discountedSellingPrice,
    CASE
        WHEN discountedSellingPrice < 100 THEN 'Budget'
        WHEN discountedSellingPrice BETWEEN 100 AND 500 THEN 'Mid-Range'
        WHEN discountedSellingPrice BETWEEN 501 AND 1000 THEN 'Premium'
        ELSE 'Luxury'
    END AS price_segment
FROM zepto_cleaned
ORDER BY discountedSellingPrice DESC;

-- distribution summary across categories:
SELECT category,
    SUM(CASE WHEN discountedSellingPrice < 100 THEN 1 ELSE 0 END) AS Budget,
    SUM(CASE WHEN discountedSellingPrice BETWEEN 100 AND 500 THEN 1 ELSE 0 END) AS Mid_Range,
    SUM(CASE WHEN discountedSellingPrice BETWEEN 501 AND 1000 THEN 1 ELSE 0 END) AS Premium,
    SUM(CASE WHEN discountedSellingPrice > 1000 THEN 1 ELSE 0 END) AS Luxury
FROM zepto_cleaned
GROUP BY category
ORDER BY category;

-- Discount Effectiveness
# High discount + out of stock (discount working too well) Demand is clearly there — just needs supply chain to catch up.
SELECT category, name, mrp, discountPercent,
       availableQuantity, discountedSellingPrice
FROM zepto_cleaned
WHERE discountPercent >= 20
AND outOfStock = 1
ORDER BY discountPercent DESC;

# Products with no discount yet still out of stock — people want it at full price and Zepto still can't keep it in stock.
SELECT category, name, mrp, discountPercent,
       availableQuantity, discountedSellingPrice
FROM zepto_cleaned
WHERE discountPercent = 0
AND outOfStock = 1
ORDER BY mrp DESC;

-- Case 3 — High discount, still in stock (discount NOT working)  These products are cheap + available yet nobody's buying — possible quality or relevance issue.
SELECT category, name, mrp, discountPercent, 
       availableQuantity, discountedSellingPrice
FROM zepto_cleaned
WHERE discountPercent >= 10
AND outOfStock = 0
AND availableQuantity > 10
ORDER BY discountPercent DESC, availableQuantity DESC;

-- Summary scorecard across all 3 cases

SELECT 
    SUM(CASE WHEN discountPercent >= 10 AND outOfStock = 0 AND availableQuantity > 10 THEN 1 ELSE 0 END) AS discount_not_working,
    SUM(CASE WHEN discountPercent = 0 AND outOfStock = 1 THEN 1 ELSE 0 END) AS supply_failure,
    SUM(CASE WHEN discountPercent >= 20 AND outOfStock = 1 THEN 1 ELSE 0 END) AS discount_working
FROM zepto_cleaned;


-- Dead Inventory
# Products that are sitting on the shelf, not moving — in stock, well stocked, but zero discount and no incentive to buy:

SELECT category, name, mrp, discountPercent,
       availableQuantity, discountedSellingPrice
FROM zepto_cleaned
WHERE discountPercent = 0
AND outOfStock = 0
AND availableQuantity >= 10
ORDER BY availableQuantity DESC;

SELECT category,
       COUNT(*) AS dead_products,
       ROUND(AVG(mrp), 2) AS avg_mrp,
       SUM(availableQuantity) AS total_stuck_units,
       ROUND(SUM(mrp * availableQuantity), 2) AS stuck_inventory_value
FROM zepto_cleaned
WHERE discountPercent = 0
AND outOfStock = 0
AND availableQuantity >= 10
GROUP BY category
ORDER BY stuck_inventory_value DESC;

-- The "stuck_inventory_value" column is the most important, it tells you how much money is locked up in products that aren't moving.
-- if any such product is found, it is advised to flag these to the pricing team to introduce a discount and free up that capital.

-- Category Health Scorecard

SELECT 
    category,
    COUNT(*) AS total_products,
    ROUND(AVG(mrp), 2) AS avg_mrp,
    ROUND(AVG(discountedSellingPrice), 2) AS avg_selling_price,
    ROUND(AVG(discountPercent), 2) AS avg_discount_pct,
    SUM(availableQuantity) AS total_inventory,
    SUM(outOfStock) AS oos_products,
    ROUND(SUM(outOfStock) * 100.0 / COUNT(*), 2) AS oos_pct,
    ROUND(SUM(discountedSellingPrice * availableQuantity), 2) AS revenue_potential,
    SUM(CASE WHEN discountPercent = 0 AND outOfStock = 0 AND availableQuantity >= 10 THEN 1 ELSE 0 END) AS dead_inventory_products,
    SUM(CASE WHEN discountPercent = 0 AND outOfStock = 1 THEN 1 ELSE 0 END) AS supply_failures,
    SUM(CASE WHEN discountPercent >= 20 AND outOfStock = 1 THEN 1 ELSE 0 END) AS discount_working
FROM zepto_cleaned
GROUP BY category
ORDER BY revenue_potential DESC;
