use master
go
CREATE PROCEDURE [sp_FixOwner_DBRoles] 
AS
DECLARE DB_Role_Cursor CURSOR
FOR
select		name 
From		sys.database_principals 
WHERE		type_desc = 'DATABASE_ROLE' 
	AND		ISNULL(owning_principal_id,1) != 1

DECLARE @name sysname
DECLARE	@TSQL	Varchar(max)

OPEN DB_Role_Cursor

PRINT DB_NAME()
PRINT ' starting...'

FETCH NEXT FROM DB_Role_Cursor INTO @name
WHILE (@@fetch_status <> -1)
BEGIN
	IF (@@fetch_status <> -2)
	BEGIN
		SET @TSQL = '  ALTER AUTHORIZATION ON ROLE::['+@name+'] TO [dbo]'
		PRINT @TSQL
		EXEC (@TSQL)

	END
	FETCH NEXT FROM DB_Role_Cursor INTO @name
END
PRINT ' done.'

CLOSE DB_Role_Cursor
DEALLOCATE DB_Role_Cursor
GO

exec sp_msForEachDB 'Use [?];exec sp_FixOwner_DBRoles'

GO

DROP Procedure [sp_FixOwner_DBRoles] 
GO

