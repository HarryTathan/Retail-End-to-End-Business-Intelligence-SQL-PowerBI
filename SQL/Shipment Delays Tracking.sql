-------------------------------------------------------------------------------
-- Tracking Shipmnet Delays

   SELECT 
    s.SupplierName,
    ish.ShipmentID,
    po.PurchaseOrderID,
    MAX(DATEDIFF(DAY, po.ExpectedDeliveryDate, ish.ActualArrivalDate)) AS DaysLate,
    SUM(pol.QuantityOrdered) AS TotalOrdered,
    SUM(isl.QuantityReceived) AS TotalReceived,
    SUM(pol.QuantityOrdered) - SUM(isl.QuantityReceived) AS TotalShortfall,
    CASE 
        WHEN MAX(DATEDIFF(DAY, po.ExpectedDeliveryDate, ish.ActualArrivalDate)) > 7 THEN 'Critical Delay'
        WHEN MAX(DATEDIFF(DAY, po.ExpectedDeliveryDate, ish.ActualArrivalDate)) > 0 THEN 'Minor Delay'
        ELSE 'On Time'
    END AS ShipmentStatus
FROM PurchaseOrder po
JOIN PurchaseOrderLine pol ON po.PurchaseOrderID = pol.PurchaseOrderID
JOIN InboundShipmentLine isl ON pol.POLineID = isl.POLineID
JOIN InboundShipment ish ON isl.ShipmentID = ish.ShipmentID
JOIN Supplier s ON po.SupplierID = s.SupplierID
GROUP BY s.SupplierName, ish.ShipmentID, po.PurchaseOrderID
HAVING MAX(DATEDIFF(DAY, po.ExpectedDeliveryDate, ish.ActualArrivalDate)) > 0 
   OR SUM(pol.QuantityOrdered) > SUM(isl.QuantityReceived)
ORDER BY DaysLate DESC;



----------------------------------------------------------------------------------------

SELECT 
    sup.supplier_name,
    COUNT(f.shipment_line_id) AS total_shipments,
    AVG(CAST(f.lead_time_days AS DECIMAL(10,2))) AS avg_lead_time
FROM gold.fct_purchasing f
JOIN gold.dim_supplier sup ON f.supplier_key = sup.supplier_key
GROUP BY sup.supplier_name;





-------------------------------------------------------------------------

SELECT 
    sup.supplier_name,
    COUNT(f.shipment_line_id) AS total_shipments,
    AVG(f.lead_time_days) AS avg_lead_time,
    STDEV(f.lead_time_days) AS lead_time_variance, -- Measures consistency
    CASE 
        WHEN AVG(f.lead_time_days) <= 7 AND STDEV(f.lead_time_days) < 2 THEN 'Elite'
        WHEN AVG(f.lead_time_days) > 15 THEN 'High Risk'
        ELSE 'Standard'
    END AS supplier_tier
FROM gold.fct_purchasing f
JOIN gold.dim_supplier sup ON f.supplier_key = sup.supplier_key
GROUP BY sup.supplier_name
ORDER BY avg_lead_time ASC;



----------------------------------------------------------------------

WITH CategorySales AS (
    SELECT 
        p.category_name,
        SUM(f.quantity * f.unit_price) AS Total_Revenue
    FROM gold.fct_sales f
    JOIN gold.dim_product p ON f.product_key = p.product_key
    GROUP BY p.category_name
),
CategoryPurchasing AS (
    SELECT 
        p.category_name,
        AVG(CAST(pur.lead_time_days AS DECIMAL(10,2))) AS Avg_Lead_Time
    FROM gold.fct_purchasing pur
    JOIN gold.dim_product p ON pur.product_key = p.product_key
    GROUP BY p.category_name
)
SELECT 
    s.category_name,
    FORMAT(s.Total_Revenue, 'C0', 'en-AU') AS Total_Revenue,
    s.Total_Revenue AS Raw_Revenue, -- Used for sorting
    CAST(p.Avg_Lead_Time AS DECIMAL(10,2)) AS Avg_Supply_Lead_Time,
    CASE 
        WHEN p.Avg_Lead_Time > 14 THEN 'Supply Chain Risk'
        ELSE 'Healthy'
    END AS Category_Status
FROM CategorySales s
LEFT JOIN CategoryPurchasing p ON s.category_name = p.category_name
ORDER BY Raw_Revenue DESC;