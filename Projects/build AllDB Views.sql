
DECLARE		@TSQL1				VarChar(max)
			,@TSQL2				VarChar(max)
			--,@DatabaseName		sysname
			,@SchemaName		sysname
			,@TableName			sysname
			,@Age				INT	
-------------------------------------------------------
--  REBUILD ALL ALLDB VIEWS USED IN THIS PROCESS     --
-------------------------------------------------------
SET			@Age				= 10

BEGIN
	DECLARE CreateAllDBViews CURSOR
	FOR
	SELECT 'sys','tables'
	UNION ALL
	SELECT 'sys','schemas'
	UNION ALL
	SELECT 'sys','sysindexes'
	UNION ALL
	SELECT 'sys','indexes'
	UNION ALL
	SELECT 'sys','dm_db_partition_stats'
	UNION ALL
	SELECT 'sys','allocation_units'
	UNION ALL
	SELECT 'sys','partitions'
	UNION ALL
	SELECT 'sys','columns'
	UNION ALL
	SELECT 'sys','index_columns'
	UNION ALL
	SELECT 'sys','foreign_keys'
	UNION ALL
	SELECT 'sys','foreign_key_columns'
	UNION ALL
	SELECT 'sys','objects'
	UNION ALL
	SELECT 'sys','stats'

	OPEN CreateAllDBViews
	FETCH NEXT FROM CreateAllDBViews INTO @SchemaName,@TableName
	WHILE (@@fetch_status <> -1)
	BEGIN
		#-BeginDebug CHECK EXISTANCE OF OBJECTS
		
			SELECT @TSQL1 = 'dbaadmin: '+Name+'('+Type+') AGE:'+CAST(DATEDIFF(minute,create_date,GetDate()) AS, 
			FROM dbaadmin.sys.objects WHERE name = 'vw_AllDB_'+@TableName
			SELECT Name,Type,create_date FROM dbaperf.sys.objects WHERE name = 'vw_AllDB_'+@TableName
		
		#-EndDebug
		IF (@@fetch_status <> -2)
		AND (
				NOT EXISTS (SELECT 1 FROM dbaadmin.sys.objects WHERE Type = 'V' AND DATEDIFF(minute,create_date,GetDate()) < @Age AND name = 'vw_AllDB_'+@TableName)
			OR	NOT EXISTS (SELECT 1 FROM dbaperf.sys.objects WHERE Type = 'SN' AND DATEDIFF(minute,create_date,GetDate()) < @Age AND name = 'vw_AllDB_'+@TableName)
			)
		BEGIN
			
			SET		@TSQL1	= 'IF OBJECT_ID(''[dbo].[vw_AllDB_'+@TableName+']'',''V'') IS NOT NULL'
							+ CHAR(13)+CHAR(10)
							+ 'DROP VIEW [dbo].[vw_AllDB_'+@TableName+']' 
							
			SET		@TSQL2	= 'USE [dbaadmin];'
							+ CHAR(13)+CHAR(10)
							+ 'EXEC (''' + REPLACE(@TSQL1,'''','''''') + ''')'
			
			PRINT 'Dropping [vw_AllDB_'+@TableName+'] View in dbaadmin.'
			EXEC	(@TSQL2)

			SET		@TSQL2	= 'USE [dbaperf];'
							+ CHAR(13)+CHAR(10)
							+ 'EXEC (''' + REPLACE(@TSQL1,'''','''''') + ''')'
			
			PRINT 'Dropping [vw_AllDB_'+@TableName+'] View in dbaperf.'
			EXEC	(@TSQL2)
			
			SET		@TSQL1	= 'IF OBJECT_ID(''[dbo].[vw_AllDB_'+@TableName+']'',''SN'') IS NOT NULL'
							+ CHAR(13)+CHAR(10)
							+ 'DROP SYNONYM [dbo].[vw_AllDB_'+@TableName+']' 
							
			SET		@TSQL2	= 'USE [dbaperf];'
							+ CHAR(13)+CHAR(10)
							+ 'EXEC (''' + REPLACE(@TSQL1,'''','''''') + ''')'
			
			PRINT 'Dropping [vw_AllDB_'+@TableName+'] Synonym in dbaperf.'
			EXEC	(@TSQL2)			
		
			
			SET		@TSQL1	= 'CREATE VIEW [dbo].[vw_AllDB_'+@TableName+'] AS' +CHAR(13)+CHAR(10)+'SELECT	''master'' AS database_name, DB_ID(''master'') AS database_id, * From [master].['+@SchemaName+'].['+@TableName+']'+CHAR(13)+CHAR(10)
			SELECT	@TSQL1	= @TSQL1 
							+ 'UNION ALL'
							+ CHAR(13)+CHAR(10)
							+ 'SELECT	'''+name+''', DB_ID('''+name+'''), * From ['+name+'].['+@SchemaName+'].['+@TableName+']'
							+ CHAR(13)+CHAR(10)
			FROM	master.sys.databases
			WHERE	name != 'master'

			SET		@TSQL2	= 'USE [dbaadmin];'
							+ CHAR(13)+CHAR(10)
							+ 'EXEC (''' + REPLACE(@TSQL1,'''','''''') + ''')'
			
			PRINT 'Creating [vw_AllDB_'+@TableName+'] View in dbaadmin.'
			EXEC	(@TSQL2)


			SET		@TSQL1	= 'CREATE SYNONYM [dbo].[vw_AllDB_'+@TableName+'] FOR [dbaadmin].[dbo].[vw_AllDB_'+@TableName+']' 
							
			SET		@TSQL2	= 'USE [dbaperf];'
							+ CHAR(13)+CHAR(10)
							+ 'EXEC (''' + REPLACE(@TSQL1,'''','''''') + ''')'
							
			PRINT 'Creating [vw_AllDB_'+@TableName+'] Synonym in dbaperf.'
			EXEC	(@TSQL2)		


		END
		ELSE PRINT '[vw_AllDB_'+@TableName+'] Parts are Recent: Nothing Done.'
		FETCH NEXT FROM CreateAllDBViews INTO @SchemaName,@TableName
	END

	CLOSE CreateAllDBViews
	DEALLOCATE CreateAllDBViews    
END
