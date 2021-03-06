USE [dbaadmin]
GO
/****** Object:  StoredProcedure [dbo].[dbasp_Restore]    Script Date: 3/17/2015 1:04:42 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[dbasp_Restore] 
					(
					@dbname				sysname
					,@FilePath			VarChar(MAX)	= NULL
					,@FileGroups			VarChar(MAX)	= NULL
					,@ForceFileName			VarChar(MAX)	= NULL
					,@LeaveNORECOVERY		BIT		= 0
					,@NoFullRestores		BIT		= 0
					,@NoDifRestores			BIT		= 0
					,@OverrideXML			XML		= NULL	
					,@post_shrink			char(1)		= 'n'
					,@complete_on_diffOnly_fail	char(1)		= 'n'
					,@BufferCount			INT		= NULL
					,@MaxTransferSize		INT		= NULL
					)

/*********************************************************
 **  Stored Procedure dbasp_Restore                  
 **  Written by Jim Wilson, Getty Images                
 **  December 29, 2008                                      
 **  
 **  This procedure is used for automated database
 **  restore processing for the pre-restore method.
 **  The pre-restore method is where we restore the
 **  DB along side of the DB of the same name using "_new"
 **  added to the DBname.  The mdf and ldf file names are 
 **  changed as well.  When the restore is completed, the old
 **  DB is droped and the "_new" DB is renamed, completing the
 **  restore.  This gives the end user greater DB availability.
 **
 **  This proc accepts the following input parms:
 **  - @dbname is the name of the database being restored.
 **  - @FilePath is the path where the backup file(s) can be found
 **    example - "\\seapsqlrpt01\seapsqlrpt01_restore"
 **  - @FileGroups is the name of individual file groups to be restored (comma seperated if more than one)
 **  - @LeaveNORECOVERY when set will Leave Database in Recovery Mode When Done
 **  - @NoFullRestores when set will Not Create Restore Script For Full Backups
 **  - @NoDifRestores when set will Not Create Restore Script For Diff Backups
 **  - @OverrideXML enables process to Force Files to be restored to specific locations
 **  - @post_shrink is for a post restore file shrink (y or n)
 **  - @complete_on_diffOnly_fail will finish the restore of a DB after a failed 
 **    differential restore'
 **
 **	WARNING: BufferCount and MaxTransferSize values can cause Memory Errors
 **	   The total space used by the buffers is determined by: buffercount * maxtransfersize * DB_Data_Devices
 **	   blogs.msdn.com/b/sqlserverfaq/archive/2010/05/06/incorrect-buffercount-data-transfer-option-can-lead-to-oom-condition.aspx
 **
 **	@BufferCount		If Specified, Forces Value to be used				  X	  X
 **	@MaxTransferSize	If Specified, Forces Value to be used				  X	  X

 ***************************************************************/
  as
SET NOCOUNT ON

--	======================================================================================
--	Revision History
--	Date		Author     		Desc
--	==========	====================	=============================================
--	12/29/2008	Jim Wilson		New process based on dbasp_autorestore.
--	12/08/2010	Jim Wilson		Added code for filegroup processing.
--	04/22/2011	Jim Wilson		New code for 2008 processing.
--	10/24/2011	Jim Wilson		Remove systema dn hidden attributes from the restore paths.
--	11/23/2011	Jim Wilson		Added code for path override via local_control table.
--	11/12/2013	Jim Wilson		Converted to use the new sproc dbasp_format_BackupRestore.
--	01/29/2014	Jim Wilson		Changed tssqldba to tsdba.
--	02/03/2014	Jim Wilson		Added new parm for dbaudf_BackupScripter_GetBackupFiles.
--	2014-10-28	Steve Ledridge		Added Parameters for @MaxTransferSize and @BufferCount to be used for both Backup and Restore Database scripts.
--	03/18/2015	Steve Ledridge		Fixed problem where Sproc loops if no files can be restored
--	======================================================================================


/***
Declare @dbname sysname
Declare @FilePath VarChar(MAX)
Declare @FileGroups VarChar(MAX)
Declare @ForceFileName VarChar(MAX)
Declare @LeaveNORECOVERY BIT
Declare @NoFullRestores BIT
Declare @NoDifRestores BIT
Declare @OverrideXML XML
Declare @post_shrink char(1)
Declare @complete_on_diffOnly_fail char(1)

select @dbname = 'Getty_Images_CRM_GENESYS'
select @FilePath = '\\seapcrmsql1a\seapcrmsql1a_backup\'
--select @FileGroups = 'primary'
select @ForceFileName = null
select @LeaveNORECOVERY = 0
select @NoFullRestores = 1
select @NoDifRestores = 0
select @OverrideXML = '
		<RestoreFileLocations>
		<Override LogicalName="Getty_Images_CRM_GENESYS" PhysicalName="E:\data\Getty_Images_CRM_GENESYS.mdf" New_PhysicalName="I:\MSSQL\Data\$DT$_Getty_Images_CRM_GENESYS.mdf" />
		<Override LogicalName="Getty_Images_CRM_GENESYS_log" PhysicalName="F:\log\Getty_Images_CRM_GENESYS_log.LDF" New_PhysicalName="I:\MSSQL\Data\$DT$_Getty_Images_CRM_GENESYS_log.LDF" />
		<Override LogicalName="Getty_Images_CRM_GENESYS_2" PhysicalName="E:\data\Getty_Images_CRM_GENESYS_2.ndf" New_PhysicalName="I:\MSSQL\Data\$DT$_Getty_Images_CRM_GENESYS_2.ndf" />
		</RestoreFileLocations>'	
Select @post_shrink = 'n'
Select @complete_on_diffOnly_fail = 'n'
--***/

			

-----------------  declares  ------------------
DECLARE
	 @miscprint			nvarchar(4000)
	,@error_count			int
	,@cmd 				nvarchar(4000)
	,@Restore_cmd			nvarchar(max)
	,@save_BackupSetSize		smallint
	,@save_subject			sysname
	,@save_message			nvarchar(500)
	,@save_diff_filename		sysname
	,@save_Diff_FullPath		varchar(2000)
	,@save_DB_checkpoint_lsn	numeric(25,0)
	,@save_DB_DatabaseBackup_lsn	numeric(25,0)
	,@save_Diff_DatabaseBackupLSN	numeric(25,0)
	,@loop_count			smallint
	,@DB_LeaveNORECOVERY		BIT
	,@Restore_DB_flag		char(1)			
	

----------------  initial values  -------------------
Select @error_count = 0
Select @loop_count = 0
Select @Restore_DB_flag = 'n'


--  Check input parms
if @FilePath is null
   BEGIN
	Select @miscprint = 'DBA WARNING: Invalid parameters to dbasp_Restore - @FilePath must be specified.' 
	Print @miscprint
	Select @error_count = @error_count + 1
	goto label99
   END

if @dbname is null or @dbname = ''
   BEGIN
	Select @miscprint = 'DBA WARNING: Invalid parameters to dbasp_Restore - @dbname must be specified.' 
	Print @miscprint
	Select @error_count = @error_count + 1
	goto label99
   END




/****************************************************************
 *                MainLine
 ***************************************************************/

 ----------------------  Print the headers  ----------------------
Print  ' '
Print  '/*********************************************************'
Select @miscprint = 'Restore Database for server: ' + @@servername  
Print  @miscprint
Print  '*********************************************************/'
RAISERROR('', -1,-1) WITH NOWAIT


--  Start Full Restore
If @NoFullRestores = 1
   begin
	Select @miscprint = 'Skipping the Full Restore Section.' 
	Print @miscprint
	RAISERROR('', -1,-1) WITH NOWAIT
	goto skip_full_restores
   end

start_full_restore:



--  Create DB restore command
Select @Restore_cmd = ''

Select @DB_LeaveNORECOVERY = @LeaveNORECOVERY
If @LeaveNORECOVERY = 0 and @NoDifRestores = 0
   begin
	Select @DB_LeaveNORECOVERY = 1
   end

If @OverrideXML is null
   begin
   	EXEC [dbaadmin].[dbo].[dbasp_format_BackupRestore] 
		 @DBName = @DBName
		,@Mode = 'RD' 
		,@FilePath = @FilePath
		,@FileGroups = @FileGroups
		,@ForceFileName = @ForceFileName
		,@Verbose = 0
		,@FullReset = 1 
		,@NoDifRestores = 1
		,@NoLogRestores = 1
		,@BufferCount		= @BufferCount		
		,@MaxTransferSize	= @MaxTransferSize
		,@LeaveNORECOVERY = @DB_LeaveNORECOVERY
		,@syntax_out = @Restore_cmd OUTPUT 
   end
Else
   begin
   	EXEC [dbaadmin].[dbo].[dbasp_format_BackupRestore] 
		 @DBName = @DBName
		,@Mode = 'RD' 
		,@FilePath = @FilePath
		,@FileGroups = @FileGroups
		,@ForceFileName = @ForceFileName
		,@Verbose = 0
		,@FullReset = 1 
		,@NoDifRestores = 1
		,@NoLogRestores = 1
		,@IgnoreSpaceLimits = 1
		,@BufferCount		= @BufferCount		
		,@MaxTransferSize	= @MaxTransferSize
		,@LeaveNORECOVERY = @DB_LeaveNORECOVERY
		,@OverrideXML = @OverrideXML
		,@syntax_out = @Restore_cmd OUTPUT 
   end

Select @Restore_cmd = Replace(@Restore_cmd, 'DROP DATABASE', '--DROP DATABASE') 
--Select @Restore_cmd = Replace(@Restore_cmd, 'EXEC [msdb]', '--EXEC [msdb]') 


-- Restore the DB
Select @Restore_DB_flag = 'y'
Print 'Here is the DB restore command being executed;'
exec dbo.dbasp_PrintLarge @Restore_cmd
raiserror('', -1,-1) with nowait

BEGIN TRY
	Exec (@Restore_cmd)
END TRY

BEGIN CATCH

	Print 'DBA Error:  Restore DB Failure for command ' + @Restore_cmd
	Select @error_count = @error_count + 1
	goto label99

END CATCH


If @@error<> 0 OR DB_ID(@DBName) IS NULL
   begin
	Print 'DBA Error:  Restore DB Failure for command ' + @Restore_cmd
	Select @error_count = @error_count + 1
	goto label99
   end

If @LeaveNORECOVERY = 1
   begin
	Print ' '
	select @miscprint = '--  Note:  This will leave the database in recovery pending mode.'
	print  @miscprint
	goto label99
   end


skip_full_restores:




--  Start Differential Restore
If @NoDifRestores = 1
   begin
	Select @miscprint = 'Skipping the Differential Restore Section.' 
	Print @miscprint
	RAISERROR('', -1,-1) WITH NOWAIT
	goto skip_diff_restores
   end

--  Check the current @DBName DB
If DATABASEPROPERTYEX (@DBName,'status') is null AND @NoFullRestores = 1
   begin
	select @miscprint = 'DBA NoteR:  The @DBName (' + @DBName + ') does not exist.  Skip to the Restore Full Section.'
	print  @miscprint
	select @NoFullRestores = 0
	goto start_full_restore
   end

If DATABASEPROPERTYEX (@DBName,'status') <> 'RESTORING' AND @NoFullRestores = 1
   begin
	select @miscprint = 'DBA Note:  The @DBName (' + @DBName + ') is not in restoring mode.  Skip to the Restore Full Section.'
	print  @miscprint
	select @NoFullRestores = 0
	goto start_full_restore
   end


--  If we have looped, just finish the restore
If @loop_count > 1
   begin
	select @Restore_cmd = ''
	select @Restore_cmd = @Restore_cmd + 'RESTORE DATABASE ' + @DBName + ' WITH RECOVERY'

	Print 'The differential restore failed.  Completing restore for just the database using the following command;'
	Print @Restore_cmd
	raiserror('', -1,-1) with nowait

	Exec (@Restore_cmd)

	If DATABASEPROPERTYEX (@DBName,'status') <> 'ONLINE'
	   begin
		Print 'DBA Error:  Restore Failure after loop.'
		Select @error_count = @error_count + 1
		goto label99
	   end

	goto skip_diff_restores
   end


--  Current Differential must match the DB that is in restoring mode
--  This section gets the LSN for the differential and compares it to the LSN for the DB being restored to
Select @save_diff_filename = (Select top 1 name from dbaudf_BackupScripter_GetBackupFiles (@dbname, @FilePath, 1, null)
				where BackupType in ('DF')
				and BackupSetNumber = 1
				order by BackupTimeStamp desc)

Select @save_BackupSetSize = (Select BackupSetSize from dbaudf_BackupScripter_GetBackupFiles (@dbname, @FilePath, 1, null)
				where name = @save_diff_filename)

Select @save_Diff_FullPath = @FilePath + @save_diff_filename

Select @save_Diff_DatabaseBackupLSN = (SELECT DatabaseBackupLSN FROM dbaadmin.dbo.dbaudf_BackupScripter_GetHeaderList (@save_BackupSetSize, @save_diff_filename, @save_Diff_FullPath))

Select @save_DB_checkpoint_lsn = (SELECT TOP 1 checkpoint_lsn
				FROM msdb.dbo.restorehistory rh 
				JOIN [msdb].[dbo].[backupset] bs 
				ON rh.backup_set_id = bs.backup_set_id 
				JOIN [msdb].[dbo].[backupmediafamily] bmf 
				ON bmf.[media_set_id] = bs.[media_set_id] 
				WHERE rh.destination_database_name = @DBName 
				AND restore_type IN ('D', 'F', 'G') 
				ORDER BY restore_date DESC)

Select @save_DB_DatabaseBackup_lsn = (SELECT TOP 1 database_backup_lsn
				FROM msdb.dbo.restorehistory rh 
				JOIN [msdb].[dbo].[backupset] bs 
				ON rh.backup_set_id = bs.backup_set_id 
				JOIN [msdb].[dbo].[backupmediafamily] bmf 
				ON bmf.[media_set_id] = bs.[media_set_id] 
				WHERE rh.destination_database_name = @DBName 
				AND restore_type IN ('D', 'F', 'G') 
				ORDER BY restore_date DESC)

If @save_Diff_DatabaseBackupLSN not in (@save_DB_checkpoint_lsn, @save_DB_DatabaseBackup_lsn) 
   begin
	print 'Here is the LSN for the DB'
	select @save_DB_checkpoint_lsn

	print 'Here is the LSN for the Differential'
	select @save_Diff_DatabaseBackupLSN

	select @miscprint = 'DBA Note:  The the differential is not related to the current @DBName (' + @DBName + ') being restored.  Skip to the Restore Full Section.'
	print  @miscprint
	raiserror('', -1,-1) with nowait
	
	If @Restore_DB_flag = 'n'
	   begin
		Select @loop_count = @loop_count + 1
		select @NoFullRestores = 0
		goto start_full_restore
	   end
   end

If @save_Diff_DatabaseBackupLSN is null
   begin
	Print 'DBA Error:  Differential was not found for this restore request.'
	Select @error_count = @error_count + 1
	goto label99
   end


--  Create Differential restore command
Select @Restore_cmd = ''

If @OverrideXML is null
   begin
   	EXEC [dbaadmin].[dbo].[dbasp_format_BackupRestore] 
		 @DBName = @DBName
		,@Mode = 'RD' 
		,@FilePath = @FilePath
		,@FileGroups = @FileGroups
		,@Verbose = 0
		,@FullReset = 1 
		,@NoFullRestores = 1
		,@NoLogRestores = 1
		,@LeaveNORECOVERY = 0
		,@BufferCount		= @BufferCount		
		,@MaxTransferSize	= @MaxTransferSize
		,@syntax_out = @Restore_cmd OUTPUT 
   end
Else
   begin
   	EXEC [dbaadmin].[dbo].[dbasp_format_BackupRestore] 
		 @DBName = @DBName
		,@Mode = 'RD' 
		,@FilePath = @FilePath
		,@FileGroups = @FileGroups
		,@Verbose = 0
		,@FullReset = 1 
		,@NoFullRestores = 1
		,@NoLogRestores = 1
		,@LeaveNORECOVERY = 0
		,@IgnoreSpaceLimits = 1
		,@BufferCount		= @BufferCount		
		,@MaxTransferSize	= @MaxTransferSize
		,@OverrideXML = @OverrideXML
		,@syntax_out = @Restore_cmd OUTPUT 
   end

Select @Restore_cmd = Replace(@Restore_cmd, 'DROP DATABASE', '--DROP DATABASE') 
--Select @Restore_cmd = Replace(@Restore_cmd, 'EXEC [msdb]', '--EXEC [msdb]') 

-- Restore the differential
Print 'Here is the Diff restore command being executed;'
exec dbo.dbasp_PrintLarge @Restore_cmd
raiserror('', -1,-1) with nowait

Exec (@Restore_cmd)
		
If DATABASEPROPERTYEX (@DBName,'status') <> 'ONLINE'
   begin
	If @complete_on_diffOnly_fail = 'y'
	   begin
		--  finish the restore and send the DBA's an email
		Select @save_subject = 'DBAADMIN:  Restore Failure for server ' + @@servername
		Select @save_message = 'Unable to restore the differential file for database ''' + @DBName + ''', the restore will be completed without the differential.'
		EXEC dbaadmin.dbo.dbasp_sendmail 
			@recipients = 'jim.wilson@gettyimages.com',  
			--@recipients = 'tsdba@gettyimages.com',  
			@subject = @save_subject,
			@message = @save_message

		select @Restore_cmd = ''
		select @Restore_cmd = @Restore_cmd + 'RESTORE DATABASE ' + @DBName + ' WITH RECOVERY'

		Print 'The differential restore failed.  Completing restore for just the database using the following command;'
		Print @Restore_cmd
		raiserror('', -1,-1) with nowait

		Exec (@Restore_cmd)

		If DATABASEPROPERTYEX (@DBName,'status') <> 'ONLINE'
		   begin
			Print 'DBA Error:  Restore Failure (Standard DIF restore - Unable to finish restore without the DIF) for command ' + @Restore_cmd
			Select @error_count = @error_count + 1
			goto label99
		   end
	   end
	Else
	   begin
		Print 'DBA Error:  Restore Failure (Standard DIF restore) for command ' + @Restore_cmd
		Select @error_count = @error_count + 1
		goto label99
	   end
   end


skip_diff_restores:







-------------------   end   --------------------------

label99:

--  Check to make sure the DB is in 'restoring' mode if requested
If @LeaveNORECOVERY = 1 and DATABASEPROPERTYEX (@DBName,'status') <> 'RESTORING'
   begin
	select @miscprint = 'DBA ERROR:  A norecovOnly restore was requested and the database is not in ''RESTORING'' mode.'
	print  @miscprint
	Select @error_count = @error_count + 1
   end

If @error_count = 0 and @LeaveNORECOVERY = 0 and DATABASEPROPERTYEX (@DBName,'status') <> 'ONLINE'
   begin
	select @miscprint = 'DBA ERROR:  The Restore process has failed for database ' + @DBName + '.  That database is not ''ONLINE'' at this time.'
	print  @miscprint
	Select @error_count = @error_count + 1
   end


If @error_count > 0
   begin
	raiserror(@miscprint,16,-1) with log
	RETURN (1)
   end
Else
   begin
	RETURN (0)
   end


 
 
 
 
 
 
 
 
 
 
 
 
 
