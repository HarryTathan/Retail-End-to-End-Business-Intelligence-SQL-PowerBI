-- Profit Analysis

SELECT 
    YEAR(so.OrderDate) AS Financial_Year,
    
    -- 1. Volume Metrics
    FORMAT(COUNT(DISTINCT so.SalesOrderID), 'N0') AS Total_Orders,
    FORMAT(SUM(sol.Quantity), 'N0') AS Items_Sold,
    
    -- 2. Revenue (Money In)
    FORMAT(SUM(sol.Quantity * sol.UnitPrice), 'C', 'en-AU') AS Total_Revenue,
    
    -- 3. COGS (Money Out - Estimated via Standard Cost)
    FORMAT(SUM(sol.Quantity * p.StandardCost), 'C', 'en-AU') AS COGS,
    
    -- 4. Gross Profit (The Bottom Line)
    FORMAT(
        SUM(sol.Quantity * sol.UnitPrice) - SUM(sol.Quantity * p.StandardCost), 
    'C', 'en-AU') AS Gross_Profit,
    
    -- 5. Margin % (Healthy retail should be 20-30% blended)
    FORMAT(
        (SUM(sol.Quantity * sol.UnitPrice) - SUM(sol.Quantity * p.StandardCost)) / 
        NULLIF(SUM(sol.Quantity * sol.UnitPrice), 0), 
    'P1') AS Gross_Margin

FROM SalesOrder so
JOIN SalesOrderLine sol ON so.SalesOrderID = sol.SalesOrderID
JOIN Product p ON sol.ProductID = p.ProductID
WHERE so.OrderStatus = 'Completed'
GROUP BY YEAR(so.OrderDate)
ORDER BY Financial_Year;


-- YoY Growth
WITH QuarterlyData AS (
    SELECT 
        YEAR(so.OrderDate) AS [Year],
        DATEPART(QUARTER, so.OrderDate) AS [Quarter],
        SUM(sol.Quantity * sol.UnitPrice) AS Revenue,
        SUM(sol.Quantity * p.StandardCost) AS Cost
    FROM SalesOrder so
    JOIN SalesOrderLine sol ON so.SalesOrderID = sol.SalesOrderID
    JOIN Product p ON sol.ProductID = p.ProductID
    WHERE so.OrderStatus = 'Completed'
    GROUP BY YEAR(so.OrderDate), DATEPART(QUARTER, so.OrderDate)
)
SELECT 
    [Year],
    [Quarter],
    
    -- 1. Quarterly Revenue
    FORMAT(Revenue, 'C', 'en-AU') AS Revenue,
    
    -- 2. Cumulative Revenue (Year-to-Date)
    -- SUM() OVER (PARTITION BY Year ORDER BY Quarter) resets the sum every year
    FORMAT(SUM(Revenue) OVER (PARTITION BY [Year] ORDER BY [Quarter]), 'C', 'en-AU') AS [Cumulative_Revenue_YTD],

    -- 3. YoY Growth Logic (Previous Year same Quarter)
    FORMAT(LAG(Revenue, 4) OVER (ORDER BY [Year], [Quarter]), 'C', 'en-AU') AS [Prev_Year_Revenue],
    
    FORMAT(
        (Revenue - LAG(Revenue, 4) OVER (ORDER BY [Year], [Quarter])) / 
        NULLIF(LAG(Revenue, 4) OVER (ORDER BY [Year], [Quarter]), 0), 
    'P1') AS [YoY_Growth_Pct],

    -- 4. Profitability per Quarter
    FORMAT(Revenue - Cost, 'C', 'en-AU') AS Gross_Profit,
    
    -- 5. Cumulative Profit (Year-to-Date)
    -- This is your "Net Annual Profit" accumulating through the year
    FORMAT(SUM(Revenue - Cost) OVER (PARTITION BY [Year] ORDER BY [Quarter]), 'C', 'en-AU') AS [Net_Annual_Profit_YTD],

    FORMAT((Revenue - Cost) / NULLIF(Revenue, 0), 'P1') AS Margin_Pct

FROM QuarterlyData
ORDER BY [Year], [Quarter];




---------------------------------------------------------------------

--Profit Sharing by store location


SELECT 
    st.store_name, 
    st.city,
    FORMAT(SUM(f.quantity * f.unit_price), 'C0', 'en-AU') AS Total_Revenue,
    CAST(SUM(f.quantity * f.unit_price) * 100.0 / SUM(SUM(f.quantity * f.unit_price)) OVER() AS DECIMAL(5,2)) AS Revenue_Share_Pct
FROM gold.fct_sales f
JOIN gold.dim_store st ON f.store_key = st.store_key
GROUP BY st.store_name, st.city
ORDER BY Revenue_Share_Pct DESC;

---------------------------------------------------
-- Inventory Analysis & Identfying low stocks and dead stock at Warehouse

WITH SalesVelocity AS (
    SELECT 
        so.StoreID,
        sol.ProductID,
        CAST(SUM(sol.Quantity) AS DECIMAL(10,2)) / 30.0 AS Avg_Daily_Sales
    FROM SalesOrder so
    JOIN SalesOrderLine sol ON so.SalesOrderID = sol.SalesOrderID
    WHERE so.OrderDate >= DATEADD(DAY, -30, GETDATE())
    GROUP BY so.StoreID, sol.ProductID
)
SELECT 
    s.StoreName,
    p.ProductName,
    i.QuantityOnHand,
    ISNULL(v.Avg_Daily_Sales, 0.00) AS Daily_Sales_Rate,
    
    
    CASE 
        WHEN i.QuantityOnHand < 0 THEN 0 
        WHEN v.Avg_Daily_Sales IS NULL OR v.Avg_Daily_Sales = 0 THEN 999 
        ELSE CAST(i.QuantityOnHand / v.Avg_Daily_Sales AS INT) 
    END AS [Days_Until_Stockout],
    

    CASE 
        WHEN i.QuantityOnHand < 0 THEN 'DATA ERROR (Negative Stock)'
        WHEN i.QuantityOnHand = 0 THEN 'OUT OF STOCK'
        
        WHEN (i.QuantityOnHand / NULLIF(v.Avg_Daily_Sales,0)) < 7 THEN 'CRITICAL (High Velocity)'
        
        WHEN i.QuantityOnHand < 150 THEN 'Restock Needed (Low Qty)'
        
        WHEN (i.QuantityOnHand / NULLIF(v.Avg_Daily_Sales,0)) > 365 OR (v.Avg_Daily_Sales = 0 AND i.QuantityOnHand > 10) THEN 'Dead Stock (> 1 Year)'
        
        ELSE 'Healthy'
    END AS [Stock_Status]

FROM Inventory i
JOIN Store s ON i.StoreID = s.StoreID
JOIN Product p ON i.ProductID = p.ProductID
LEFT JOIN SalesVelocity v ON i.ProductID = v.ProductID AND i.StoreID = v.StoreID

ORDER BY 
        i.QuantityOnHand ASC;


------------------------------------------------------------
--Inventory Health & Stock Movement (Sales and Restocking) 


SELECT 
    TransactionType,
    COUNT(*) AS [Transaction Count],
    FORMAT(SUM(QuantityChange), 'N0') AS [Net Stock Change]
FROM InventoryTransaction
GROUP BY TransactionType
ORDER BY [Transaction Count] DESC;


--------------------------------------------------------------------
-- Category Wise Overall Analysis (returns)

SELECT 
    p.CategoryName,
    
   
    FORMAT(SUM(CASE WHEN it.TransactionType = 'Restock' THEN it.QuantityChange ELSE 0 END), 'N0') AS Units_Restocked,
    
   
    FORMAT(ABS(SUM(CASE WHEN it.TransactionType = 'Sale' THEN it.QuantityChange ELSE 0 END)), 'N0') AS Units_Sold,
    
    
    FORMAT(SUM(CASE WHEN it.TransactionType = 'Return' THEN it.QuantityChange ELSE 0 END), 'N0') AS Units_Returned,
    

    FORMAT(SUM(CASE WHEN it.TransactionType = 'Adjustment' THEN it.QuantityChange ELSE 0 END), 'N0') AS Stock_Adjustments,
    
    
    FORMAT(
        SUM(CASE WHEN it.TransactionType = 'Return' THEN it.QuantityChange ELSE 0 END) * 1.0 /
        NULLIF(ABS(SUM(CASE WHEN it.TransactionType = 'Sale' THEN it.QuantityChange ELSE 0 END)), 0),
    'P1') AS Return_Rate

FROM InventoryTransaction it
JOIN Product prod ON it.ProductID = prod.ProductID
JOIN ProductCategory p ON prod.CategoryID = p.CategoryID
GROUP BY p.CategoryName
ORDER BY SUM(CASE WHEN it.TransactionType = 'Sale' THEN ABS(it.QuantityChange) ELSE 0 END) DESC;


-----------------------------------------------------------------------------

-- In depth Inventory Analysis (Store - wise & Product Wise)




SELECT 
    s.StoreName,
    p.ProductName,
    
    FORMAT(SUM(CASE WHEN it.TransactionType = 'Restock' THEN it.QuantityChange ELSE 0 END), 'N0') AS [In],
    

    FORMAT(ABS(SUM(CASE WHEN it.TransactionType = 'Sale' THEN it.QuantityChange ELSE 0 END)), 'N0') AS [Out],
    

    FORMAT(SUM(CASE WHEN it.TransactionType = 'Return' THEN it.QuantityChange ELSE 0 END), 'N0') AS [Returned],
    
    
    FORMAT(SUM(CASE WHEN it.TransactionType = 'Adjustment' THEN it.QuantityChange ELSE 0 END), 'N0') AS [Adjustments],
    
    
    FORMAT(SUM(it.QuantityChange), 'N0') AS [Current Stock]

FROM InventoryTransaction it
JOIN Store s ON it.StoreID = s.StoreID
JOIN Product p ON it.ProductID = p.ProductID
GROUP BY s.StoreName, p.ProductName
ORDER BY s.StoreName, p.ProductName;





--------------------------------------------------
-- Returned Items

SELECT TOP 20
    p.ProductName,
    p.Brand,
    
    
    FORMAT(ABS(SUM(CASE WHEN it.TransactionType = 'Sale' THEN it.QuantityChange ELSE 0 END)), 'N0') AS [Units Sold],
    FORMAT(SUM(CASE WHEN it.TransactionType = 'Return' THEN it.QuantityChange ELSE 0 END), 'N0') AS [Units Returned],
    
    
    FORMAT(
        SUM(CASE WHEN it.TransactionType = 'Return' THEN it.QuantityChange ELSE 0 END) * 1.0 /
        NULLIF(ABS(SUM(CASE WHEN it.TransactionType = 'Sale' THEN it.QuantityChange ELSE 0 END)), 0),
    'P1') AS [Return Rate %],
    
    
    FORMAT(
        SUM(CASE WHEN it.TransactionType = 'Return' THEN it.QuantityChange ELSE 0 END) * p.UnitPrice,
    'C', 'en-AU') AS [Refunded Value]

FROM InventoryTransaction it
JOIN Product p ON it.ProductID = p.ProductID
GROUP BY p.ProductName, p.Brand, p.UnitPrice
HAVING ABS(SUM(CASE WHEN it.TransactionType = 'Sale' THEN it.QuantityChange ELSE 0 END)) > 20 -- Ignore low volume
ORDER BY 
  [Return Rate %] desc







  -----------------------------------------------------------

  --Analysing Theft

SELECT 
    s.StoreName,
    
    FORMAT(ABS(SUM(CASE WHEN it.QuantityChange < 0 THEN it.QuantityChange ELSE 0 END)), 'N0') AS [Units Stolen/Lost],
    
    FORMAT(
        SUM(CASE WHEN it.QuantityChange < 0 THEN it.QuantityChange * p.StandardCost ELSE 0 END), 
    'C', 'en-AU') AS [Financial Loss (Theft)]

FROM InventoryTransaction it
JOIN Store s ON it.StoreID = s.StoreID
JOIN Product p ON it.ProductID = p.ProductID
WHERE it.TransactionType = 'Adjustment'
GROUP BY s.StoreName
ORDER BY [Financial Loss (Theft)] desc




