

/* ================================================================================
   SEED DATA SCRIPT: STATIC FOUNDATION
   Populates Stores, Suppliers, Categories, Products, and Customers.
   ================================================================================
*/
SET NOCOUNT ON;

-- 1. STORES (Real locations + Online)
INSERT INTO Store (StoreName, StoreType, State, City, OpenedDate) VALUES
('Melbourne Central', 'Physical', 'VIC', 'Melbourne', '2019-03-15'),
('Sydney George St', 'Physical', 'NSW', 'Sydney', '2020-11-01'),
('Brisbane Queen St', 'Physical', 'QLD', 'Brisbane', '2021-06-20'),
('Perth CBD', 'Physical', 'WA', 'Perth', '2022-01-10'),
('TechAU Online Warehouse', 'Online', 'VIC', 'Tullamarine', '2018-01-01');

-- 2. SUPPLIERS (Mix of distributors and brands)
INSERT INTO Supplier (SupplierName, ContactPerson, Email, PhoneNumber) VALUES
('Global Electronics Import', 'Sarah Smith', 'orders@global-elec.com.au', '03-9999-1111'),
('Sony Australia', 'David Chen', 'wholesale@sony.com.au', '02-8888-2222'),
('Samsung Logistics', 'Maria Rodriguez', 'partners@samsung.com', '02-7777-3333'),
('Cable & Connector Wholesalers', 'Jim Beam', 'sales@cables-r-us.com', '03-5555-6666'),
('Logitech Distribution', 'Amy Wong', 'au-sales@logitech.com', '02-4444-5555');

-- 3. CATEGORIES (Hierarchical Data)
-- Level 1: Roots
INSERT INTO ProductCategory (CategoryName, ParentCategoryID) VALUES ('Electronics', NULL); -- ID 1
INSERT INTO ProductCategory (CategoryName, ParentCategoryID) VALUES ('Accessories', NULL); -- ID 2

-- Level 2: Children
INSERT INTO ProductCategory (CategoryName, ParentCategoryID) VALUES ('Laptops', 1);       -- ID 3
INSERT INTO ProductCategory (CategoryName, ParentCategoryID) VALUES ('Smartphones', 1);   -- ID 4
INSERT INTO ProductCategory (CategoryName, ParentCategoryID) VALUES ('Audio', 1);         -- ID 5
INSERT INTO ProductCategory (CategoryName, ParentCategoryID) VALUES ('Cables', 2);        -- ID 6
INSERT INTO ProductCategory (CategoryName, ParentCategoryID) VALUES ('Chargers', 2);      -- ID 7

-- 4. PRODUCTS (30 SKUs with varied margins)
-- Note: UnitPrice is what we sell for. StandardCost is what we pay.
INSERT INTO Product (SKU, ProductName, CategoryID, Brand, UnitPrice, StandardCost) VALUES
-- Laptops (Low margin, high value)
('LAP-DEL-001', 'Dell XPS 13', 3, 'Dell', 1899.00, 1600.00),
('LAP-APP-002', 'MacBook Air M2', 3, 'Apple', 1599.00, 1350.00),
('LAP-HP-003', 'HP Spectre x360', 3, 'HP', 2100.00, 1750.00),
('LAP-LEN-004', 'Lenovo ThinkPad X1', 3, 'Lenovo', 2450.00, 2000.00),

-- Phones (Medium margin)
('PHO-SAM-001', 'Samsung Galaxy S24', 4, 'Samsung', 1349.00, 950.00),
('PHO-APP-002', 'iPhone 15 Pro', 4, 'Apple', 1849.00, 1450.00),
('PHO-GOO-003', 'Google Pixel 8', 4, 'Google', 1199.00, 800.00),

-- Audio (High margin)
('AUD-SON-001', 'Sony WH-1000XM5', 5, 'Sony', 549.00, 280.00),
('AUD-APP-002', 'AirPods Pro 2', 5, 'Apple', 399.00, 250.00),
('AUD-BOS-003', 'Bose QC45', 5, 'Bose', 449.00, 220.00),
('AUD-JBL-004', 'JBL Flip 6 Speaker', 5, 'JBL', 149.00, 70.00),

-- Cables & Chargers (Very high margin - "Pure Profit")
('ACC-USB-001', 'USB-C Cable 1m', 6, 'Generic', 19.95, 2.50),
('ACC-USB-002', 'USB-C Cable 2m', 6, 'Generic', 29.95, 3.50),
('ACC-LIG-003', 'Lightning Cable 1m', 6, 'Apple', 35.00, 8.00),
('ACC-WBR-004', 'Wall Charger 20W', 7, 'Samsung', 39.00, 10.00),
('ACC-WBR-005', 'Fast Charger 65W', 7, 'Anker', 69.00, 25.00);

-- 5. CUSTOMERS (A seed list of 100 people)
-- We use a loop here to generate enough volume for analysis
DECLARE @i INT = 1;
WHILE @i <= 100
BEGIN
    INSERT INTO Customer (FirstName, LastName, Email, Gender, DateOfBirth, State)
    VALUES (
        CHOOSE((@i % 5) + 1, 'John', 'Sarah', 'Mike', 'Emma', 'David'), -- Random First Name
        'Customer' + CAST(@i AS NVARCHAR), -- Last Name
        'cust' + CAST(@i AS NVARCHAR) + '@email.com',
        CHOOSE((@i % 2) + 1, 'M', 'F'),
        DATEADD(DAY, -1 * (ABS(CHECKSUM(NEWID())) % 10000 + 6500), GETDATE()), -- Random Age 18-45
        CHOOSE((@i % 3) + 1, 'VIC', 'NSW', 'QLD') -- Random State
    );
    SET @i = @i + 1;
END

PRINT 'Static Foundation Loaded Successfully.';


----------------------------------------------------------------------------------------


SELECT 
    p.ProductName, 
    c.CategoryName AS SubCategory,
    parent.CategoryName AS ParentCategory,
    p.UnitPrice,
    p.StandardCost,
    FORMAT((p.UnitPrice - p.StandardCost) / p.UnitPrice, 'P1') AS Margin_Pct
FROM Product p
JOIN ProductCategory c ON p.CategoryID = c.CategoryID
LEFT JOIN ProductCategory parent ON c.ParentCategoryID = parent.CategoryID
ORDER BY Margin_Pct DESC;


---------------------------------------------------------------------------------------------

/* ================================================================================
   THE TIME MACHINE: DATA SIMULATION (2023 - PRESENT)
   Generates Purchase Orders, Shipments, Sales, Payments, and Returns.
   ================================================================================
*/
SET NOCOUNT ON;
DECLARE @StartDate DATE = '2023-01-01';
DECLARE @EndDate DATE = GETDATE();
DECLARE @CurrentDate DATE = @StartDate;

PRINT 'Starting Simulation from 2023-01-01...';

-- 1. THE BIG BANG: INITIAL STOCKING (Jan 2023)
-- We need to buy stock BEFORE we can sell it, or the trigger will block us.
PRINT 'Initializing Warehouse Stock...';

DECLARE @StoreID INT = 1;
WHILE @StoreID <= 5 -- Loop through all 5 stores
BEGIN
    -- Create one massive "Opening Order" for each store
    INSERT INTO PurchaseOrder (SupplierID, StoreID, OrderDate, ExpectedDeliveryDate, POStatus)
    VALUES (
        1, -- Supplier
        @StoreID, 
        '2022-12-15', -- Ordered in Dec 2022
        '2022-12-30', -- Arrived before we open
        'Closed'
    );
    DECLARE @OpeningPO INT = SCOPE_IDENTITY();

    -- Stock EVERY product (50 of each)
    INSERT INTO PurchaseOrderLine (PurchaseOrderID, ProductID, QuantityOrdered, UnitCost)
    SELECT @OpeningPO, ProductID, 50, StandardCost FROM Product;

    -- Ship it (Receive it)
    INSERT INTO InboundShipment (ActualArrivalDate, CarrierName) VALUES ('2022-12-30', 'DHL');
    DECLARE @OpeningShip INT = SCOPE_IDENTITY();

    -- Link it to Inventory (Triggers will fire here and fill the Inventory table)
    INSERT INTO InboundShipmentLine (ShipmentID, POLineID, QuantityReceived)
    SELECT @OpeningShip, POLineID, 50 
    FROM PurchaseOrderLine WHERE PurchaseOrderID = @OpeningPO;

    SET @StoreID = @StoreID + 1;
END

-- 2. THE DAILY GRIND (Simulation Loop)
WHILE @CurrentDate <= @EndDate
BEGIN
    
    -- A. SEASONALITY FACTOR
    -- Sales are 2x higher in Nov/Dec, 0.8x in Jan/Feb
    DECLARE @Seasonality FLOAT = CASE 
        WHEN MONTH(@CurrentDate) IN (11, 12) THEN 2.0 
        WHEN MONTH(@CurrentDate) IN (1, 2) THEN 0.8
        ELSE 1.0 
    END;

    -- B. GENERATE SALES (Random number of orders per day per store)
    SET @StoreID = 1;
    WHILE @StoreID <= 5
    BEGIN
        -- Random orders: 0 to 5 orders per store per day * Seasonality
        DECLARE @DailyOrders INT = CAST((ABS(CHECKSUM(NEWID())) % 6) * @Seasonality AS INT);
        DECLARE @k INT = 1;

        WHILE @k <= @DailyOrders
        BEGIN
            -- Pick a Random Customer
            DECLARE @CustID INT = (ABS(CHECKSUM(NEWID())) % 100) + 1;

            -- Create the Order Header
            INSERT INTO SalesOrder (CustomerID, StoreID, OrderDate, OrderStatus)
            VALUES (@CustID, @StoreID, @CurrentDate, 'Completed');
            DECLARE @NewSOID INT = SCOPE_IDENTITY();

            -- Create Lines (1-3 items per order)
            -- CRITICAL: We only sell what we have in stock.
            -- We pick a random product, check Inventory, and insert if > 0.
            INSERT INTO SalesOrderLine (SalesOrderID, ProductID, Quantity, UnitPrice)
            SELECT TOP 1 
                @NewSOID, 
                p.ProductID, 
                1, -- Buying 1 unit
                p.UnitPrice
            FROM Product p
            JOIN Inventory i ON p.ProductID = i.ProductID AND i.StoreID = @StoreID
            WHERE i.QuantityOnHand > 0 -- ONLY SELL IF IN STOCK
            ORDER BY NEWID();

            -- If we successfully added a line, create the Payment & Transaction
            IF EXISTS (SELECT 1 FROM SalesOrderLine WHERE SalesOrderID = @NewSOID)
            BEGIN
                -- 1. Create Payment
                INSERT INTO Payment (SalesOrderID, PaymentDate, PaymentMethod, PaymentAmount, PaymentStatus)
                SELECT @NewSOID, @CurrentDate, 'Credit Card', SUM(Quantity * UnitPrice), 'Success'
                FROM SalesOrderLine WHERE SalesOrderID = @NewSOID;

                -- 2. DEDUCT INVENTORY (The Trigger handles the Master Table, we just log the Transaction)
                INSERT INTO InventoryTransaction (ProductID, StoreID, TransactionDate, TransactionType, QuantityChange, ReferenceSalesLineID)
                SELECT ProductID, @StoreID, @CurrentDate, 'Sale', -1 * Quantity, SalesOrderLineID
                FROM SalesOrderLine WHERE SalesOrderID = @NewSOID;
            END
            ELSE
            BEGIN
                -- If no stock was found, delete the empty order header
                DELETE FROM SalesOrder WHERE SalesOrderID = @NewSOID;
            END

            SET @k = @k + 1;
        END
        SET @StoreID = @StoreID + 1;
    END

    -- C. REPLENISHMENT (Buying Logic)
    -- Run this check every Monday (Day 2 of week) to restock
    IF DATEPART(WEEKDAY, @CurrentDate) = 2 
    BEGIN
        SET @StoreID = 1;
        WHILE @StoreID <= 5
        BEGIN
            -- Find items with < 5 stock
            IF EXISTS (SELECT 1 FROM Inventory WHERE StoreID = @StoreID AND QuantityOnHand < 5)
            BEGIN
                -- Create PO
                INSERT INTO PurchaseOrder (SupplierID, StoreID, OrderDate, ExpectedDeliveryDate, POStatus)
                VALUES (1, @StoreID, @CurrentDate, DATEADD(DAY, 7, @CurrentDate), 'Closed');
                DECLARE @RestockPO INT = SCOPE_IDENTITY();

                -- Order 20 more of anything that is low
                INSERT INTO PurchaseOrderLine (PurchaseOrderID, ProductID, QuantityOrdered, UnitCost)
                SELECT @RestockPO, ProductID, 20, (SELECT StandardCost FROM Product WHERE ProductID = Inventory.ProductID)
                FROM Inventory 
                WHERE StoreID = @StoreID AND QuantityOnHand < 5;

                -- Receive it 7 days later (Future Simulation)
                -- We cheat slightly and process the receipt NOW but date it for the future
                -- so the data exists for analysis.
                INSERT INTO InboundShipment (ActualArrivalDate, CarrierName) 
                VALUES (DATEADD(DAY, 7, @CurrentDate), 'Restock Express');
                DECLARE @RestockShip INT = SCOPE_IDENTITY();

                INSERT INTO InboundShipmentLine (ShipmentID, POLineID, QuantityReceived)
                SELECT @RestockShip, POLineID, 20
                FROM PurchaseOrderLine WHERE PurchaseOrderID = @RestockPO;

                -- UPDATE INVENTORY (Add Stock)
                INSERT INTO InventoryTransaction (ProductID, StoreID, TransactionDate, TransactionType, QuantityChange, ReferenceShipmentLineID)
                SELECT pol.ProductID, @StoreID, DATEADD(DAY, 7, @CurrentDate), 'Restock', 20, isl.ShipmentLineID
                FROM PurchaseOrderLine pol
                JOIN InboundShipmentLine isl ON pol.POLineID = isl.POLineID
                WHERE pol.PurchaseOrderID = @RestockPO;
            END
            SET @StoreID = @StoreID + 1;
        END
    END

    -- Advance Time
    SET @CurrentDate = DATEADD(DAY, 1, @CurrentDate);
END

PRINT 'Simulation Complete. 2023-Present data loaded.';




---------------------------------------------------------------------








