----------------------------------------------------------------------
-- Monthly KPI Scorecard : Dash Board
SELECT 
    FORMAT(OrderDate, 'yyyy-MM') AS [Month],
    COUNT(DISTINCT so.SalesOrderID) AS [Orders],
    COUNT(DISTINCT CustomerID) AS [Active Customers],
    FORMAT(SUM(sol.Quantity * sol.UnitPrice), 'C0', 'en-AU') AS [Revenue],
    FORMAT(AVG(sol.Quantity * sol.UnitPrice), 'C2', 'en-AU') AS [AOV],
    CAST(SUM(sol.Quantity * sol.UnitPrice) / COUNT(DISTINCT CustomerID) AS DECIMAL(10,2)) AS [Revenue_Per_Customer]
FROM SalesOrder so
JOIN SalesOrderLine sol ON so.SalesOrderID = sol.SalesOrderID
WHERE OrderStatus = 'Completed'
    AND OrderDate >= DATEADD(MONTH, -12, GETDATE())
GROUP BY FORMAT(OrderDate, 'yyyy-MM')
ORDER BY [Month];



------------------------------------------------------------------------------------------------------
-- Profit Snapshot


SELECT 
    d.year,
    
    FORMAT(d.full_date, 'MMM-yyyy') AS Month_Year,
    s.store_name,
    p.category_name,
    FORMAT(SUM(f.quantity * f.unit_price), 'C0', 'en-AU') AS Total_Revenue,
    FORMAT(SUM(f.quantity * (f.unit_price - f.standard_cost)), 'C0', 'en-AU') AS Total_Profit,
    COUNT(DISTINCT f.sales_order_id) AS Transaction_Count
FROM gold.fct_sales f
JOIN gold.dim_date d ON f.date_key = d.date_key
JOIN gold.dim_store s ON f.store_key = s.store_key
JOIN gold.dim_product p ON f.product_key = p.product_key
GROUP BY 
    d.year, 
    MONTH(d.full_date),             
    FORMAT(d.full_date, 'MMM-yyyy'), 
    s.store_name, 
    p.category_name
ORDER BY 
    d.year DESC, 
    MONTH(d.full_date) DESC,       
    p.category_name, 
    SUM(f.quantity * (f.unit_price - f.standard_cost)) DESC;