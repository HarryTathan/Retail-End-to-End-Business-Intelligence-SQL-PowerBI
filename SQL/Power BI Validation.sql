-- Metrics

SELECT 
    '1. Total Revenue' AS Metric, 
    FORMAT(SUM(quantity * unit_price), 'C0', 'en-AU') AS Value
FROM gold.fct_sales

UNION ALL

SELECT 
    '2. Total COGS', 
    FORMAT(SUM(quantity * standard_cost), 'C0', 'en-AU')
FROM gold.fct_sales

UNION ALL

SELECT 
    '3. Gross Profit', 
    FORMAT(SUM(quantity * unit_price) - SUM(quantity * standard_cost), 'C0', 'en-AU')
FROM gold.fct_sales

UNION ALL

SELECT 
    '4. Current Stock (Units)', 
    FORMAT(SUM(quantity_change), 'N0')
FROM gold.fct_inventory

UNION ALL

SELECT 
    '5. Avg Lead Time (Days)', 
    FORMAT(AVG(CAST(lead_time_days AS FLOAT)), 'N1')
FROM gold.fct_purchasing;



-- YoY Dashboard

WITH DateMaster AS (
    SELECT DISTINCT year, month_name, year * 100 + month(full_date) AS month_key
    FROM gold.dim_date
    WHERE full_date >= '2023-01-01' AND full_date < '2026-01-01'
),

MonthlySales AS (
    SELECT 
        d.year,
        d.month_name,
        SUM(s.quantity * s.unit_price) AS Revenue,
        SUM(s.quantity * s.standard_cost) AS COGS
    FROM gold.fct_sales s
    JOIN gold.dim_date d ON s.date_key = d.date_key
    WHERE d.full_date >= '2023-01-01'
    GROUP BY d.year, d.month_name
),

DailyInventory AS (
    
    SELECT 
        d.date_key,
        SUM(i.quantity_change * p.standard_cost) AS Daily_Stock_Value_Change
    FROM gold.fct_inventory i
    JOIN gold.dim_date d ON i.date_key = d.date_key
    JOIN gold.dim_product p ON i.product_key = p.product_key
    GROUP BY d.date_key
),
MonthlyInventory AS (
    SELECT 
        d.year,
        d.month_name,
        (
            SELECT SUM(Daily_Stock_Value_Change) 
            FROM DailyInventory di 
            WHERE di.date_key <= MAX(d.date_key)
        ) AS Closing_Stock_Value
    FROM gold.dim_date d
    WHERE d.full_date >= '2023-01-01'
    GROUP BY d.year, d.month_name
),

FinalReport AS (
    SELECT 
        dm.year,
        dm.month_name,
        dm.month_key,
        ISNULL(ms.Revenue, 0) AS Total_Revenue,
        ISNULL(ms.COGS, 0) AS Total_COGS,
        (ISNULL(ms.Revenue, 0) - ISNULL(ms.COGS, 0)) AS Gross_Profit,
        ISNULL(mi.Closing_Stock_Value, 0) AS Stock_Value,
        LAG(ms.Revenue, 12, 0) OVER (ORDER BY dm.month_key) AS Revenue_LY
    FROM DateMaster dm
    LEFT JOIN MonthlySales ms ON dm.year = ms.year AND dm.month_name = ms.month_name
    LEFT JOIN MonthlyInventory mi ON dm.year = mi.year AND dm.month_name = mi.month_name
)
SELECT 
    CAST(year AS VARCHAR) + '-' + LEFT(month_name, 3) AS Period,
    FORMAT(Total_Revenue, 'C0', 'en-AU') AS Total_Revenue,
    FORMAT(Revenue_LY, 'C0', 'en-AU') AS Revenue_LY,


    CASE 
        WHEN Revenue_LY = 0 THEN '0%'
        ELSE FORMAT((Total_Revenue - Revenue_LY) / Revenue_LY, 'P2') 
    END AS YoY_Growth,
    

    CASE 
        WHEN Stock_Value = 0 THEN '0.00'
        ELSE FORMAT(Total_COGS / Stock_Value, 'N2') 
    END AS Inv_Turnover,
    
    FORMAT(Stock_Value, 'C0', 'en-AU') AS Avg_Stock_Value,
    FORMAT(Total_COGS, 'C0', 'en-AU') AS Total_COGS,
    FORMAT(Gross_Profit, 'C0', 'en-AU') AS Gross_Profit
FROM FinalReport
ORDER BY month_key;



-------------------------------------------------------------------------

-- Store Performance

SELECT 
    st.store_name,
    FORMAT(SUM(s.quantity * s.unit_price), 'C0', 'en-AU') AS Total_Revenue,
    COUNT(DISTINCT s.sales_order_id) AS Total_Orders,
    FORMAT(AVG(s.quantity * s.unit_price), 'C0', 'en-AU') AS Avg_Order_Value
FROM gold.fct_sales s
JOIN gold.dim_store st ON s.store_key = st.store_key
GROUP BY st.store_name
ORDER BY SUM(s.quantity * s.unit_price) DESC;


------------------------------------------------------------------------------------------

SELECT TOP 10
    p.product_name,
    p.category_name,
    FORMAT(SUM(s.quantity * s.unit_price), 'C0') AS Total_Revenue,
    FORMAT(SUM(s.quantity * s.unit_price) - SUM(s.quantity * s.standard_cost), 'C0') AS Total_Profit,
    FORMAT((SUM(s.quantity * s.unit_price) - SUM(s.quantity * s.standard_cost)) / NULLIF(SUM(s.quantity * s.unit_price), 0), 'P1') AS GP_Margin
FROM gold.fct_sales s
JOIN gold.dim_product p ON s.product_key = p.product_key
JOIN gold.dim_date d ON s.date_key = d.date_key
WHERE d.full_date >= '2023-01-01' -- Keep strict alignment
GROUP BY p.product_name, p.category_name
ORDER BY GP_Margin DESC;



