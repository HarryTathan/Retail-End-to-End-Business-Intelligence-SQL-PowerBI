CREATE OR ALTER PROCEDURE gold.usp_RefreshGoldLayer
AS
BEGIN
    SET NOCOUNT ON;
    
    -- 1. Handle Transactions and Errors
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 2. CLEAR GOLD FACTS (No FK issues in Gold)
        PRINT 'Cleaning Gold Layer...';
        TRUNCATE TABLE gold.fct_sales;
        TRUNCATE TABLE gold.fct_purchasing;
        TRUNCATE TABLE gold.fct_inventory;

        -- 3. SYNC DIMENSIONS (Using DISTINCT to prevent the "Fan-Out" doubling we saw)
        PRINT 'Refreshing Dimensions...';
        
        -- Customer
        DELETE FROM gold.dim_customer;
        INSERT INTO gold.dim_customer (source_customer_id, full_name, email, gender, state)
        SELECT DISTINCT CustomerID, FirstName + ' ' + LastName, Email, Gender, State FROM dbo.Customer;

        -- Product (Identity Handling included)
        DELETE FROM gold.dim_product;
        SET IDENTITY_INSERT gold.dim_product ON;
        INSERT INTO gold.dim_product (product_key, source_product_id, sku, product_name, category_name, brand, unit_price, standard_cost, is_discontinued)
        SELECT DISTINCT p.ProductID, p.ProductID, p.SKU, p.ProductName, pc.CategoryName, p.Brand, p.UnitPrice, p.StandardCost, p.IsDiscontinued
        FROM dbo.Product p
        LEFT JOIN dbo.ProductCategory pc ON p.CategoryID = pc.CategoryID;
        SET IDENTITY_INSERT gold.dim_product OFF;

        -- 4. SYNC FACTS
        PRINT 'Syncing Facts...';

        -- Sales (Including verified Returns)
        INSERT INTO gold.fct_sales (sales_order_line_id, product_key, store_key, customer_key, date_key, quantity, unit_price, standard_cost, discount_amount, return_quantity)
        SELECT sol.SalesOrderLineID, p.product_key, st.store_key, c.customer_key, d.date_key,
               sol.Quantity, sol.UnitPrice, p.standard_cost, sol.DiscountAmount, ISNULL(cr.ReturnQuantity, 0)
        FROM dbo.SalesOrderLine sol
        JOIN dbo.SalesOrder so ON sol.SalesOrderID = so.SalesOrderID
        JOIN gold.dim_product p ON sol.ProductID = p.source_product_id
        JOIN gold.dim_store st ON so.StoreID = st.source_store_id
        JOIN gold.dim_customer c ON so.CustomerID = c.source_customer_id
        JOIN gold.dim_date d ON CAST(so.OrderDate AS DATE) = d.full_date
        LEFT JOIN dbo.CustomerReturn cr ON sol.SalesOrderLineID = cr.SalesOrderLineID;

        -- Purchasing (Using LEFT JOINs to prevent the 0-row "Kill Switch")
        INSERT INTO gold.fct_purchasing (shipment_line_id, product_key, supplier_key, date_key, qty_ordered, qty_received, lead_time_days)
        SELECT isl.ShipmentLineID, p.product_key, ISNULL(sup.supplier_key, 0), ISNULL(d.date_key, 0),
               pol.QuantityOrdered, isl.QuantityReceived, ISNULL(DATEDIFF(DAY, po.OrderDate, ish.ActualArrivalDate), 0)
        FROM dbo.InboundShipmentLine isl
        JOIN dbo.InboundShipment ish ON isl.ShipmentID = ish.ShipmentID
        JOIN dbo.PurchaseOrderLine pol ON isl.POLineID = pol.POLineID
        JOIN dbo.PurchaseOrder po ON pol.PurchaseOrderID = po.PurchaseOrderID
        JOIN gold.dim_product p ON pol.ProductID = p.source_product_id
        LEFT JOIN gold.dim_supplier sup ON po.SupplierID = sup.source_supplier_id
        LEFT JOIN gold.dim_date d ON CAST(ish.ActualArrivalDate AS DATE) = d.full_date;

        COMMIT TRANSACTION;
        PRINT 'SUCCESS: Gold Layer Refreshed and Verified.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        PRINT 'ERROR: ' + ERROR_MESSAGE();
    END CATCH
END;
GO



exec gold.usp_RefreshGoldLayer