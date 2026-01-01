-- Check Sales Migration
SELECT 
    (SELECT COUNT(*) FROM dbo.SalesOrderLine) AS Source_Sales_Count,
    (SELECT COUNT(*) FROM gold.fct_sales) AS Gold_Sales_Count,
    CASE WHEN (SELECT COUNT(*) FROM dbo.SalesOrderLine) = (SELECT COUNT(*) FROM gold.fct_sales) 
         THEN 'MATCH' ELSE 'MISMATCH' END AS Status;

-- Check Product Flattening
-- Note: Gold should have unique Products
SELECT 
    (SELECT COUNT(*) FROM dbo.Product) AS Source_Product_Count,
    (SELECT COUNT(*) FROM gold.dim_product) AS Gold_Product_Count;



-------------------------------------------------------------------------------------------

-- Refrential Integrity

-- Are there any Sales rows that didn't link to a Product?
SELECT COUNT(*) AS Orphaned_Sales_Products
FROM gold.fct_sales
WHERE product_key IS NULL;

-- Are there any Inventory transactions pointing to a non-existent Date?
SELECT COUNT(*) AS Orphaned_Inventory_Dates
FROM gold.fct_inventory f
LEFT JOIN gold.dim_date d ON f.date_key = d.date_key
WHERE d.date_key IS NULL;


---------------------------------------------------------------------------------------

-- Validate Total Revenue
SELECT 
    SUM(UnitPrice * Quantity) AS Source_Total_Revenue 
FROM dbo.SalesOrderLine;

SELECT 
    SUM(unit_price * quantity) AS Gold_Total_Revenue 
FROM gold.fct_sales;



---------------------------------------------------------------------------
--Dimension Quality Check

SELECT category_name, COUNT(*) as Product_Count
FROM gold.dim_product
GROUP BY category_name;