SELECT 
    TABLE_NAME AS [Table], 
    COLUMN_NAME AS [Column], 
    DATA_TYPE AS [Type], 
    IS_NULLABLE AS [Nullable],
    CHARACTER_MAXIMUM_LENGTH AS [MaxLen]
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo' -- or your specific schema name
ORDER BY TABLE_NAME, ORDINAL_POSITION;


---------------------------------------------------------------------

SELECT 
    fk.name AS [FK_Name],
    tp.name AS [Parent_Table],
    cp.name AS [Parent_Column],
    tr.name AS [Referenced_Table],
    cr.name AS [Referenced_Column]
FROM sys.foreign_keys AS fk
INNER JOIN sys.foreign_key_columns AS fkc ON fk.object_id = fkc.constraint_object_id
INNER JOIN sys.tables AS tp ON fkc.parent_object_id = tp.object_id
INNER JOIN sys.columns AS cp ON fkc.parent_object_id = cp.object_id AND fkc.parent_column_id = cp.column_id
INNER JOIN sys.tables AS tr ON fkc.referenced_object_id = tr.object_id
INNER JOIN sys.columns AS cr ON fkc.referenced_object_id = cr.object_id AND fkc.referenced_column_id = cr.column_id;






----------------------------------------------------------------------------------------------------------------------------

SELECT 
    tc.TABLE_NAME,
    kcu.COLUMN_NAME
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu 
    ON tc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME
WHERE tc.CONSTRAINT_TYPE = 'PRIMARY KEY'
ORDER BY tc.TABLE_NAME;