CREATE SCHEMA gold;
GO

-- 1. Product Dimension (Combines Product and Category)
CREATE TABLE gold.dim_product (
    product_key INT IDENTITY(1,1) PRIMARY KEY,
    source_product_id INT NOT NULL,
    sku NVARCHAR(50),
    product_name NVARCHAR(100),
    category_name NVARCHAR(50),
    brand NVARCHAR(50),
    unit_price DECIMAL(18,2),
    standard_cost DECIMAL(18,2),
    is_discontinued BIT
);

-- 2. Store Dimension (The RLS Target)
CREATE TABLE gold.dim_store (
    store_key INT IDENTITY(1,1) PRIMARY KEY,
    source_store_id INT NOT NULL,
    store_name NVARCHAR(100),
    store_type NVARCHAR(20),
    city NVARCHAR(50),
    state NVARCHAR(50)
);

-- 3. Customer Dimension
CREATE TABLE gold.dim_customer (
    customer_key INT IDENTITY(1,1) PRIMARY KEY,
    source_customer_id INT NOT NULL,
    full_name NVARCHAR(101), -- Combined First + Last
    email NVARCHAR(100),
    gender CHAR(1),
    state NVARCHAR(50)
);

-- 4. Supplier Dimension
CREATE TABLE gold.dim_supplier (
    supplier_key INT IDENTITY(1,1) PRIMARY KEY,
    source_supplier_id INT NOT NULL,
    supplier_name NVARCHAR(100),
    contact_person NVARCHAR(100)
);

-- 5. Date Dimension (Standard for Time Intelligence)
CREATE TABLE gold.dim_date (
    date_key INT PRIMARY KEY, -- YYYYMMDD
    full_date DATE,
    year INT,
    quarter INT,
    month_name NVARCHAR(20),
    day_of_week NVARCHAR(20)
);



---------------------------------------------------------------------

-- 1. Sales Fact (Grain: SalesOrderLineID)
CREATE TABLE gold.fct_sales (
    sales_line_key INT IDENTITY(1,1) PRIMARY KEY,
    sales_order_line_id INT, -- Degenerate Dimension
    product_key INT REFERENCES gold.dim_product(product_key),
    store_key INT REFERENCES gold.dim_store(store_key),
    customer_key INT REFERENCES gold.dim_customer(customer_key),
    date_key INT REFERENCES gold.dim_date(date_key),
    quantity INT,
    unit_price DECIMAL(18,2),
    standard_cost DECIMAL(18,2),
    discount_amount DECIMAL(18,2),
    return_quantity INT DEFAULT 0
);

-- 2. Purchasing Fact (Grain: ShipmentLineID)
CREATE TABLE gold.fct_purchasing (
    purchasing_key INT IDENTITY(1,1) PRIMARY KEY,
    shipment_line_id INT,
    product_key INT REFERENCES gold.dim_product(product_key),
    supplier_key INT REFERENCES gold.dim_supplier(supplier_key),
    date_key INT REFERENCES gold.dim_date(date_key),
    qty_ordered INT,
    qty_received INT,
    lead_time_days INT -- Calculated as ActualArrival - OrderDate
);

-- 3. Inventory Fact (Grain: TransactionID)
CREATE TABLE gold.fct_inventory (
    inventory_key INT IDENTITY(1,1) PRIMARY KEY,
    transaction_id INT,
    product_key INT REFERENCES gold.dim_product(product_key),
    store_key INT REFERENCES gold.dim_store(store_key),
    date_key INT REFERENCES gold.dim_date(date_key),
    quantity_change INT,
    transaction_type NVARCHAR(20)
);

