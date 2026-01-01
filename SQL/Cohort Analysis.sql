WITH FirstPurchase AS (
    
    SELECT 
        CustomerID,
        DATEFROMPARTS(YEAR(MIN(OrderDate)), MONTH(MIN(OrderDate)), 1) AS CohortMonth
    FROM SalesOrder
    WHERE OrderStatus = 'Completed'
    GROUP BY CustomerID
),
CohortActivities AS (
    
    SELECT 
        fp.CohortMonth,
        so.OrderDate,
        DATEDIFF(MONTH, fp.CohortMonth, so.OrderDate) AS MonthOffset,
        fp.CustomerID
    FROM SalesOrder so
    JOIN FirstPurchase fp ON so.CustomerID = fp.CustomerID
    WHERE so.OrderStatus = 'Completed'
),
CohortSize AS (
    SELECT 
        CohortMonth, 
        COUNT(DISTINCT CustomerID) AS Original_Count
    FROM FirstPurchase
    GROUP BY CohortMonth
),
RetentionCounts AS (
    SELECT 
        CohortMonth,
        MonthOffset,
        COUNT(DISTINCT CustomerID) AS Active_Customers
    FROM CohortActivities
    GROUP BY CohortMonth, MonthOffset
)

SELECT 
    FORMAT(r.CohortMonth, 'yyyy-MM') AS [Cohort],
    s.Original_Count AS [New Customers],

    FORMAT(MAX(CASE WHEN r.MonthOffset = 0 THEN r.Active_Customers * 1.0 / s.Original_Count END), 'P0') AS [Month 0],

    FORMAT(MAX(CASE WHEN r.MonthOffset = 1 THEN r.Active_Customers * 1.0 / s.Original_Count END), 'P0') AS [Month 1],

    FORMAT(MAX(CASE WHEN r.MonthOffset = 2 THEN r.Active_Customers * 1.0 / s.Original_Count END), 'P0') AS [Month 2],

    FORMAT(MAX(CASE WHEN r.MonthOffset = 3 THEN r.Active_Customers * 1.0 / s.Original_Count END), 'P0') AS [Month 3],
   
    FORMAT(MAX(CASE WHEN r.MonthOffset = 6 THEN r.Active_Customers * 1.0 / s.Original_Count END), 'P0') AS [Month 6],
    
    FORMAT(MAX(CASE WHEN r.MonthOffset = 12 THEN r.Active_Customers * 1.0 / s.Original_Count END), 'P0') AS [Month 12]

FROM RetentionCounts r
JOIN CohortSize s ON r.CohortMonth = s.CohortMonth
GROUP BY r.CohortMonth, s.Original_Count
ORDER BY r.CohortMonth DESC;


