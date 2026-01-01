-- Mismatches between Inventory stock and Inventory Transaction

SELECT 
    p.ProductName,
    s.StoreName,
    i.QuantityOnHand AS [System_Balance],
    ISNULL(SUM(it.QuantityChange), 0) AS [Calculated_From_History],
    (i.QuantityOnHand - ISNULL(SUM(it.QuantityChange), 0)) AS [Variance]
FROM Inventory i
JOIN Product p ON i.ProductID = p.ProductID
JOIN Store s ON i.StoreID = s.StoreID
LEFT JOIN InventoryTransaction it ON i.ProductID = it.ProductID AND i.StoreID = it.StoreID
GROUP BY p.ProductName, s.StoreName, i.QuantityOnHand
HAVING (i.QuantityOnHand - ISNULL(SUM(it.QuantityChange), 0)) <> 0;



-- Any Sales before Store opening:

SELECT 
    so.SalesOrderID,
    so.OrderDate,
    s.StoreName,
    s.OpenedDate
FROM SalesOrder so
JOIN Store s ON so.StoreID = s.StoreID
WHERE so.OrderDate < s.OpenedDate;


---------------------------------------------
--Any Items with negative Profits

SELECT 
    p.ProductName,
    COUNT(sol.SalesOrderLineID) AS [Count of Sales],
    
    FORMAT(AVG(sol.UnitPrice - ISNULL(sol.DiscountAmount, 0)), 'C', 'en-AU') AS [Avg Net Price],
    FORMAT(MAX(p.StandardCost), 'C', 'en-AU') AS [Standard Cost],
    
    FORMAT(AVG((sol.UnitPrice - ISNULL(sol.DiscountAmount, 0)) - p.StandardCost), 'C', 'en-AU') AS [Loss Per Unit],
    FORMAT(SUM(sol.Quantity * ((sol.UnitPrice - ISNULL(sol.DiscountAmount, 0)) - p.StandardCost)), 'C', 'en-AU') AS [Total Financial Loss]
FROM SalesOrderLine sol
JOIN Product p ON sol.ProductID = p.ProductID

WHERE (sol.UnitPrice - ISNULL(sol.DiscountAmount, 0)) < p.StandardCost
GROUP BY p.ProductName
ORDER BY SUM(sol.Quantity * ((sol.UnitPrice - ISNULL(sol.DiscountAmount, 0)) - p.StandardCost)) ASC;



--------------------------------------------------
--Profitable Products

SELECT 
    p.ProductName,
    -- We calculate Net Price here to ensure the logic matches the Loss report
    FORMAT(AVG(sol.UnitPrice - sol.DiscountAmount), 'C', 'en-AU') AS [Avg Net Sale Price],
    FORMAT(MAX(p.StandardCost), 'C', 'en-AU') AS [Standard Cost],
    FORMAT(AVG((sol.UnitPrice - sol.DiscountAmount) - p.StandardCost), 'C', 'en-AU') AS [Profit Per Unit]
FROM SalesOrderLine sol
JOIN Product p ON sol.ProductID = p.ProductID
-- THE FIX: Filter by NET price, not Gross price
WHERE (sol.UnitPrice - sol.DiscountAmount) > p.StandardCost 
GROUP BY p.ProductName
ORDER BY [Profit Per Unit] DESC;