DECLARE		@BackupDrive		CHAR(1)
DECLARE		@BackupPath			VarChar(2000)
DECLARE		@BackupDB			SYSNAME
DECLARE		@RestoreDB			SYSNAME
DECLARE		@FileNameAdd		VarChar(50)
DECLARE		@TSQL				nVARCHAR(4000)
DECLARE		@Params				nVarChar(4000)
DECLARE		@CheckDB			SYSNAME
DECLARE		@SequenceID			INT
DECLARE		@NewDBMethod		INT
DECLARE		@CmdStr				varchar(255)
DECLARE		@object				int
DECLARE		@hr					int	
DECLARE		@ScriptType			bigint
SET NOCOUNT ON

SELECT		TOP 1
			@BackupDrive		= DriveLetter
			,@NewDBMethod		= 0				-- 0=NONE
												-- 1=GENERIC CREATE
												-- 2=CREATE FROM EXISTING
												-- 3=BACKUP AND RESTORE FROM EXISTING
			,@BackupDB			= 'AssetUsage'
			,@RestoreDB			= 'AssetUsage_Archive'
			,@FileNameAdd		= '_Archive' -- ONLY USED IF FILENAME DOES NOT CONTAIN DBNAME EXACTLY
			,@SequenceID		= 15
			,@BackupPath		= @BackupDrive+':\'+@BackupDB+'.bak'
			,@ScriptType		=	-- -1|		-- SQLDMOScript_/UseQuotedIdentifiers	-- Use quote characters to delimit identifier parts when scripting object names.			
									-- 1|		-- SQLDMOScript_Drops					-- Generate Transact-SQL to remove referenced component. Script tests for existence prior attempt to remove component.
									-- 2|		-- SQLDMOScript_/ObjectPermissions		-- Include Transact-SQL privilege defining statements when scripting database objects.
									4|			-- SQLDMOScript_Default					-- SQLDMOScript_PrimaryObject		-- Generate Transact-SQL creating the referenced component.
									-- 32|		-- SQLDMOScript_/DatabasePermissions	-- Generate Transact-SQL database privilege defining script. Database permissions grant or deny statement execution rights.
									-- 34|		-- SQLDMOScript_Permissions				-- SQLDMOScript_ObjectPermissions and SQLDMOScript_DatabasePermissions combined using an OR logical operator.
									-- 64|		-- SQLDMOScript_ToFileOnly				-- Most SQL-DMO object scripting methods specify both a return value and an optional output file. When used, and an output file is specified, the method does not return the script to the caller, but only writes the script to the output file.
									-- 4096|	-- SQLDMOScript_/IncludeIfNotExists		-- Transact-SQL creating a component is prefixed by a check for existence. When script is executed, component is created only when a copy of the named component does not exist.
									-- 73736|	-- SQLDMOScript_Indexes					-- SQLDMOScript_ClusteredIndexes, SQLDMOScript_NonClusteredIndexes, and SQLDMOScript_DRIIndexes combined using an OR logical operator. Applies to both table and view objects.
									32768|		-- SQLDMOScript_/NoCommandTerm			-- Individual Transact-SQL statements in the script are not delimited using the connection-specific command terminator. By default, individual Transact-SQL statements are delimited.
									-- 131072|	-- SQLDMOScript_/IncludeHeaders			-- Generated script is prefixed with a header containing date and time of generation and other descriptive information.
									262144|		-- SQLDMOScript_/OwnerQualify			-- Object names in Transact-SQL generated to remove an object are qualified by the owner of the referenced object. Transact-SQL generated to create the referenced object qualify the object name using the current object owner.
									-- 524288|	-- SQLDMOScript_/TimestampToBinary		-- When scripting object creation for a table or user-defined data type, convert specification of timestamp data type to binary(8).
									0
FROM		(
			SELECT		*
			FROM		(
						select		TOP 1
									0 [Order]
									, DriveLetter
						from		dbaadmin.dbo.dbaudf_listdrives() 
						WHERE		VolumeName like '%backup%'
						ORDER BY AvailableSpace desc
						) T1
			UNION
			SELECT		*
			FROM		(
						select		TOP 1
									1 [Order]
									, DriveLetter
						from		dbaadmin.dbo.dbaudf_listdrives() 
						WHERE DriveLetter != 'C'
						ORDER BY AvailableSpace desc
						) T1
			) T1
ORDER BY	[Order]			

IF	-- GENERIC CREATE
		DB_ID(@RestoreDB) IS NULL 
	AND @NewDBMethod = 1
BEGIN
	PRINT	'Creating Database ['+@RestoreDB+'] In Default Locations'
	PRINT	''

	SET @TSQL = 'CREATE DATABASE ['+@RestoreDB+']'
	EXEC (@TSQL) 

END
IF	-- CREATE FROM EXISTING
		DB_ID(@RestoreDB) IS NULL 
	AND DB_ID(@BackupDB) IS NOT NULL 
	AND @NewDBMethod = 2 
BEGIN
	PRINT	'Creating Database ['+@RestoreDB+'] using ['+@RestoreDB+'] as a template'
	PRINT	''

	SELECT		@CmdStr		= 'Connect('+@@SERVERNAME+')'
	EXEC @hr = sp_OACreate 'SQLDMO.SQLServer', @object OUT
	EXEC @hr = sp_OASetProperty @object, 'LoginSecure', TRUE
	EXEC @hr = sp_OAMethod @object,@CmdStr

	SELECT		@CmdStr	= 'Databases("' + @BackupDB + '").Script'
	EXEC @hr = sp_OAMethod @object, @CmdStr, @TSQL OUTPUT,@ScriptType
	EXEC @hr = sp_OADestroy @object

	SELECT		@TSQL = LEFT(@TSQL,CHARINDEX(CHAR(13)+CHAR(10)+'GO'+CHAR(13)+CHAR(10),@TSQL))
				,@TSQL = REPLACE(@TSQL,',',CHAR(13)+CHAR(10)+CHAR(9)+CHAR(9)+',')
				,@TSQL = REPLACE(@TSQL,'(NAME =','('+CHAR(13)+CHAR(10)+CHAR(9)+CHAR(9)+'NAME =')
				,@TSQL = REPLACE(@TSQL,'(',CHAR(13)+CHAR(10)+CHAR(9)+CHAR(9)+'(')
				,@TSQL = REPLACE(@TSQL,')',CHAR(13)+CHAR(10)+CHAR(9)+CHAR(9)+')')
				,@TSQL = REPLACE(@TSQL,']  ON',']'+CHAR(13)+CHAR(10)+CHAR(9)+'ON')
				,@TSQL = REPLACE(@TSQL,'LOG ON',CHAR(13)+CHAR(10)+CHAR(9)+'LOG ON')
				,@TSQL = REPLACE(@TSQL,@BackupDB,@RestoreDB)

	SELECT		@TSQL = REPLACE(@TSQL,[OldName],[NewName])
	FROM		(
				SELECT		physical_name AS [OldName]
							,CASE WHEN physical_name LIKE '%'+@BackupDB+'%' THEN REPLACE(physical_name,@BackupDB,@RestoreDB)
										ELSE REVERSE(STUFF(REVERSE(physical_name),5,LEN(@FileNameAdd),REVERSE(@FileNameAdd)))
										END AS [NewName]
				FROM		sys.master_files
				WHERE		database_id = DB_ID(@BackupDB)
				) T1

	--PRINT	@TSQL
	EXEC	(@TSQL)

END
IF	-- BACKUP AND RESTORE FROM EXISTING
		DB_ID(@RestoreDB) IS NULL 
	AND	DB_ID(@BackupDB) IS NOT NULL 
	AND	@NewDBMethod = 3 
BEGIN	

	PRINT	'Backing up '+@BackupDB+' to '+@BackupPath
	PRINT	''

	BACKUP DATABASE @BackupDB 
		TO DISK = @BackupPath 
		WITH	NOFORMAT
				,NOINIT
				,NAME = N'Full Database Backup'
				,SKIP
				,NOREWIND
				,NOUNLOAD
				,STATS = 10

	SELECT		@TSQL	= 'RESTORE	DATABASE ['+@RestoreDB+']'+CHAR(13)+CHAR(10) 
						+ 'FROM	DISK = N'''+@BackupPath+''''+CHAR(13)+CHAR(10) 
						+ 'WITH	FILE = 1'+CHAR(13)+CHAR(10)

	SELECT		@TSQL	= @TSQL
						+ '		,MOVE N'''+name+''' TO N'''
						+ CASE WHEN physical_name LIKE '%'+@BackupDB+'%' THEN REPLACE(physical_name,@BackupDB,@RestoreDB)
							ELSE REVERSE(STUFF(REVERSE(physical_name),5,LEN(@FileNameAdd),REVERSE(@FileNameAdd)))
							END
						+ ''''+CHAR(13)+CHAR(10)
	FROM		sys.master_files
	WHERE		database_id = DB_ID(@BackupDB)

	SELECT		@TSQL	= @TSQL
						+ '		,NOUNLOAD'+CHAR(13)+CHAR(10)
						+ '		,STATS = 10'+CHAR(13)+CHAR(10)

	PRINT	'Restoring '+@RestoreDB+' from '+@BackupPath
	PRINT	''
	--PRINT	(@TSQL) 
	EXEC	(@TSQL)

	PRINT	'Deleting Backup File '+@BackupPath
	PRINT	''
	SET		@TSQL = 'DEL ' + @BackupPath
	EXEC	xp_CmdShell @TSQL
END

-- IDENTIFY FIRST DATABASE TO START CLEANING
IF		DB_ID('dbaadmin') IS NOT NULL
	SET @CheckDB = 'dbaadmin'
ELSE IF	DB_ID('deplinfo') IS NOT NULL
	SET @CheckDB = 'deplinfo'
ELSE IF	DB_ID('deplcontrol') IS NOT NULL
	SET @CheckDB = 'deplcontrol'
ELSE IF	DB_ID('gears') IS NOT NULL
	SET @CheckDB = 'gears'		
ELSE GOTO Done4
	
CloneRecordsINDB:
BEGIN

	PRINT	'Cloning Controll Records in '+@CheckDB+'...'

	BEGIN PRINT	'  Checking Table [Clean_Security_Logins]'
	SELECT	@Params	= '@BackupDB SYSNAME, @RestoreDB SYSNAME'
			,@TSQL	= 'USE ' + @CheckDB +CHAR(13)+CHAR(10)
					+ '	IF OBJECT_ID(''[Clean_Security_Logins]'') IS NOT NULL
	 IF EXISTS (SELECT * FROM [Clean_Security_Logins] WHERE [DBname] = @BackupDB OR [DfltDB] = @BackupDB)
	  IF NOT EXISTS (SELECT * FROM [Clean_Security_Logins] WHERE [DBname] = @RestoreDB OR [DfltDB] = @RestoreDB)
		BEGIN
			PRINT	''    Cloning Table [Clean_Security_Logins]''

			SELECT		* 
				INTO	[#Clean_Security_Logins] 
			FROM		[Clean_Security_Logins] 
			WHERE		[DBname] = @BackupDB
					OR	[DfltDB] = @BackupDB
					
			UPDATE		[#Clean_Security_Logins] 
					SET	[DBname] = @RestoreDB
			WHERE		[DBname] = @BackupDB

			UPDATE		[#Clean_Security_Logins] 
					SET	[DfltDB] = @RestoreDB
			WHERE		[DfltDB] = @BackupDB

			INSERT INTO [Clean_Security_Logins] 
			SELECT		* 
			FROM		[#Clean_Security_Logins]

			DROP TABLE	[#Clean_Security_Logins]
		END'
	EXEC sp_executesql @TSQL,@Params,@BackupDB,@RestoreDB
	END

	BEGIN PRINT	'  Checking Table [Clean_Security_Roles]'
	SELECT	@Params	= '@BackupDB SYSNAME, @RestoreDB SYSNAME'
			,@TSQL	= 'USE ' + @CheckDB +CHAR(13)+CHAR(10)
					+ '	IF OBJECT_ID(''[Clean_Security_Roles]'') IS NOT NULL
	 IF EXISTS (SELECT * FROM [Clean_Security_Roles] WHERE [DBname] = @BackupDB)
	  IF NOT EXISTS (SELECT * FROM [Clean_Security_Roles] WHERE [DBname] = @RestoreDB)
		BEGIN
			PRINT	''    Cloning Table [Clean_Security_Roles]''

			SELECT		* 
				INTO	[#Clean_Security_Roles] 
			FROM		[Clean_Security_Roles] 
			WHERE		[DBname] = @BackupDB;

			UPDATE		[#Clean_Security_Roles] 
				SET		[DBname] = @RestoreDB;
				
			INSERT INTO	[Clean_Security_Roles] 
			SELECT		* 
			FROM		[#Clean_Security_Roles];

			DROP TABLE	[#Clean_Security_Roles];
		END'
	EXEC sp_executesql @TSQL,@Params,@BackupDB,@RestoreDB
	END

	BEGIN PRINT	'  Checking Table [db_BaseLocation]'
	SELECT	@Params	= '@BackupDB SYSNAME, @RestoreDB SYSNAME'
			,@TSQL	= 'USE ' + @CheckDB +CHAR(13)+CHAR(10)
					+ '	IF OBJECT_ID(''[db_BaseLocation]'') IS NOT NULL
	 IF EXISTS (SELECT * FROM [db_BaseLocation] WHERE [db_name] = @BackupDB)
	  IF NOT EXISTS (SELECT * FROM [db_BaseLocation] WHERE [db_name] = @RestoreDB)
		BEGIN
			PRINT	''    Cloning Table [db_BaseLocation]''

			SELECT		* 
				INTO	[#db_BaseLocation] 
			FROM		[db_BaseLocation] 
			WHERE		[db_name] = @BackupDB;
			
			UPDATE		[#db_BaseLocation] 
				SET		[db_name] = @RestoreDB;
				
			INSERT INTO	[db_BaseLocation]
						(
						[db_name]
						,[companionDB_name]
						,[RSTRfolder]
						,[baseline_srvname]
						)
		 
			SELECT		[db_name]
						,[companionDB_name]
						,[RSTRfolder]
						,[baseline_srvname] 
			FROM		[#db_BaseLocation];
			
			DROP TABLE	[#db_BaseLocation];
		END'
	EXEC sp_executesql @TSQL,@Params,@BackupDB,@RestoreDB
	END

	BEGIN PRINT	'  Checking Table [db_sequence] with [db_name] Column'
	SELECT	@Params	= '@BackupDB SYSNAME, @RestoreDB SYSNAME'
			,@TSQL	= 'USE ' + @CheckDB +CHAR(13)+CHAR(10)
					+ '	IF OBJECT_ID(''[db_sequence]'') IS NOT NULL AND COL_NAME(OBJECT_ID(''[db_sequence]''),2) = ''db_name''
	 IF EXISTS (SELECT * FROM [db_sequence] WHERE [db_name] = @BackupDB)
	  IF NOT EXISTS (SELECT * FROM [db_sequence] WHERE [db_name] = @RestoreDB)
		BEGIN
			PRINT	''    Cloning Table [db_sequence]''

			SELECT		* 
				INTO	[#db_sequence] 
			FROM		[db_sequence] 
			WHERE		[db_name] = @BackupDB;
			
			UPDATE		[#db_sequence] 
				SET		[db_name] = @RestoreDB
						,[seq_id] = '''+CAST(@SequenceID AS VarChar(10))+'''
			
			INSERT INTO	[db_sequence] 
			SELECT		* 
			FROM		[#db_sequence];
			
			DROP TABLE	[#db_sequence];
		END'
	EXEC sp_executesql @TSQL,@Params,@BackupDB,@RestoreDB
	END

	BEGIN PRINT	'  Checking Table [db_sequence] with [DBName] Column'
	SELECT	@Params	= '@BackupDB SYSNAME, @RestoreDB SYSNAME'
			,@TSQL	= 'USE ' + @CheckDB +CHAR(13)+CHAR(10)
					+ '	IF OBJECT_ID(''[db_sequence]'') IS NOT NULL AND COL_NAME(OBJECT_ID(''[db_sequence]''),2) = ''DBName''
	 IF EXISTS (SELECT * FROM [db_sequence] WHERE [DBName] = @BackupDB)
	  IF NOT EXISTS (SELECT * FROM [db_sequence] WHERE [DBName] = @RestoreDB)
		BEGIN
			PRINT	''    Cloning Table [db_sequence]''

			SELECT		* 
				INTO	[#db_sequence] 
			FROM		[db_sequence] 
			WHERE		[DBName] = @BackupDB;
			
			UPDATE		[#db_sequence] 
				SET		[DBName] = @RestoreDB
						,[seq_id] = '''+CAST(@SequenceID AS VarChar(10))+'''
			
			INSERT INTO	[db_sequence] 
			SELECT		* 
			FROM		[#db_sequence];
			
			DROP TABLE	[#db_sequence];
		END'
	EXEC sp_executesql @TSQL,@Params,@BackupDB,@RestoreDB
	END

	BEGIN PRINT	'  Checking Table [db_ApplCrossRef]'
	SELECT	@Params	= '@BackupDB SYSNAME, @RestoreDB SYSNAME'
			,@TSQL	= 'USE ' + @CheckDB +CHAR(13)+CHAR(10)
					+ '	IF OBJECT_ID(''[db_ApplCrossRef]'') IS NOT NULL
	 IF EXISTS (SELECT * FROM [db_ApplCrossRef] WHERE [db_name] = @BackupDB)
	  IF NOT EXISTS (SELECT * FROM [db_ApplCrossRef] WHERE [db_name] = @RestoreDB)
		BEGIN
			PRINT	''    Cloning Table [db_ApplCrossRef]''
		
			SELECT		* 
				INTO	[#db_ApplCrossRef] 
			FROM		[db_ApplCrossRef] 
			WHERE		[db_name] = @BackupDB;
			
			UPDATE		[#db_ApplCrossRef] 
				SET		[db_name] = @RestoreDB;
			
			INSERT INTO [dbaadmin].[dbo].[db_ApplCrossRef]
						(
						[db_name]
						,[companionDB_name]
						,[RSTRfolder]
						,[Appl_desc]
						,[baseline_srvname]
						)
 			SELECT		[db_name]
						,[companionDB_name]
						,[RSTRfolder]
						,[Appl_desc]
						,[baseline_srvname] 
			FROM		[#db_ApplCrossRef];
			
			DROP TABLE	[#db_ApplCrossRef];
		END'
	EXEC sp_executesql @TSQL,@Params,@BackupDB,@RestoreDB
	END

	BEGIN PRINT	'  Checking Table [Base_Appl_Info]'
	SELECT	@Params	= '@BackupDB SYSNAME, @RestoreDB SYSNAME'
			,@TSQL	= 'USE ' + @CheckDB +CHAR(13)+CHAR(10)
					+ 'IF OBJECT_ID(''[Base_Appl_Info]'') IS NOT NULL
	 IF EXISTS (SELECT * FROM [Base_Appl_Info] WHERE [DBname] = @BackupDB)
	  IF NOT EXISTS (SELECT * FROM [Base_Appl_Info] WHERE [DBname] = @RestoreDB)
		BEGIN
			PRINT	''    Cloning Table [Base_Appl_Info]''

			SELECT		* 
				INTO	[#Base_Appl_Info] 
			FROM		[Base_Appl_Info] 
			WHERE		[DBname] = @BackupDB;
			
			UPDATE		[#Base_Appl_Info] 
				SET		[DBname] = @RestoreDB;
			
			INSERT INTO [DEPLcontrol].[dbo].[Base_Appl_Info]
						(
						[DBname]
						,[CompanionDB_name]
						,[APPLname]
						,[BASEfolder]
						,[SQLname]
						,[baseline_srvname]
						,[ENVnum]
						,[Domain]
						,[moddate]
						)
			SELECT		[DBname]
						,[CompanionDB_name]
						,[APPLname]
						,[BASEfolder]
						,[SQLname]
						,[baseline_srvname]
						,[ENVnum]
						,[Domain]
						,[moddate] 
			FROM		[#Base_Appl_Info];
			
			DROP TABLE	[#Base_Appl_Info];
		END'
	EXEC sp_executesql @TSQL,@Params,@BackupDB,@RestoreDB
	END

	BEGIN PRINT	'  Checking Table [DataSync_target_table]'
	SELECT	@Params	= '@BackupDB SYSNAME, @RestoreDB SYSNAME'
			,@TSQL	= 'USE ' + @CheckDB +CHAR(13)+CHAR(10)
					+ 'IF OBJECT_ID(''[DataSync_target_table]'') IS NOT NULL
	 IF EXISTS (SELECT * FROM [DataSync_target_table] WHERE [DatabaseName] = @BackupDB)
	  IF NOT EXISTS (SELECT * FROM [DataSync_target_table] WHERE [DatabaseName] = @RestoreDB)
		BEGIN
			PRINT	''    Cloning Table [DataSync_target_table]''

			SELECT		* 
				INTO	[#DataSync_target_table] 
			FROM		[DataSync_target_table] 
			WHERE		[DatabaseName] = @BackupDB;
			
			UPDATE		[#DataSync_target_table] 
				SET		[DatabaseName] = @RestoreDB;
			
			INSERT INTO	[DataSync_target_table] 
			SELECT		* 
			FROM		[#DataSync_target_table];
			
			DROP TABLE	[#DataSync_target_table];
		END'
	EXEC sp_executesql @TSQL,@Params,@BackupDB,@RestoreDB
	END

	BEGIN PRINT	'  Checking Table [DEPL_Access_Ctrl]'
	SELECT	@Params	= '@BackupDB SYSNAME, @RestoreDB SYSNAME'
			,@TSQL	= 'USE ' + @CheckDB +CHAR(13)+CHAR(10)
					+ 'IF OBJECT_ID(''[DEPL_Access_Ctrl]'') IS NOT NULL
	 IF EXISTS (SELECT * FROM [DEPL_Access_Ctrl] WHERE [DBname] = @BackupDB)
	  IF NOT EXISTS (SELECT * FROM [DEPL_Access_Ctrl] WHERE [DBname] = @RestoreDB)
		BEGIN
			PRINT	''    Cloning Table [DEPL_Access_Ctrl]''

			SELECT		* 
				INTO	[#DEPL_Access_Ctrl] 
			FROM		[DEPL_Access_Ctrl] 
			WHERE		[DBname] = @BackupDB;
			
			UPDATE		[#DEPL_Access_Ctrl] 
				SET		[DBname] = @RestoreDB;
			
			INSERT INTO	[DEPL_Access_Ctrl] 
			SELECT		* 
			FROM		[#DEPL_Access_Ctrl];
			
			DROP TABLE	[#DEPL_Access_Ctrl];
		END'
	EXEC sp_executesql @TSQL,@Params,@BackupDB,@RestoreDB
	END

	BEGIN PRINT	'  Checking Table [DataSync_target_table]'
	SELECT	@Params	= '@BackupDB SYSNAME, @RestoreDB SYSNAME'
			,@TSQL	= 'USE ' + @CheckDB +CHAR(13)+CHAR(10)
					+ 'IF OBJECT_ID(''[DataSync_target_table]'') IS NOT NULL
	 IF EXISTS (SELECT * FROM [DataSync_target_table] WHERE [DatabaseName] = @BackupDB)
	  IF NOT EXISTS (SELECT * FROM [DataSync_target_table] WHERE [DatabaseName] = @RestoreDB)
		BEGIN
			PRINT	''    Cloning Table [DataSync_target_table]''

			SELECT		* 
				INTO	[#DataSync_target_table] 
			FROM		[DataSync_target_table] 
			WHERE		[DatabaseName] = @BackupDB;
			
			UPDATE		[#DataSync_target_table] 
				SET		[DatabaseName] = @RestoreDB;
			
			INSERT INTO	[DataSync_target_table] 
			SELECT		* 
			FROM		[#DataSync_target_table];
			
			DROP TABLE	[#DataSync_target_table];
		END'
	EXEC sp_executesql @TSQL,@Params,@BackupDB,@RestoreDB
	END

	BEGIN PRINT	'  Checking Table [PostRestoreDataUpdate]'
	SELECT	@Params	= '@BackupDB SYSNAME, @RestoreDB SYSNAME'
			,@TSQL	= 'USE ' + @CheckDB +CHAR(13)+CHAR(10)
					+ 'IF OBJECT_ID(''[PostRestoreDataUpdate]'') IS NOT NULL
	 IF EXISTS (SELECT * FROM [PostRestoreDataUpdate] WHERE [DBName] = @BackupDB)
	  IF NOT EXISTS (SELECT * FROM [PostRestoreDataUpdate] WHERE [DBName] = @RestoreDB)
		BEGIN
			PRINT	''    Cloning Table [PostRestoreDataUpdate]''

			SELECT		* 
				INTO	[#PostRestoreDataUpdate] 
			FROM		[PostRestoreDataUpdate] 
			WHERE		[DBName] = @BackupDB;
			
			UPDATE		[#PostRestoreDataUpdate] 
				SET		[DBName] = @RestoreDB;
			
			INSERT INTO	[PostRestoreDataUpdate] 
			SELECT		* 
			FROM		[#PostRestoreDataUpdate];
			
			DROP TABLE	[#PostRestoreDataUpdate];
		END'
	EXEC sp_executesql @TSQL,@Params,@BackupDB,@RestoreDB
	END
	
	BEGIN PRINT	'  Checking Table [COMPONENTS]'

	SELECT	@Params	= '@BackupDB SYSNAME, @RestoreDB SYSNAME'
			,@TSQL	= 'USE ' + @CheckDB +CHAR(13)+CHAR(10)
					+ 'IF OBJECT_ID(''[COMPONENTS]'') IS NOT NULL
	 IF EXISTS (SELECT * FROM [COMPONENTS] WHERE [component_name] = @BackupDB)
	  IF NOT EXISTS (SELECT * FROM [COMPONENTS] WHERE [component_name] = @RestoreDB)
		BEGIN
			PRINT	''    Cloning Table [COMPONENTS]''

			SELECT		* 
				INTO	[#COMPONENTS] 
			FROM		[COMPONENTS] 
			WHERE		[component_name] = @BackupDB;
			
			UPDATE		[#COMPONENTS] 
				SET		[component_name] = @RestoreDB;
			
			INSERT INTO [gears].[dbo].[COMPONENTS]
						(
						[component_type_id]
						,[component_name]
						,[component_APPLname]
						,[component_web_msi_name]
						)
			SELECT		[component_type_id]
						,[component_name]
						,[component_APPLname]
						,[component_web_msi_name] 
			FROM		[#COMPONENTS];
			
			DROP TABLE	[#COMPONENTS];
		END'
		
	EXEC sp_executesql @TSQL,@Params,@BackupDB,@RestoreDB
	END
	
	BEGIN PRINT	'  Checking Table [PROJECT_COMPONENTS]'

	SELECT	@Params	= '@BackupDB SYSNAME, @RestoreDB SYSNAME'
			,@TSQL	= 'USE ' + @CheckDB +CHAR(13)+CHAR(10)
					+ 'IF OBJECT_ID(''[PROJECT_COMPONENTS]'') IS NOT NULL
	 IF EXISTS (SELECT * FROM [PROJECT_COMPONENTS] WHERE [component_id] = (SELECT [component_id] FROM [COMPONENTS] WHERE [component_name] = @BackupDB))
	  IF NOT EXISTS (SELECT * FROM [PROJECT_COMPONENTS] WHERE [component_id] = (SELECT [component_id] FROM [COMPONENTS] WHERE [component_name] = @RestoreDB))
		BEGIN
			PRINT	''    Cloning Table [PROJECT_COMPONENTS]''

			SELECT		* 
				INTO	[#PROJECT_COMPONENTS] 
			FROM		[PROJECT_COMPONENTS] 
			WHERE		[component_id] = (SELECT [component_id] FROM [COMPONENTS] WHERE [component_name] = @BackupDB);
			
			UPDATE		[#PROJECT_COMPONENTS] 
				SET		[component_id] = (SELECT [component_id] FROM [COMPONENTS] WHERE [component_name] = @RestoreDB);
			
			INSERT INTO [gears].[dbo].[PROJECT_COMPONENTS]
						(
						[project_id]
						,[component_id]
						)
 			SELECT		[project_id]
						,[component_id] 
			FROM		[#PROJECT_COMPONENTS];
			
			DROP TABLE	[#PROJECT_COMPONENTS];
		END'
		
	EXEC sp_executesql @TSQL,@Params,@BackupDB,@RestoreDB
	END

	
	
END


IF @CheckDB = 'dbaadmin'
	GOTO Done1
IF @CheckDB = 'deplinfo'
	GOTO Done2
IF @CheckDB = 'deplcontrol'
	GOTO Done3

GOTO Done4

Done1:
IF DB_ID('deplinfo') IS NOT NULL
BEGIN
	SET @CheckDB = 'deplinfo'
	GOTO CloneRecordsINDB
END

Done2:
IF DB_ID('deplcontrol') IS NOT NULL
BEGIN
	SET @CheckDB = 'deplcontrol'
	GOTO CloneRecordsINDB
END

Done3:
IF DB_ID('gears') IS NOT NULL
BEGIN
	SET @CheckDB = 'gears'
	GOTO CloneRecordsINDB
END

Done4:

-- MAKE SURE ALL DEPLOYMENT RELATED DB's HAVE THE BUILD TABLES
EXEC DBAADMIN.[dbo].[dbasp_create_buildtbl]

PRINT 'DONE....'


