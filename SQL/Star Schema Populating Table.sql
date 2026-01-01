-- Populate Date Dimension
DECLARE @StartDate DATE = '2020-01-01', @EndDate DATE = '2025-12-31';

WITH DateCTE AS (
    SELECT @StartDate AS DateValue
    UNION ALL
    SELECT DATEADD(DAY, 1, DateValue)
    FROM DateCTE
    WHERE DateValue < @EndDate
)
INSERT INTO gold.dim_date (date_key, full_date, year, quarter, month_name, day_of_week)
SELECT 
    CAST(FORMAT(DateValue, 'yyyyMMdd') AS INT) AS date_key,
    DateValue,
    YEAR(DateValue),
    DATEPART(QUARTER, DateValue),
    DATENAME(MONTH, DateValue),
    DATENAME(WEEKDAY, DateValue)
FROM DateCTE
OPTION (MAXRECURSION 0);



----------------------------------------------------

-- 1. Product Dimension (Flattening 3NF)
INSERT INTO gold.dim_product (source_product_id, sku, product_name, category_name, brand, unit_price, standard_cost, is_discontinued)
SELECT DISTINCT 
    p.ProductID, p.SKU, p.ProductName, pc.CategoryName, p.Brand, p.UnitPrice, p.StandardCost, p.IsDiscontinued
FROM dbo.Product p
LEFT JOIN dbo.ProductCategory pc ON p.CategoryID = pc.CategoryID;

-- 2. Store Dimension
INSERT INTO gold.dim_store (source_store_id, store_name, store_type, city, state)
SELECT DISTINCT StoreID, StoreName, StoreType, City, State
FROM dbo.Store;

-- 3. Customer Dimension
INSERT INTO gold.dim_customer (source_customer_id, full_name, email, gender, state)
SELECT DISTINCT CustomerID, FirstName + ' ' + LastName, Email, Gender, State
FROM dbo.Customer;

-- 4. Supplier Dimension
INSERT INTO gold.dim_supplier (source_supplier_id, supplier_name, contact_person)
SELECT DISTINCT SupplierID, SupplierName, ContactPerson
FROM dbo.Supplier;


-----------------------------------------------------------------------------------------------------


-- Fact Sales

INSERT INTO gold.fct_sales (sales_order_line_id, sales_order_id, product_key, store_key, customer_key, date_key, quantity, unit_price, standard_cost, discount_amount, return_quantity)
SELECT 
    sol.SalesOrderLineID, 
    sol.SalesOrderID, 
    p.product_key, 
    st.store_key, 
    c.customer_key, 
    d.date_key,
    sol.Quantity, 
    sol.UnitPrice, 
    p.standard_cost, 
    sol.DiscountAmount, 
    ISNULL(cr.ReturnQuantity, 0)
FROM dbo.SalesOrderLine sol
JOIN dbo.SalesOrder so ON sol.SalesOrderID = so.SalesOrderID -- Confirmed table name
JOIN gold.dim_product p ON sol.ProductID = p.source_product_id
JOIN gold.dim_store st ON so.StoreID = st.source_store_id
JOIN gold.dim_customer c ON so.CustomerID = c.source_customer_id
JOIN gold.dim_date d ON CAST(so.OrderDate AS DATE) = d.full_date
LEFT JOIN dbo.CustomerReturn cr ON sol.SalesOrderLineID = cr.SalesOrderLineID;




-- Fact Purchasing

-- STEP 2: Reload with DISTINCT to prevent Fan-out
INSERT INTO gold.fct_purchasing (shipment_line_id, product_key, supplier_key, date_key, qty_ordered, qty_received, lead_time_days)
SELECT DISTINCT
    isl.ShipmentLineID, 
    p.product_key, 
    sup.supplier_key, 
    d.date_key,
    pol.QuantityOrdered, 
    isl.QuantityReceived,
    DATEDIFF(DAY, po.OrderDate, ish.ActualArrivalDate)
FROM dbo.InboundShipmentLine isl
INNER JOIN dbo.InboundShipment ish ON isl.ShipmentID = ish.ShipmentID
INNER JOIN dbo.PurchaseOrderLine pol ON isl.POLineID = pol.POLineID
INNER JOIN dbo.PurchaseOrder po ON pol.PurchaseOrderID = po.PurchaseOrderID
INNER JOIN gold.dim_product p ON pol.ProductID = p.source_product_id
INNER JOIN gold.dim_supplier sup ON po.SupplierID = sup.source_supplier_id
INNER JOIN gold.dim_date d ON CAST(ish.ActualArrivalDate AS DATE) = d.full_date;

-- Fact Inventory


INSERT INTO gold.fct_inventory (transaction_id, product_key, store_key, date_key, quantity_change, transaction_type)
SELECT 
    it.TransactionID, 
    p.product_key, 
    st.store_key, 
    d.date_key,
    it.QuantityChange, 
    it.TransactionType
FROM dbo.InventoryTransaction it
JOIN gold.dim_product p ON it.ProductID = p.source_product_id
JOIN gold.dim_store st ON it.StoreID = st.source_store_id
JOIN gold.dim_date d ON CAST(it.TransactionDate AS DATE) = d.full_date;

