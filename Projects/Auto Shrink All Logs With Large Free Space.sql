USE DBAADMIN
GO
IF OBJECT_ID('dbo.dbasp_ShrinkAllLargeLogs') IS NOT NULL
	DROP PROCEDURE dbo.dbasp_ShrinkAllLargeLogs
GO

CREATE PROCEDURE	dbo.dbasp_ShrinkAllLargeLogs
	(
	@MinLogSize_MB	INT = 1000	-- LOG SIZE DEFALT MINIMUM IS 1GB
	,@MinLogFreePct	INT = 50	-- LOG PERCENT FREE MINIMUM IS 50%
	)
AS
BEGIN
		SET NOCOUNT ON

		PRINT	'-- CHECK DB LOGS FOR NEEDED SHRINKING'
			
		DECLARE		@TSQL		VARCHAR(max)
					,@CMD		VARCHAR(max)
					,@DBName	SYSNAME
					,@LogName	SYSNAME
					,@Env		SYSNAME
					,@Size		FLOAT
					,@Free		FLOAT
					,@Ratio		FLOAT

		IF OBJECT_ID('Tempdb..#LogFileSpace') IS NOT NULL
			DROP TABLE #LogFileSpace

		CREATE		TABLE		#LogFileSpace
				(
				[DATABASE_NAME]		SYSNAME
				,[LOGFILE_NAME]		SYSNAME
				,[CurrentSizeMB]	FLOAT
				,[FreeSpaceMB]		FLOAT
				)

		SELECT	@Env = env_detail
		FROM	dbaadmin.dbo.Local_ServerEnviro
		WHERE	env_type = 'ENVname'

		IF		@Env = 'Production'
			PRINT	' -- PRODUCTION: MINIMAL SHRINKING METHOD USED.'

		SET		@TSQL	= CASE @Env
		WHEN 'Production' 
		THEN
		'USE [$DBNAME$];
		PRINT ''  -- SHRINKING LOG FOR $DBNAME$'' 
		PRINT ''    -- BEFORE: $DBNAME$:$LOGNAME$ Size=$SIZE$ Free=$FREE$ RATIO=$RATIO$''  
		DBCC SHRINKFILE (N''$LOGNAME$'') WITH NO_INFOMSGS ;'
		ELSE
		'USE [MASTER];
		BACKUP LOG [$DBNAME$] WITH TRUNCATE_ONLY;
		USE [$DBNAME$];
		DBCC SHRINKFILE (N''$LOGNAME$'' , 0, TRUNCATEONLY) WITH NO_INFOMSGS ;
		DBCC SHRINKFILE (N''$LOGNAME$'' , 0, NOTRUNCATE) WITH NO_INFOMSGS ;
		DBCC SHRINKFILE (N''$LOGNAME$'' , 0, TRUNCATEONLY) WITH NO_INFOMSGS ;'
		END
		+CHAR(13)+CHAR(10)+
		'DECLARE	@Size float, @Free Float, @Ratio float
		SELECT		@Size		=size/128.0
					,@Free		=size/128.0 - CAST(FILEPROPERTY(name, ''SpaceUsed'') AS INT)/128.0
					,@Ratio		=(@Free*100.0)/@Size
		FROM		sys.master_files
		WHERE		name = ''$LOGNAME$''
			AND		database_id = DB_ID()
		PRINT ''    -- AFTER:  $DBNAME$:$LOGNAME$ Size=''+CAST(@Size AS VarChar(10))+'' Free=''+CAST(@Free AS VarChar(10))+'' RATIO=''+CAST(@Ratio AS VarChar(10))'

		EXEC	sp_MsForEachDB
		'USE [?];
		INSERT INTO	#LogFileSpace
		SELECT		DB_NAME(database_id)
					,name
					,size/128.0 
					,size/128.0 - CAST(FILEPROPERTY(name, ''SpaceUsed'') AS INT)/128.0
		FROM		sys.master_files
		WHERE		type = 1	-- LOG FILES
			AND		state = 0	-- ONLINE
			AND		database_id = DB_ID()'

		DECLARE LogFileCursor CURSOR KEYSET
		FOR
		SELECT		[DATABASE_NAME]
					,[LOGFILE_NAME]
					,[CurrentSizeMB]
					,[FreeSpaceMB]	
					,([FreeSpaceMB]*100.0)/[CurrentSizeMB]
		FROM		#LogFileSpace
		WHERE		[FreeSpaceMB] >= @MinLogSize_MB
				AND	([FreeSpaceMB] * 100) / [CurrentSizeMB] >= @MinLogFreePct
		OPEN LogFileCursor

		IF  @@CURSOR_ROWS = 0 PRINT '  --  ALL DATABASES ARE GOOD, NO SHRINKING PERFORMED.'
		FETCH NEXT FROM LogFileCursor INTO @DBName,@LogName,@Size,@Free,@Ratio	
		WHILE (@@fetch_status <> -1)					   	
		BEGIN											   
			IF (@@fetch_status <> -2)
			BEGIN
				SET @CMD = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@TSQL,'$DBNAME$',@DBName),'$LOGNAME$',@LogName),'$SIZE$',CAST(@Size AS VarChar(10))),'$FREE$',CAST(@Free AS VarChar(10))),'$RATIO$',CAST(@Ratio AS VarChar(10)))
				EXEC (@CMD)

			END
			FETCH NEXT FROM LogFileCursor INTO @DBName,@LogName,@Size,@Free,@Ratio
		END

		CLOSE LogFileCursor
		DEALLOCATE LogFileCursor

		IF OBJECT_ID('Tempdb..#LogFileSpace') IS NOT NULL
			DROP TABLE #LogFileSpace
END
GO

/*
USE [master]
GO
ALTER DATABASE [test] MODIFY FILE ( NAME = N'test_log', SIZE = 1433600KB )
GO
USE [dbaadmin]
GO
exec dbaadmin.dbo.dbasp_ShrinkAllLargeLogs 1000,50
GO
*/






