CREATE OR ALTER TRIGGER trg_Sync_Inventory_Master
ON InventoryTransaction
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- We use MERGE to handle both "New Items" and "Existing Items" in one go.
    -- This also handles BULK INSERTS (e.g., loading 1000 sales at once).
    MERGE INTO Inventory AS Target
    USING (
        SELECT ProductID, StoreID, SUM(QuantityChange) as TotalChange
        FROM inserted
        GROUP BY ProductID, StoreID
    ) AS Source
    ON Target.ProductID = Source.ProductID AND Target.StoreID = Source.StoreID

    -- Scenario A: The item exists in this store. Update the count.
    WHEN MATCHED THEN
        UPDATE SET 
            Target.QuantityOnHand = Target.QuantityOnHand + Source.TotalChange,
            Target.LastUpdated = GETDATE()

    -- Scenario B: The item is new to this store. Create the record.
    WHEN NOT MATCHED THEN
        INSERT (ProductID, StoreID, QuantityOnHand, LastUpdated)
        VALUES (Source.ProductID, Source.StoreID, Source.TotalChange, GETDATE());

END;
GO