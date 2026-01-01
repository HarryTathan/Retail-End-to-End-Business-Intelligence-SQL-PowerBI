-- Customer RFM Analysis (Churn Risk and Customer Segmentation)
WITH CustomerMetrics AS (
    SELECT 
        c.CustomerID,
        c.FirstName + ' ' + c.LastName AS FullName,
        DATEDIFF(DAY, MAX(so.OrderDate), (SELECT MAX(OrderDate) FROM SalesOrder)) AS DaysSinceLastOrder,
        COUNT(DISTINCT so.SalesOrderID) AS TotalOrders,
        SUM(sol.Quantity * sol.UnitPrice) AS TotalSpend
    FROM Customer c
    JOIN SalesOrder so ON c.CustomerID = so.CustomerID
    JOIN SalesOrderLine sol ON so.SalesOrderID = sol.SalesOrderID
    WHERE so.OrderStatus = 'Completed'
    GROUP BY c.CustomerID, c.FirstName, c.LastName
),
SegmentedData AS (
    SELECT *,
        CASE 
            -- 1. HIGH VALUE: Above 200k (Your specific requirement)
            WHEN TotalSpend >= 200000 THEN '1. VIP (High Value)'
            
            -- 2. CHURN RISK: Haven't ordered in the top 10% longest durations (~50+ days)
            WHEN DaysSinceLastOrder >= 70 THEN '4. Churn Risk'
            
            -- 3. NEW / OCCASIONAL: Low orders (<30) AND active in last 30 days
            WHEN TotalOrders < 30 AND DaysSinceLastOrder <= 30 THEN '3. Occasional'
            
            -- 4. REGULAR: Everyone else
            ELSE '2. Regular' 
        END AS Customer_Segment
    FROM CustomerMetrics
)
SELECT 
    CustomerID,
    FullName,
    DaysSinceLastOrder,
    TotalOrders,
    FORMAT(TotalSpend, 'C', 'en-AU') AS TotalSpend,
    Customer_Segment
FROM SegmentedData
ORDER BY Customer_Segment ASC, TotalSpend DESC;






------------------------------------------



WITH CustomerMetrics AS (
    SELECT 
        c.customer_key,
        -- Convert Integer date_key (YYYYMMDD) to actual Date for math
        DATEDIFF(DAY, 
            MAX(CAST(CAST(f.date_key AS VARCHAR) AS DATE)), 
            (SELECT MAX(CAST(CAST(date_key AS VARCHAR) AS DATE)) FROM gold.fct_sales)
        ) AS DaysSinceLastOrder,
        COUNT(DISTINCT f.sales_order_id) AS TotalOrders,
        SUM(f.quantity * f.unit_price) AS TotalSpend
    FROM gold.fct_sales f
    JOIN gold.dim_customer c ON f.customer_key = c.customer_key
    GROUP BY c.customer_key
),
SegmentedData AS (
    SELECT 
        CASE 
            -- 1. HIGH VALUE: Spend above 200k
            WHEN TotalSpend >= 200000 THEN '1. VIP (High Value)'
            
            -- 2. CHURN RISK: Haven't ordered in 70+ days
            WHEN DaysSinceLastOrder >= 70 THEN '4. Churn Risk'
            
            -- 3. OCCASIONAL: Low frequency (< 30 orders) AND shopped recently (<= 30 days)
            WHEN TotalOrders < 30 AND DaysSinceLastOrder <= 30 THEN '3. Occasional'
            
            -- 4. REGULAR: The healthy engine of the business
            ELSE '2. Regular' 
        END AS Customer_Segment,
        TotalOrders,
        TotalSpend
    FROM CustomerMetrics
)
SELECT 
    Customer_Segment,
    COUNT(*) AS Customer_Count,
    MIN(TotalOrders) AS Min_Orders_In_Segment,
    FORMAT(AVG(TotalSpend), 'C0', 'en-AU') AS Avg_Spend,
    FORMAT(SUM(TotalSpend), 'C0', 'en-AU') AS Total_Revenue
FROM SegmentedData
GROUP BY Customer_Segment
ORDER BY Customer_Segment ASC;


-- MARKET BASKET ANALYSIS / Product Assocaition (Cross-Sell Report)

SELECT TOP 50
    MainProd.ProductName AS [Product Bought],
    AttachedProd.ProductName AS [Also In Basket],
    
    
    COUNT(*) AS [Frequency],
    
    
    FORMAT(
        CAST(COUNT(*) AS DECIMAL) / 
        (SELECT COUNT(*) FROM SalesOrderLine WHERE ProductID = MainProd.ProductID),
    'P1') AS [Attach Rate]

FROM SalesOrderLine SOL1

JOIN SalesOrderLine SOL2 ON SOL1.SalesOrderID = SOL2.SalesOrderID 
    AND SOL1.ProductID != SOL2.ProductID -- Exclude itself


JOIN Product MainProd ON SOL1.ProductID = MainProd.ProductID
JOIN Product AttachedProd ON SOL2.ProductID = AttachedProd.ProductID

GROUP BY MainProd.ProductID, MainProd.ProductName, AttachedProd.ProductName
ORDER BY [Product Bought],[Frequency] DESC;


-------------------------------------------------------------------------
-- store wise

SELECT 
    f.customer_key, 
    f.date_key, 
    f.store_key, 
    p.product_name, 
    p.category_name
INTO #BasketData
FROM gold.fct_sales f
JOIN gold.dim_product p ON f.product_key = p.product_key
WHERE p.category_name IN ('Laptops', 'Cables');


SELECT 
    st.store_name,
    B1.product_name AS [Lead Product],
    B2.product_name AS [Attached Product],
    COUNT(*) AS [Bundle_Frequency],
    FORMAT(CAST(COUNT(*) AS DECIMAL) / 
        SUM(COUNT(*)) OVER(PARTITION BY st.store_name, B1.product_name), 'P1') AS [Store_Attach_Rate]
FROM #BasketData B1
JOIN #BasketData B2 ON B1.customer_key = B2.customer_key AND B1.date_key = B2.date_key
JOIN gold.dim_store st ON B1.store_key = st.store_key
WHERE B1.category_name = 'Laptops' AND B2.category_name = 'Cables'
GROUP BY st.store_name, B1.product_name, B2.product_name
ORDER BY st.store_name, Bundle_Frequency DESC;

DROP TABLE #BasketData;


-------------------------------------------------------------------------
-- category wise margins

SELECT 
    p.category_name,
    FORMAT(SUM(f.quantity * f.unit_price), 'C0', 'en-AU') AS Revenue,
    FORMAT(SUM(f.quantity * f.standard_cost), 'C0', 'en-AU') AS COGS, -- Cost of Goods Sold
    FORMAT(SUM(f.quantity * (f.unit_price - f.standard_cost)), 'C0', 'en-AU') AS Gross_Profit,
    CAST(SUM(f.quantity * (f.unit_price - f.standard_cost)) * 100.0 / SUM(f.quantity * f.unit_price) AS DECIMAL(5,2)) AS Margin_Pct
FROM gold.fct_sales f
JOIN gold.dim_product p ON f.product_key = p.product_key
GROUP BY p.category_name
ORDER BY Margin_Pct DESC;


-------------------------------------------------------------------------------------------------------
-- Return Rate by Product


WITH SalesMetrics AS (
    SELECT 
        ProductID,
        SUM(CASE WHEN TransactionType = 'Sale' THEN ABS(QuantityChange) END) as sales_qty,
        SUM(CASE WHEN TransactionType = 'Return' THEN QuantityChange END) as return_qty
    FROM InventoryTransaction
    GROUP BY ProductID
)
SELECT 
    p.ProductName,
    sales_qty,
    return_qty,
    CAST(return_qty * 1.0 / NULLIF(sales_qty, 0) AS DECIMAL(5,4)) as return_rate
FROM SalesMetrics sm
JOIN Product p ON sm.ProductID = p.ProductID;

