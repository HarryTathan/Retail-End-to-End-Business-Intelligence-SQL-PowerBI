



-- 1. Store
CREATE TABLE Store (
    StoreID INT IDENTITY(1,1) PRIMARY KEY,
    StoreName NVARCHAR(100) NOT NULL,
    StoreType NVARCHAR(20) NOT NULL CHECK (StoreType IN ('Physical', 'Online')),
    State NVARCHAR(50) NOT NULL,
    City NVARCHAR(50) NOT NULL,
    OpenedDate DATE NOT NULL,
    IsActive BIT DEFAULT 1
);

-- 2. Customer
CREATE TABLE Customer (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) NOT NULL UNIQUE, -- Prevents duplicates
    Gender CHAR(1),
    DateOfBirth DATE NOT NULL,
    State NVARCHAR(50),
    CreatedDate DATETIME DEFAULT GETDATE(),
    IsActive BIT DEFAULT 1
);

-- 3. Supplier
CREATE TABLE Supplier (
    SupplierID INT IDENTITY(1,1) PRIMARY KEY,
    SupplierName NVARCHAR(100) NOT NULL,
    ContactPerson NVARCHAR(100),
    Email NVARCHAR(100) NOT NULL,
    PhoneNumber NVARCHAR(20),
    IsActive BIT DEFAULT 1
);


-- 4. ProductCategory
CREATE TABLE ProductCategory (
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName NVARCHAR(50) NOT NULL,
    ParentCategoryID INT NULL FOREIGN KEY REFERENCES ProductCategory(CategoryID) 
    -- Recursive Key: Allows Category Hierarchy
);

-- 5. Product
CREATE TABLE Product (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    SKU NVARCHAR(50) NOT NULL UNIQUE, -- The master key for logic
    ProductName NVARCHAR(100) NOT NULL,
    CategoryID INT NOT NULL FOREIGN KEY REFERENCES ProductCategory(CategoryID),
    Brand NVARCHAR(50),
    UnitPrice DECIMAL(18, 2) NOT NULL CHECK (UnitPrice >= 0),
    StandardCost DECIMAL(18, 2) NOT NULL CHECK (StandardCost >= 0),
    CreatedDate DATETIME DEFAULT GETDATE(),
    IsDiscontinued BIT DEFAULT 0
);


-- 6. PurchaseOrder (Header)
CREATE TABLE PurchaseOrder (
    PurchaseOrderID INT IDENTITY(1,1) PRIMARY KEY,
    SupplierID INT NOT NULL FOREIGN KEY REFERENCES Supplier(SupplierID),
    StoreID INT NOT NULL FOREIGN KEY REFERENCES Store(StoreID), -- Who requested it?
    OrderDate DATE NOT NULL,
    ExpectedDeliveryDate DATE NOT NULL,
    POStatus NVARCHAR(20) NOT NULL CHECK (POStatus IN ('Pending', 'Closed', 'Cancelled')),
    CONSTRAINT CHK_DeliveryDate CHECK (ExpectedDeliveryDate >= OrderDate)
);

-- 7. PurchaseOrderLine (Detail)
CREATE TABLE PurchaseOrderLine (
    POLineID INT IDENTITY(1,1) PRIMARY KEY,
    PurchaseOrderID INT NOT NULL FOREIGN KEY REFERENCES PurchaseOrder(PurchaseOrderID),
    ProductID INT NOT NULL FOREIGN KEY REFERENCES Product(ProductID),
    QuantityOrdered INT NOT NULL CHECK (QuantityOrdered > 0),
    UnitCost DECIMAL(18, 2) NOT NULL CHECK (UnitCost >= 0) 
    -- Logic: Cost is snapshotted here. Future product cost changes won't break history.
);

-- 8. InboundShipment (Logistics Header)
CREATE TABLE InboundShipment (
    ShipmentID INT IDENTITY(1,1) PRIMARY KEY,
    CarrierName NVARCHAR(50),
    TrackingNumber NVARCHAR(100),
    ActualArrivalDate DATETIME NOT NULL
);

-- 9. InboundShipmentLine (Logistics Detail / The Bridge)
-- This is the physical receipt of goods.
CREATE TABLE InboundShipmentLine (
    ShipmentLineID INT IDENTITY(1,1) PRIMARY KEY,
    ShipmentID INT NOT NULL FOREIGN KEY REFERENCES InboundShipment(ShipmentID),
    POLineID INT NOT NULL FOREIGN KEY REFERENCES PurchaseOrderLine(POLineID),
    QuantityReceived INT NOT NULL CHECK (QuantityReceived > 0)
);



-- 10. SalesOrder 
CREATE TABLE SalesOrder (
    SalesOrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL FOREIGN KEY REFERENCES Customer(CustomerID),
    StoreID INT NOT NULL FOREIGN KEY REFERENCES Store(StoreID),
    OrderDate DATETIME DEFAULT GETDATE(),
    OrderStatus NVARCHAR(20) NOT NULL CHECK (OrderStatus IN ('Completed', 'Cancelled', 'Returned'))
);

-- 11. SalesOrderLine 
CREATE TABLE SalesOrderLine (
    SalesOrderLineID INT IDENTITY(1,1) PRIMARY KEY,
    SalesOrderID INT NOT NULL FOREIGN KEY REFERENCES SalesOrder(SalesOrderID),
    ProductID INT NOT NULL FOREIGN KEY REFERENCES Product(ProductID),
    Quantity INT NOT NULL CHECK (Quantity > 0),
    UnitPrice DECIMAL(18, 2) NOT NULL CHECK (UnitPrice >= 0), -- Snapshot price
    DiscountAmount DECIMAL(18, 2) DEFAULT 0 CHECK (DiscountAmount >= 0)
);

-- 12. Payment
CREATE TABLE Payment (
    PaymentID INT IDENTITY(1,1) PRIMARY KEY,
    SalesOrderID INT NOT NULL FOREIGN KEY REFERENCES SalesOrder(SalesOrderID),
    PaymentDate DATETIME DEFAULT GETDATE(),
    PaymentMethod NVARCHAR(20) NOT NULL, -- Card, Cash, etc.
    PaymentAmount DECIMAL(18, 2) NOT NULL CHECK (PaymentAmount > 0),
    PaymentStatus NVARCHAR(20) NOT NULL CHECK (PaymentStatus IN ('Success', 'Failed'))
);

-- 13. Returns
CREATE TABLE CustomerReturn (
    ReturnID INT IDENTITY(1,1) PRIMARY KEY,
    SalesOrderLineID INT NOT NULL FOREIGN KEY REFERENCES SalesOrderLine(SalesOrderLineID),
    ReturnDate DATETIME DEFAULT GETDATE(),
    ReturnQuantity INT NOT NULL CHECK (ReturnQuantity > 0),
    ReturnReason NVARCHAR(200)
    -- Logic Note: Complex validation (Total Returns <= Sold Quantity) usually requires a Trigger or App Logic
);


-- 14. Inventory (Current Snapshot)
CREATE TABLE Inventory (
    InventoryID INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT NOT NULL FOREIGN KEY REFERENCES Product(ProductID),
    StoreID INT NOT NULL FOREIGN KEY REFERENCES Store(StoreID),
    QuantityOnHand INT NOT NULL DEFAULT 0,
    LastUpdated DATETIME DEFAULT GETDATE(),
    CONSTRAINT UQ_Product_Store UNIQUE (ProductID, StoreID) 
    -- Critical: A product can only appear once per store.
);

-- 15. InventoryTransaction (The Audit Trail)
CREATE TABLE InventoryTransaction (
    TransactionID INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT NOT NULL FOREIGN KEY REFERENCES Product(ProductID),
    StoreID INT NOT NULL FOREIGN KEY REFERENCES Store(StoreID),
    TransactionDate DATETIME DEFAULT GETDATE(),
    
    TransactionType NVARCHAR(20) NOT NULL CHECK (TransactionType IN ('Sale', 'Restock', 'Return', 'Adjustment')),
    QuantityChange INT NOT NULL, -- Can be negative (Sale) or positive (Restock)
    
    -- LEAK PREVENTION: Lineage Columns
    -- These are nullable because a transaction comes from EITHER a Sale OR a Shipment
    ReferenceSalesLineID INT NULL FOREIGN KEY REFERENCES SalesOrderLine(SalesOrderLineID),
    ReferenceShipmentLineID INT NULL FOREIGN KEY REFERENCES InboundShipmentLine(ShipmentLineID),
    ReferenceReturnID INT NULL FOREIGN KEY REFERENCES CustomerReturn(ReturnID)
);
