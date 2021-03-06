USE [dbaperf]
GO
/****** Object:  StoredProcedure [dbo].[dbasp_extract_DriveAndDBUsage]    Script Date: 8/25/2014 9:23:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[dbasp_extract_DriveAndDBUsage]

/*********************************************************
 **  Stored Procedure dbasp_extract_DriveAndDBUsage
 **  Written by Steve Ledridge, Getty Images                
 **  July 15, 2014                                      
 **  
 **  This is intended to take snapshots of DB and Drive Usage
 **  so that forecasting and trending can be evaluated.
 **  data is stored into the 'Drive_Stats_Log' table which will
 **  be created if it doesnt already exist.
 **  @Export parameter toggles sending daily results to central server
 ***************************************************************/
AS
SET NOCOUNT ON

--	======================================================================================
--	Revision History
--	Date		Author     		Desc
--	==========	====================	=============================================
--	07/15/2014	Steve Ledridge		Procedure Created
--	08/18/2014	Steve Ledridge		Modified to make use of new ability to distinguish Mount Points in Changed dbasp_ListDrives()
--	08/19/2014	Jim Wilson		Added code to ignore secondary AvailGrp DB's.
--	08/25/2014	Steve Ledridge		Modified DB Space Usage Check to not error on File Groups with no objects. 
--	======================================================================================


DECLARE		@DBName			SYSNAME
		,@SnapshotDB		BIT
		,@SizeOnDisk		NUMERIC(38,10)
		,@FileSize		NUMERIC(38,10)
		,@CMD			nVarChar(4000)
		,@dbsize		BIGINT
		,@LogSize		BIGINT
		,@ReservedPages		BIGINT
		,@UsedPages		BIGINT
		,@DataPages		BIGINT
		,@IndexPages		BIGINT
		,@FileType		SYSNAME
		,@DataSpaceID		INT
		,@FileGroupName		SYSNAME
		,@DriveLetter		CHAR(1)
		,@DriveSize_GB		NUMERIC(38,10)
		,@DriveFree_GB		NUMERIC(38,10)
		,@FileCount		INT
		,@FileSize_GB		NUMERIC(38,10)
		,@Pct_Unused		FLOAT
		,@Pct_Data		FLOAT
		,@Pct_Index		FLOAT
		,@RunDate		DateTime
		,@FileName		VarChar(max)
		,@TableName		SYSNAME
		,@SCRIPT		VarChar(8000)
		,@Output_Path		VarChar(max)
		,@target_env		SYSNAME
		,@target_server		SYSNAME
		,@target_share		SYSNAME
		,@retry_limit		INT
		,@RC			INT
		,@Export		bit
		,@RootFolder		VarChar(max)


DECLARE		@Results		TABLE
		(
		RootFolder		VarChar(500) 
		,FileType		SYSNAME
		,DBName			SYSNAME
		,DataSpaceID		INT NULL
		,FileGroup		SYSNAME NULL
		,DriveSize_GB		NUMERIC(38,10)
		,DriveFree_GB		NUMERIC(38,10)
		,FileCount		INT
		,FileSize_GB		NUMERIC(38,10)
		,UnUsed_GB		NUMERIC(38,10)
		,Data_GB		NUMERIC(38,10)
		,Index_GB		NUMERIC(38,10)
		)

SELECT		@TableName	= 'Drive_Stats_Log'
		,@Output_Path	= '\\'+REPLACE(@@ServerName,'\'+@@ServiceName,'')+'\'+REPLACE(@@ServerName,'\','$')+'_dbasql\dba_reports'
		,@target_env	= 'amer'
		,@target_server	= 'SEAPDBASQL01'
		,@target_share	= 'SEAPDBASQL01_dbasql\DiskSpaceChecks'
		,@retry_limit	= 5
		,@RunDate	= CONVERT(VarChar(12),GetDate(),101)
		,@FileName	= REPLACE([dbaadmin].[dbo].[dbaudf_base64_encode] (@@SERVERNAME+'|'+REPLACE(@TableName,'dbaperf.dbo.',''))+'.dat','=','$')
		,@SCRIPT	= 'bcp "SELECT * FROM [dbaperf].[dbo].['+@TableName+'] WHERE [RunDate] = '''+CONVERT(VarChar(12),@RunDate,101)+'''" queryout "'+@Output_Path+'\'+@FileName+'" -S '+@@Servername+' -T -N'
		,@Export	= 1


DECLARE RootFolderCursor CURSOR
FOR
-- SELECT QUERY FOR CURSOR
SELECT		DISTINCT
		RootFolder
		,TotalSize/POWER(1024.0,3) AS [DriveSize_GB]
		,FreeSpace/POWER(1024.0,3) AS [DriveFree_GB]
FROM		dbaadmin.dbo.dbaudf_ListDrives()
WHERE		ISNULL(DriveLetter,'') != 'C:'
	AND	SUBSTRING(RootFolder,2,1) = ':' 
	AND	ISNULL(TotalSize,0) > 0
ORDER BY	RootFolder DESC

OPEN RootFolderCursor;
FETCH RootFolderCursor INTO @RootFolder,@DriveSize_GB,@DriveFree_GB;
WHILE (@@fetch_status <> -1)
BEGIN
	IF (@@fetch_status <> -2)
	BEGIN
		---------------------------- 
		---------------------------- CURSOR LOOP TOP
		IF (select @@version) not like '%Server 2005%' and (SELECT SERVERPROPERTY ('productversion')) > '11.0.0000' --sql2012 or higher
		   begin
			DECLARE DBCursor CURSOR
			FOR
			SELECT		CASE	WHEN T2.FullPathName LIKE '%\$RECYCLE.BIN\%' THEN 'RECYCLE BIN'
						WHEN T2.Name LIKE '%ERRORLOG%' THEN 'LOGFILE'
						WHEN T2.Name LIKE '%SQLAGENT%' THEN 'LOGFILE'
						WHEN T3.database_id IS NULL THEN CASE T2.Extension
											WHEN '.BAK'	THEN 'BACKUP'
											WHEN '.DIF'	THEN 'BACKUP'
											WHEN '.TRN'	THEN 'BACKUP'
											WHEN '.cBAK'	THEN 'BACKUP'
											WHEN '.cDIF'	THEN 'BACKUP'
											WHEN '.cTRN'	THEN 'BACKUP'
											WHEN '.SQB'	THEN 'BACKUP'
											WHEN '.SQD'	THEN 'BACKUP'
											WHEN '.SQT'	THEN 'BACKUP'

											WHEN '.LDF'	THEN 'DB_LOG'
											WHEN '.MDF'	THEN 'DB_ROWS'
											WHEN '.NDF'	THEN 'DB_ROWS'

											WHEN '.SQL'	THEN 'SCRIPT'
											WHEN '.GSQL'	THEN 'SCRIPT'
											WHEN '.sqlplan'	THEN 'SQL EXECUTION PLAN'

											WHEN '.CSV'	THEN 'DATAFILE'
											WHEN '.TAB'	THEN 'DATAFILE'
											WHEN '.XML'	THEN 'DATAFILE'
											WHEN '.dat'	THEN 'DATAFILE'
											WHEN '.tsv'	THEN 'DATAFILE'

											WHEN '.HTML'	THEN 'DOC'
											WHEN '.HTM'	THEN 'DOC'
											WHEN '.RPT'	THEN 'DOC'
											WHEN '.RTF'	THEN 'DOC'
											WHEN '.TXT'	THEN 'DOC'
							
											WHEN '.OUT'	THEN 'LOGFILE'
											WHEN '.LOG'	THEN 'LOGFILE'
											WHEN '.1'	THEN 'LOGFILE'
											WHEN '.2'	THEN 'LOGFILE'
											WHEN '.3'	THEN 'LOGFILE'
											WHEN '.4'	THEN 'LOGFILE'
											WHEN '.5'	THEN 'LOGFILE'
											WHEN '.w3c'	THEN 'LOGFILE'

											WHEN '.BLG'	THEN 'PERFMON FILE'
											WHEN '.mdmp'	THEN 'CRASH DUMP FILE'
											WHEN '.trc'	THEN 'SQL TRACE FILE'
											WHEN '.actn'	THEN 'FILE TRANSIT ACTION FILE'

											WHEN '.cmd'	THEN 'BATCH FILE'
											WHEN '.bat'	THEN 'BATCH FILE'
											WHEN '.exe'	THEN 'EXECUTABLE'

											WHEN '.ZIP'	THEN 'PACKAGE'
											WHEN '.RAR'	THEN 'PACKAGE'
											WHEN '.Z'	THEN 'PACKAGE'
											WHEN '.CAB'	THEN 'PACKAGE'
							
											ELSE 'OTHER'
											END
						ELSE ISNULL('DB_' + T3.type_desc,'')
						END AS [FileType]
					,ISNULL(DB_NAME(T3.database_id),'') DatabaseName
					,ISNULL(T3.data_space_id,0) data_space_id
					,count(*) AS [FileCount]
					,SUM(T2.size/power(1024.0,3)) AS [FileSize_GB]
			From		dbaadmin.[dbo].[dbaudf_DirectoryList2](@RootFolder,null,1) T2
			LEFT JOIN	sys.master_files T3
				ON	T3.physical_name = T2.FullPathName
			LEFT JOIN	(
					SELECT		DISTINCT
							RootFolder + '%' [RootFolder]
					FROM		@Results
					) T1
				ON	T2.Directory LIKE T1.RootFolder
			WHERE		T1.RootFolder IS NULL
			AND		DB_NAME(T3.database_id) not in (SELECT dbcs.database_name
									FROM master.sys.availability_groups AS AG
									LEFT OUTER JOIN master.sys.dm_hadr_availability_group_states as agstates
									   ON AG.group_id = agstates.group_id
									INNER JOIN master.sys.availability_replicas AS AR
									   ON AG.group_id = AR.group_id
									INNER JOIN master.sys.dm_hadr_availability_replica_states AS arstates
									   ON AR.replica_id = arstates.replica_id AND arstates.is_local = 1
									INNER JOIN master.sys.dm_hadr_database_replica_cluster_states AS dbcs
									   ON arstates.replica_id = dbcs.replica_id
									LEFT OUTER JOIN master.sys.dm_hadr_database_replica_states AS dbrs
									   ON dbcs.replica_id = dbrs.replica_id AND dbcs.group_database_id = dbrs.group_database_id
									where agstates.primary_replica <> @@servername)
			GROUP BY	CASE	WHEN T2.FullPathName LIKE '%\$RECYCLE.BIN\%' THEN 'RECYCLE BIN'
						WHEN T2.Name LIKE '%ERRORLOG%' THEN 'LOGFILE'
						WHEN T2.Name LIKE '%SQLAGENT%' THEN 'LOGFILE'
						WHEN T3.database_id IS NULL THEN CASE T2.Extension
											WHEN '.BAK'	THEN 'BACKUP'
											WHEN '.DIF'	THEN 'BACKUP'
											WHEN '.TRN'	THEN 'BACKUP'
											WHEN '.cBAK'	THEN 'BACKUP'
											WHEN '.cDIF'	THEN 'BACKUP'
											WHEN '.cTRN'	THEN 'BACKUP'
											WHEN '.SQB'	THEN 'BACKUP'
											WHEN '.SQD'	THEN 'BACKUP'
											WHEN '.SQT'	THEN 'BACKUP'

											WHEN '.LDF'	THEN 'DB_LOG'
											WHEN '.MDF'	THEN 'DB_ROWS'
											WHEN '.NDF'	THEN 'DB_ROWS'

											WHEN '.SQL'	THEN 'SCRIPT'
											WHEN '.GSQL'	THEN 'SCRIPT'
											WHEN '.sqlplan'	THEN 'SQL EXECUTION PLAN'

											WHEN '.CSV'	THEN 'DATAFILE'
											WHEN '.TAB'	THEN 'DATAFILE'
											WHEN '.XML'	THEN 'DATAFILE'
											WHEN '.dat'	THEN 'DATAFILE'
											WHEN '.tsv'	THEN 'DATAFILE'

											WHEN '.HTML'	THEN 'DOC'
											WHEN '.HTM'	THEN 'DOC'
											WHEN '.RPT'	THEN 'DOC'
											WHEN '.RTF'	THEN 'DOC'
											WHEN '.TXT'	THEN 'DOC'
							
											WHEN '.OUT'	THEN 'LOGFILE'
											WHEN '.LOG'	THEN 'LOGFILE'
											WHEN '.1'	THEN 'LOGFILE'
											WHEN '.2'	THEN 'LOGFILE'
											WHEN '.3'	THEN 'LOGFILE'
											WHEN '.4'	THEN 'LOGFILE'
											WHEN '.5'	THEN 'LOGFILE'
											WHEN '.w3c'	THEN 'LOGFILE'

											WHEN '.BLG'	THEN 'PERFMON FILE'
											WHEN '.mdmp'	THEN 'CRASH DUMP FILE'
											WHEN '.trc'	THEN 'SQL TRACE FILE'
											WHEN '.actn'	THEN 'FILE TRANSIT ACTION FILE'

											WHEN '.cmd'	THEN 'BATCH FILE'
											WHEN '.bat'	THEN 'BATCH FILE'
											WHEN '.exe'	THEN 'EXECUTABLE'

											WHEN '.ZIP'	THEN 'PACKAGE'
											WHEN '.RAR'	THEN 'PACKAGE'
											WHEN '.Z'	THEN 'PACKAGE'
											WHEN '.CAB'	THEN 'PACKAGE'
							
											ELSE 'OTHER'
											END
						ELSE  ISNULL('DB_' + T3.type_desc,'')
						END
					,ISNULL(DB_NAME(T3.database_id),'')
					,ISNULL(T3.data_space_id,0)
		   end
		Else
		   begin
			DECLARE DBCursor CURSOR
			FOR
			SELECT		CASE	WHEN T2.FullPathName LIKE '%\$RECYCLE.BIN\%' THEN 'RECYCLE BIN'
						WHEN T2.Name LIKE '%ERRORLOG%' THEN 'LOGFILE'
						WHEN T2.Name LIKE '%SQLAGENT%' THEN 'LOGFILE'
						WHEN T3.database_id IS NULL THEN CASE T2.Extension
											WHEN '.BAK'	THEN 'BACKUP'
											WHEN '.DIF'	THEN 'BACKUP'
											WHEN '.TRN'	THEN 'BACKUP'
											WHEN '.cBAK'	THEN 'BACKUP'
											WHEN '.cDIF'	THEN 'BACKUP'
											WHEN '.cTRN'	THEN 'BACKUP'
											WHEN '.SQB'	THEN 'BACKUP'
											WHEN '.SQD'	THEN 'BACKUP'
											WHEN '.SQT'	THEN 'BACKUP'

											WHEN '.LDF'	THEN 'DB_LOG'
											WHEN '.MDF'	THEN 'DB_ROWS'
											WHEN '.NDF'	THEN 'DB_ROWS'

											WHEN '.SQL'	THEN 'SCRIPT'
											WHEN '.GSQL'	THEN 'SCRIPT'
											WHEN '.sqlplan'	THEN 'SQL EXECUTION PLAN'

											WHEN '.CSV'	THEN 'DATAFILE'
											WHEN '.TAB'	THEN 'DATAFILE'
											WHEN '.XML'	THEN 'DATAFILE'
											WHEN '.dat'	THEN 'DATAFILE'
											WHEN '.tsv'	THEN 'DATAFILE'

											WHEN '.HTML'	THEN 'DOC'
											WHEN '.HTM'	THEN 'DOC'
											WHEN '.RPT'	THEN 'DOC'
											WHEN '.RTF'	THEN 'DOC'
											WHEN '.TXT'	THEN 'DOC'
							
											WHEN '.OUT'	THEN 'LOGFILE'
											WHEN '.LOG'	THEN 'LOGFILE'
											WHEN '.1'	THEN 'LOGFILE'
											WHEN '.2'	THEN 'LOGFILE'
											WHEN '.3'	THEN 'LOGFILE'
											WHEN '.4'	THEN 'LOGFILE'
											WHEN '.5'	THEN 'LOGFILE'
											WHEN '.w3c'	THEN 'LOGFILE'

											WHEN '.BLG'	THEN 'PERFMON FILE'
											WHEN '.mdmp'	THEN 'CRASH DUMP FILE'
											WHEN '.trc'	THEN 'SQL TRACE FILE'
											WHEN '.actn'	THEN 'FILE TRANSIT ACTION FILE'

											WHEN '.cmd'	THEN 'BATCH FILE'
											WHEN '.bat'	THEN 'BATCH FILE'
											WHEN '.exe'	THEN 'EXECUTABLE'

											WHEN '.ZIP'	THEN 'PACKAGE'
											WHEN '.RAR'	THEN 'PACKAGE'
											WHEN '.Z'	THEN 'PACKAGE'
											WHEN '.CAB'	THEN 'PACKAGE'
							
											ELSE 'OTHER'
											END
						ELSE ISNULL('DB_' + T3.type_desc,'')
						END AS [FileType]
					,ISNULL(DB_NAME(T3.database_id),'') DatabaseName
					,ISNULL(T3.data_space_id,0) data_space_id
					,count(*) AS [FileCount]
					,SUM(T2.size/power(1024.0,3)) AS [FileSize_GB]
			From		dbaadmin.[dbo].[dbaudf_DirectoryList2](@RootFolder,null,1) T2
			LEFT JOIN	sys.master_files T3
				ON	T3.physical_name = T2.FullPathName
			LEFT JOIN	(
					SELECT		DISTINCT
							RootFolder + '%' [RootFolder]
					FROM		@Results
					) T1
				ON	T2.Directory LIKE T1.RootFolder
			WHERE		T1.RootFolder IS NULL

			GROUP BY	CASE	WHEN T2.FullPathName LIKE '%\$RECYCLE.BIN\%' THEN 'RECYCLE BIN'
						WHEN T2.Name LIKE '%ERRORLOG%' THEN 'LOGFILE'
						WHEN T2.Name LIKE '%SQLAGENT%' THEN 'LOGFILE'
						WHEN T3.database_id IS NULL THEN CASE T2.Extension
											WHEN '.BAK'	THEN 'BACKUP'
											WHEN '.DIF'	THEN 'BACKUP'
											WHEN '.TRN'	THEN 'BACKUP'
											WHEN '.cBAK'	THEN 'BACKUP'
											WHEN '.cDIF'	THEN 'BACKUP'
											WHEN '.cTRN'	THEN 'BACKUP'
											WHEN '.SQB'	THEN 'BACKUP'
											WHEN '.SQD'	THEN 'BACKUP'
											WHEN '.SQT'	THEN 'BACKUP'

											WHEN '.LDF'	THEN 'DB_LOG'
											WHEN '.MDF'	THEN 'DB_ROWS'
											WHEN '.NDF'	THEN 'DB_ROWS'

											WHEN '.SQL'	THEN 'SCRIPT'
											WHEN '.GSQL'	THEN 'SCRIPT'
											WHEN '.sqlplan'	THEN 'SQL EXECUTION PLAN'

											WHEN '.CSV'	THEN 'DATAFILE'
											WHEN '.TAB'	THEN 'DATAFILE'
											WHEN '.XML'	THEN 'DATAFILE'
											WHEN '.dat'	THEN 'DATAFILE'
											WHEN '.tsv'	THEN 'DATAFILE'

											WHEN '.HTML'	THEN 'DOC'
											WHEN '.HTM'	THEN 'DOC'
											WHEN '.RPT'	THEN 'DOC'
											WHEN '.RTF'	THEN 'DOC'
											WHEN '.TXT'	THEN 'DOC'
							
											WHEN '.OUT'	THEN 'LOGFILE'
											WHEN '.LOG'	THEN 'LOGFILE'
											WHEN '.1'	THEN 'LOGFILE'
											WHEN '.2'	THEN 'LOGFILE'
											WHEN '.3'	THEN 'LOGFILE'
											WHEN '.4'	THEN 'LOGFILE'
											WHEN '.5'	THEN 'LOGFILE'
											WHEN '.w3c'	THEN 'LOGFILE'

											WHEN '.BLG'	THEN 'PERFMON FILE'
											WHEN '.mdmp'	THEN 'CRASH DUMP FILE'
											WHEN '.trc'	THEN 'SQL TRACE FILE'
											WHEN '.actn'	THEN 'FILE TRANSIT ACTION FILE'

											WHEN '.cmd'	THEN 'BATCH FILE'
											WHEN '.bat'	THEN 'BATCH FILE'
											WHEN '.exe'	THEN 'EXECUTABLE'

											WHEN '.ZIP'	THEN 'PACKAGE'
											WHEN '.RAR'	THEN 'PACKAGE'
											WHEN '.Z'	THEN 'PACKAGE'
											WHEN '.CAB'	THEN 'PACKAGE'
							
											ELSE 'OTHER'
											END
						ELSE  ISNULL('DB_' + T3.type_desc,'')
						END
					,ISNULL(DB_NAME(T3.database_id),'')
					,ISNULL(T3.data_space_id,0)
		   end


		OPEN DBCursor;
		FETCH DBCursor INTO @FileType,@DBName,@DataSpaceID,@FileCount,@FileSize_GB;

		WHILE (@@fetch_status <> -1)
		BEGIN
			IF (@@fetch_status <> -2)
			BEGIN
				--SELECT  @RootFolder,@FileType,@DBName,@DataSpaceID,@DriveSize_GB,@DriveFree_GB,@FileCount,@FileSize_GB;
				---------------------------- 
				---------------------------- CURSOR LOOP TOP
				SELECT	@FileGroupName	= NULL
					,@Pct_Unused	= NULL
					,@Pct_Data	= NULL
					,@Pct_Index	= NULL

				--SELECT @CMD = 'DBCC UPDATEUSAGE ('''+@DBName+''')'
				--EXEC (@CMD)
				IF @FileType = 'DB_ROWS' and nullif(@DBName,'') IS NOT NULL AND  databasepropertyex (@DBName,'status') = 'ONLINE'
				BEGIN
					Select @cmd = 'use [' + @DBName + ']
    
					select		@FileGroupName = FILEGROUP_NAME(isnull(@DataSpaceID,0)) --select *
					from		dbo.sysfiles 
					where		groupid		= isnull(@DataSpaceID,0)
	 
					SELECT		@Pct_Unused	= CASE [TotalPages] WHEN 0 THEN 100 ELSE ([UnusedPages]*100.0)/[TotalPages] END	--[Pct_Unused]
							,@Pct_Data	= CASE [TotalPages] WHEN 0 THEN 0 ELSE ([DataPages]*100.0)/[TotalPages] END	--[Pct_Data]
							,@Pct_Index	= CASE [TotalPages] WHEN 0 THEN 0 ELSE ([IndexPages]*100.0)/[TotalPages] END	--[Pct_Index]
					FROM		(		
							Select		sum(a.total_pages) [TotalPages]
									,sum(a.total_pages)-sum(a.used_pages) [UnusedPages]
									,sum(	CASE	
										WHEN it.internal_type IN (202,204)	Then 0
										When a.type <> 1			Then a.used_pages
										When p.index_id < 2			Then a.data_pages
										Else 0 END) [DataPages]
									,sum(a.used_pages) 
										-sum(	CASE	
										WHEN it.internal_type IN (202,204)	Then 0
										When a.type <> 1			Then a.used_pages
										When p.index_id < 2			Then a.data_pages
										Else 0 END) [IndexPages]
							from		sys.partitions p 
							join		sys.allocation_units a 
								on	(a.type IN (1,3) AND p.hobt_id = a.container_id)
								or	(a.type IN (2) AND p.partition_id = a.container_id)
							left join	sys.internal_tables it 
								on	p.object_id = it.object_id
							WHERE		a.data_space_id = isnull(@DataSpaceID,0)
							) Data'

					EXEC	sp_executesql @cmd, N'@DataSpaceID int,@FileGroupName SYSNAME output,@Pct_Unused Float output,@Pct_Data Float output,@Pct_Index Float output'
								,@DataSpaceID
								,@FileGroupName	output
								,@Pct_Unused	output
								,@Pct_Data	output
								,@Pct_Index	output
				END

				INSERT INTO	@Results
				SELECT		@RootFolder
						,@FileType
						,@DBName		
						,@DataSpaceID
						,@FileGroupName
						,@DriveSize_GB
						,@DriveFree_GB
						,@FileCount
						,@FileSize_GB	
						,CASE @FileType WHEN 'DB_ROWS' THEN ISNULL((@Pct_Unused * @FileSize_GB)/100.0,0) ELSE 0 END
						,CASE @FileType WHEN 'DB_ROWS' THEN ISNULL((@Pct_Data * @FileSize_GB)/100.0,0) ELSE 0 END
						,CASE @FileType WHEN 'DB_ROWS' THEN ISNULL((@Pct_Index * @FileSize_GB)/100.0,0) ELSE 0 END

				---------------------------- CURSOR LOOP BOTTOM
				----------------------------


			END
 			FETCH NEXT FROM DBCursor INTO @FileType,@DBName,@DataSpaceID,@FileCount,@FileSize_GB;
		END
		CLOSE DBCursor;
		DEALLOCATE DBCursor;		


		---------------------------- CURSOR LOOP BOTTOM
		----------------------------
	END
 	FETCH NEXT FROM RootFolderCursor INTO @RootFolder,@DriveSize_GB,@DriveFree_GB;
END
CLOSE RootFolderCursor;
DEALLOCATE RootFolderCursor;


IF OBJECT_ID('[dbo].[Drive_Stats_Log]') IS NULL
	EXEC('CREATE TABLE [dbo].[Drive_Stats_Log](
	[ServerName] [nvarchar](128) NULL,
	[RunDate] [datetime] NULL,
	[RootFolder] [char](1) NULL,
	[FileType] [sysname] NOT NULL,
	[DBName] [sysname] NOT NULL,
	[DataSpaceID] [int] NULL,
	[FileGroup] [sysname] NULL,
	[DriveSize_GB] [numeric](38, 10) NULL,
	[DriveFree_GB] [numeric](38, 10) NULL,
	[FileCount] [int] NULL,
	[FileSize_GB] [numeric](38, 10) NULL,
	[UnUsed_GB] [numeric](38, 10) NULL,
	[Data_GB] [numeric](38, 10) NULL,
	[Index_GB] [numeric](38, 10) NULL
	) ON [PRIMARY]')
ELSE IF EXISTS (SELECT * From syscolumns where id = OBJECT_ID('[dbo].[Drive_Stats_Log]') and name = 'DriveLetter')
BEGIN
	EXEC sp_rename 'dbo.Drive_Stats_Log.DriveLetter', 'RootPath', 'COLUMN';
END

IF EXISTS (SELECT * From syscolumns where id = OBJECT_ID('[dbo].[Drive_Stats_Log]') and name = 'RootPath' and length < 256)
BEGIN
	DECLARE @TSQL VarChar(8000)

	SELECT @TSQL = 'DROP STATISTICS [dbo].[Drive_Stats_Log].['+S.NAME+']'
	FROM   SYS.OBJECTS AS O
	       INNER JOIN SYS.STATS AS S
		 ON O.OBJECT_ID = S.OBJECT_ID
	       INNER JOIN SYS.STATS_COLUMNS AS SC
		 ON SC.OBJECT_ID = S.OBJECT_ID
		    AND S.STATS_ID = SC.STATS_ID
	WHERE  (O.OBJECT_ID = OBJECT_ID('[dbo].[Drive_Stats_Log]'))
	       AND (O.TYPE IN ('U'))
	       AND (INDEXPROPERTY(S.OBJECT_ID,S.NAME,'IsStatistics') = 1)  /* only stats */
	       AND (COL_NAME(SC.OBJECT_ID,SC.COLUMN_ID) = 'RootPath')

	EXEC (@TSQL)
	
	EXEC('ALTER TABLE [dbo].[Drive_Stats_Log] ALTER COLUMN [RootPath] VarChar(500)');
END




DELETE	[dbo].[Drive_Stats_Log]
WHERE	[RunDate] = @RunDate


INSERT INTO	[dbo].[Drive_Stats_Log]
SELECT		@@ServerName	[ServerName]
		,@RunDate	[RunDate]
		,*
FROM		@Results



RAISERROR('  Exporting Data from %s to file %s.',-1,-1,@TableName,@FileName) WITH NOWAIT
EXEC	@RC=xp_cmdshell @SCRIPT, no_output
		
IF @RC <> 0
BEGIN
	RAISERROR('    *** ERROR Exporting Data from %s to file %s. ***',-1,-1,@TableName,@FileName) WITH NOWAIT
	RAISERROR(@SCRIPT,-1,-1) WITH NOWAIT
	GOTO ENDOFCODE
END

RAISERROR('  Sending Data from %s.',-1,-1,@TableName) WITH NOWAIT
EXEC	@RC=[dbaadmin].[dbo].[dbasp_File_Transit] 
		@source_name		= @FileName
		,@source_path		= @Output_Path
		,@target_env		= @target_env
		,@target_server		= @target_server
		,@target_share		= @target_share
		,@retry_limit		= @retry_limit

IF @RC <> 0
BEGIN
	RAISERROR('    *** ERROR Sending Data from %s. ***',-1,-1,@TableName) WITH NOWAIT
	GOTO ENDOFCODE
END

waitfor delay '00:00:05'  
  
-- DELETE FILE AFTER SENDING
RAISERROR('  Deleting file %s after sending.',-1,-1,@FileName) WITH NOWAIT
SET		@SCRIPT = 'DEL "'+ @Output_Path+'\'+@FileName+'"'
exec	@RC=xp_cmdshell @Script, no_output

IF @RC <> 0
BEGIN
	RAISERROR('    *** ERROR Deleting file %s after sending. ***',-1,-1,@FileName) WITH NOWAIT
	RAISERROR(@SCRIPT,-1,-1) WITH NOWAIT
	GOTO ENDOFCODE
END

ENDOFCODE:
GO
 
 
