USE [SQLdeploy]
GO
/****** Object:  StoredProcedure [dbo].[dpsp_auto_DBrestore]    Script Date: 4/2/2014 2:48:09 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--ALTER PROCEDURE [dbo].[dpsp_auto_DBrestore]

/*********************************************************
 **  Stored Procedure dpsp_auto_DBrestore               
 **  Written by Jim Wilson, Getty Images                
 **  November 15, 2002                                      
 **  
 **  This procedure is used for automated deployment 
 **  database restore processing.
 **
 **  This proc is set up to restore a database using one of
 **  two different processes (snapshot revert, restore from 
 **  central backup.  The preference is to perform a snapshot revert.  
 **  If the current snapshot matches the most recent baseline for the DB, 
 **  the snapshot revert will be will be performed.  If not, the backup
 **  file located on the central server will be restored.
 **
 **  This proc gets its input parms from the Request_local table:
 **
 **  - @dbname is the name of the database being restored.
 **
 **  - @restore_folder is the folder where the backup file can be 
 **    found on the central server.  The rest of the path is filled in 
 **    depending on information found in the SQLdeploy DB.
 **    For example, if the deployment is run in the test environment
 **    and the @restore_folder parm is 'GMSA', the path would
 **    be '\\sqldeployer02\sqldeployer02_BASE_GMSA'
 **
 ***************************************************************/
 -- as
SET NOCOUNT ON

--	======================================================================================
--	Revision History
--	Date		Author     		Desc
--	==========	====================	=============================================
--	11/15/2002	Jim Wilson		New auto restore/detach-attach process 
--	12/11/2002	Jim Wilson		added kill spids and wait for's 
--	04/18/2003	Jim Wilson		Changes for new instance share names.
--	05/30/2003	Jim Wilson		Changes for new load share
--	07/07/2003	Jim Wilson		Added print stmt for missing 'nxt' files
--	11/17/2003	Jim Wilson		Changed killspids to alter DB
--	02/24/2004	Jim Wilson		Added process to delete default LDF file
--	08/11/2004	Jim Wilson		New code for small DB footprint processing
--	11/01/2004	Jim Wilson		Added check on restore filelist only results
--	11/16/2004	Jim Wilson		Fixed error when spaces are in the file path
--	08/30/2005	Jim Wilson		Added insert for the gears_update table
--	10/31/2006	Jim Wilson		Modified to support instance specific restore folder shares
--	06/14/2007	Jim Wilson		Major re-write.  Use local backup if available.
--	06/14/2007	Jim Wilson		Updated for SQL 2005.
--	07/30/2007	Jim Wilson		Added code for RedGate restores.
--	07/31/2007	Jim Wilson		Added @force_BAK flag.
--	08/22/2007	Jim Wilson		Reset @force_BAK flag to 'n' when starting restore from central.
--	01/23/2008	Jim Wilson		Added support for type 'F' files.
--	01/31/2008	Jim Wilson		Added support for type 'F' files (in 2 more places).
--	06/17/2008	Jim Wilson		Get central server info from table db_BaseLocation.
--	10/24/2008	Jim Wilson		Enhanced code for @central_server variable.
--	02/09/2009	Jim Wilson		Converted for SQLdeploy.
--	03/06/2009	Jim Wilson		Added baseline info update to control_local table.
--	03/23/2009	Jim Wilson		Added check to control table for alt mdf and ldf paths.
--	04/13/2009	Jim Wilson		New code to remove 01/01/1980 files from DIR results.
--	04/14/2009	Jim Wilson		Changed single_user mode to restricted_user mode for detach.
--	04/15/2009	Jim Wilson		Added master.sys.sp_executesql to detach process.
--						Removed naked attach code.
--	07/08/2009	Jim Wilson		Fixed bug with ldf file delete.
--	08/10/2009	Jim Wilson		Added check/wait for Base - Local Process job.
--	09/25/2009	Jim Wilson		Added update to DEPLcontrol build_central table.
--	10/21/2009	Jim Wilson		Added ndf share processing for backup restores.
--	12/02/2009	Jim Wilson		New code to make sure MDF attaches go to the MFD share.
--	03/24/2010	Jim Wilson		Added NDF path override from control table.
--	05/19/2010	Jim Wilson		Added column for new sql2008 filelist.
--	06/02/2010	Jim Wilson		Changed seafrestgsql to fresdbasql01. 
--	06/16/2010	Jim Wilson		Added code for new BASE share. 
--	01/25/2011	Jim Wilson		New code to support Filegroup backup files. 
--	03/17/2011	Steve Ledridge		Temp code for 'FREAGMSSQL01\A'.  This will be removed at some point. 
--	04/26/2011	Jim Wilson		Added code for new cBAK backup types. 
--	09/15/2011	Jim Wilson		Updated seafresqldba01 to seapsqldba01. 
--	01/06/2012	Jim Wilson		Make sure restore paths are not sysem or hidden. 
--	05/15/2012	Jim Wilson		Added extra LDF delete prior to attach process. 
--	06/01/2012	Jim Wilson		Removed detach\attach and added snapshot\revert. 
--	02/26/2013	Steve Ledridge		Modified Calls to functions supporting the replacement of OLE with CLR.
--	02/27/2013	Jim Wilson		Added spids > 50 to kill process. 
--	03/01/2013	Jim Wilson		Added datetime markers for snapshot activity. 
--	04/09/2013	Jim Wilson		Added code for override_path by logical file. 
--	04/10/2013	Jim Wilson		Added try\catch to snapshot revert. 
--	04/16/2013	Jim Wilson		Modify one of the old DIR's to use dbaudf_directorylist2.
--						Added state = 0 to snapshot process. 
--	05/03/2013	Jim Wilson		Modified snapshot name.
--	05/07/2013	Jim Wilson		Modified check for SQL 2008 or above.  Added double check for snapshot baseline date.
--	05/10/2013	Jim Wilson		Removed direct query to the snapshot db and new code to skip snapshot.
--	06/10/2013	Jim Wilson		No snapshot for standard edition.
--	06/19/2013	Jim Wilson		Added check for current local baseline file.
--	06/20/2013	Jim Wilson		Missing WITH added.  Now only processing IsPresent rows from filelistonly.
--	09/04/2013	Jim Wilson		Changed fresdbasql01 to seasdbasql01. 
--	10/16/2013	Jim Wilson		Added map base share for LOCAL env. 
--	11/07/2013	Jim Wilson		New section for restore from prod using the restore format sproc. 
--	11/25/2013	Jim Wilson		Bug fix for new restore from prod code. 
--	02/04/2014	Jim Wilson		Altered for multi-file support. 
--	02/11/2014	Jim Wilson		Added back local restore processing. 
--	03/10/2014	Jim Wilson		Fixed restore for multi-file FG baselines. 
--	03/27/2014	Jim Wilson		Added code for auto mini DB prerestore. 
--	======================================================================================


-----------------  declares  ------------------
DECLARE
	 @miscprint				varchar(4000)
	,@cmd					nvarchar(4000)
	,@Restore_cmd				nvarchar(max)
	,@central_server 			sysname
	,@CentralSQLname			sysname
	,@query					nvarchar(4000)
	,@error_count				int
	,@mdf_path 				nvarchar(255)
	,@ldf_path 				nvarchar(255)
	,@nxt_path 				nvarchar(255)
	,@nxt_share_flag			char(1)
	,@charpos				int
	,@central_backup_path 			nvarchar(500)
	,@mini_backup_path 			nvarchar(500)
	,@local_base_path			nvarchar(500)
	,@parm01				nvarchar(100)
	,@save_servername			sysname
	,@save_servername2			sysname
	,@save_envname				sysname
	,@trys					smallint
	,@restore_folder 			nvarchar(100) 
	,@dbname 				sysname
	,@z_dbname_new				sysname
	,@dynamicSQL				nvarchar(2000)
	,@dynamicVAR				nvarchar(100)
	,@baseline_info				sysname
	,@save_DeployID				bigint
	,@CentralBaselinePath			VarChar(4000)
	,@CentralBaselineModDate		DateTime
	,@LocalBaselinePath			VarChar(4000)
	,@LocalBaselineModDate			DateTime
	,@TSQL					VarChar(max)
	,@CustomProperty			SYSNAME
	,@IsSnapshot				bit
	,@IsSnapCurrent				bit
	,@CurrentModValue			DateTime
	,@spid					int
	,@str					varchar(255)
	,@SnapDBName				SYSNAME
	,@retry					int
	,@retry_limit				int
	,@save_central_baseline_filename	sysname
	,@save_local_baseline_filename		sysname
	,@basedate				datetime
	,@save_prod_server			sysname
	,@restore_from_prod			char(1)
	,@restore_mini				char(1)
	,@ForceFileName				VarChar(MAX)
	,@drop_try				varchar(500)
	,@drop_db				sysname
	,@query_text				nvarchar(500)


----------------  initial values  -------------------
Select @error_count = 0
Select @Restore_cmd = ''
Select @retry_limit = 5
Select @restore_mini = 'n'


Select @IsSnapshot = 0
Select @IsSnapCurrent = 0

Select @save_servername		= @@servername
Select @save_servername2	= @@servername

Select @charpos = charindex('\', @save_servername)
IF @charpos <> 0
   begin
	Select @save_servername = substring(@@servername, 1, (CHARINDEX('\', @@servername)-1))

	Select @save_servername2 = stuff(@save_servername2, @charpos, 1, '$')
   end


-- Get the DBname from the control_local table
Select @save_DeployID = (Select top 1 DeployID from dbo.Controller where enddate is null order by DeployID)
Select @dbname = (select DBname from dbo.Request_local where DeployID = @save_DeployID and status like 'in-work%')
Select @restore_folder = (select top 1 BASEfolder from dbo.Request_local where DeployID = @save_DeployID and status like 'in-work%')


Select @central_server = (select baseline_srvname from SQLdeploy.dbo.db_BaseLocation where DBname = @dbname and RSTRfolder = @restore_folder)
If @central_server is null
   begin
	Select @central_server = (select top 1 baseline_srvname from SQLdeploy.dbo.db_BaseLocation where DBname = @dbname)
   end


--select * FROM dbo.Request_local -- SQLdeploy.dbo.db_BaseLocation

--  Set the baseline paths
select @central_backup_path = '\\' + @central_server + '\' + @central_server + '_BASE_' + @restore_folder
select @restore_folder, @central_server , @central_server, @restore_folder

Select @local_base_path = '\\' + @save_servername + '\' + @save_servername2 + '_base'



Select @save_envname = (select env_name from SQLdeploy.dbo.enviro_info where env_type = 'ENVname')


--  Check for ENV "local" and then map a drive to the baseline share
If @save_envname = 'local'
   begin
	select @cmd = 'net use'
	exec master.sys.xp_cmdshell @cmd--, no_output

	--  Connect to the remote server share
	select @cmd = 'net use ' + @central_backup_path + ' /u:' + @central_server + '\SQLminiRead' + ' xxxxx'
	print @cmd
	select @cmd = 'net use ' + @central_backup_path + ' /u:' + @central_server + '\SQLminiRead' + ' Run0ff@themoutH'
	--print @cmd
	exec master.sys.xp_cmdshell @cmd--, no_output
   end



--  Create Temp Tables
create table #output (output_data nvarchar(4000) null)



--  Verify backup file exists and set @CentralBaselinePath
If exists (select 1 from dbo.ControlTable where subject = 'restore_from_prod' and control01 = rtrim(@dbname) and control02 = @@servername)
   begin
	goto skip_Verifybackupfile
   end


--  Verify central baseline   
Select	    top 1 
	    @save_central_baseline_filename = name
from	    dbaadmin.dbo.dbaudf_directorylist2	(
						@central_backup_path
						,'*.*'
						, 0
						)
where	    name like '%' + @dbname + '_prod%'
    and	    DateModified <> '1980-01-01 16:00:00.000'
order by    DateCreated desc

If @save_central_baseline_filename is null
   begin
	Select @miscprint = 'DBA WARNING: Central baseline files could not be found @dbname ' + @dbname + ' at ' + @central_backup_path + '.' 
	raiserror(@miscprint,-1,-1) with log
	Select @error_count = @error_count + 1
	goto label99
   end
Else
   begin
	Select @CentralBaselinePath = @central_backup_path + '\' + @save_central_baseline_filename
	Begin TRY
	Select @CentralBaselineModDate = dbaadmin.dbo.dbaudf_GetFileProperty(@CentralBaselinePath,'File','LastWriteTime')
	End TRY
	Begin CATCH
	Select @CentralBaselineModDate = null
	End CATCH
   end



--  Verify local baseline   
Select	    top 1 
	    @save_local_baseline_filename = name
from	    dbaadmin.dbo.dbaudf_directorylist2	(
						@local_base_path
						,'*.*'
						, 0
						)
where	    name like '%' + @dbname + '_prod%'
    and	    DateModified <> '1980-01-01 16:00:00.000'
order by    DateCreated desc

If @save_local_baseline_filename is null
   begin
	Select @miscprint = 'DBA Note:  Local baseline file(s) not found.' 
	raiserror(@miscprint,-1,-1) with log
   end
Else
   begin
	Select @LocalBaselinePath = @local_base_path + '\' + @save_local_baseline_filename
	Begin TRY
	Select @LocalBaselineModDate = dbaadmin.dbo.dbaudf_GetFileProperty(@LocalBaselinePath,'File','LastWriteTime')
	End TRY
	Begin CATCH
	Select @LocalBaselineModDate = null
	End CATCH
   end


skip_Verifybackupfile:



--  Verify input parm
if @restore_folder is null or @dbname is null
   BEGIN
	Select @miscprint = 'DBA WARNING: Invalid parameter for @dbname or @restore_folder' 
	raiserror(@miscprint,-1,-1) with log
	Select @error_count = @error_count + 1
	goto label99
   END


--  Verfiy mdf and ldf shares and get mdf and ldf paths
If exists (select 1 from dbo.ControlTable where subject = 'auto_restore_mdf' and control01 = @dbname and control02 = @@servername)
   begin
	Select @parm01 = (select top 1 control03 from dbo.ControlTable where subject = 'auto_restore_mdf' and control01 = @dbname and control02 = @@servername)
	exec dbaadmin.dbo.dbasp_get_share_path @parm01, @mdf_path output
   end
Else
   begin
	Select @parm01 = @save_servername2 + '_mdf'
	exec dbaadmin.dbo.dbasp_get_share_path @parm01, @mdf_path output
   end

If exists (select 1 from dbo.ControlTable where subject = 'auto_restore_ldf' and control01 = @dbname and control02 = @@servername)
   begin
	Select @parm01 = (select top 1 control03 from dbo.ControlTable where subject = 'auto_restore_ldf' and control01 = @dbname and control02 = @@servername)
	exec dbaadmin.dbo.dbasp_get_share_path @parm01, @ldf_path output
   end
Else
   begin
	Select @parm01 = @save_servername2 + '_ldf'
	exec dbaadmin.dbo.dbasp_get_share_path @parm01, @ldf_path output
   end


--  Verfiy nxt share and get base path (used for snapshot)
Select @parm01 = @save_servername2 + '_NXT'
exec dbaadmin.dbo.dbasp_get_share_path @parm01, @nxt_path output

if @nxt_path is null
   BEGIN
	Select @nxt_share_flag = 'n'
   END
Else
   BEGIN
	Select @nxt_share_flag = 'y'
   END



--  Update the request_central DB
If @save_envname = 'local'
   begin
	goto skip_centralupdate_01
   end

Select @CentralSQLname = (select top 1 env_name from dbo.enviro_info where env_type = 'DEPLOYcentralServer')

select @query = 'Update DEPLOYcentral.dbo.Request_central set status = ''in-work_restore'', ModDate = getdate()'
select @query = @query + ' where DeployID = ' + convert(nvarchar(15), @save_DeployID)
select @query = @query + ' and SQLname = ''' + @@servername + ''''
select @query = @query + ' and process = ''restore'''
select @query = @query + ' and DBname = ''' + @dbname + ''''
Print 'Update DEPLOYcentral.dbo.Request_central 01 ' + convert(varchar(30),getdate(),9)
raiserror('', -1,-1) with nowait
Print @query
Select @cmd = 'sqlcmd -S' + @CentralSQLname + ' -dDEPLOYcentral -E -Q"' + @query + '"'
print @cmd
Select @retry = 0
central_update_start01:
delete from #output 
Insert into #output EXEC master.sys.xp_cmdshell @cmd--, no_output

If exists (select 1 from #output where output_data like '%error%')
   begin
	Select @retry = @retry + 1
	Waitfor delay '00:00:10'
	If @retry < @retry_limit
	   begin
		goto central_update_start01
	   end
	Else
	   begin
		Select @miscprint = 'DBA Error:  Unable to update central server via sqlcmd.'
		Print @miscprint 
		raiserror(@miscprint,-1,-1) with log
	   end
   end

skip_centralupdate_01:



/****************************************************************
 *                MainLine
 ***************************************************************/

--  Header
Print 'Start Restore Process for DB ' + @dbname + '  Started: '  + convert(varchar(30),getdate(),9)
raiserror('', -1,-1) with nowait



--  If the DB is in suspect or loading mode, drop it
If (DATABASEPROPERTYEX(@dbname, N'Status')) in ('RESTORING', 'RECOVERING', 'SUSPECT')
   begin
	Print 'Droping the database due to DB status. ' + convert(varchar(30),getdate(),9)
	Select (DATABASEPROPERTYEX(@dbname, N'Status'))
	Select @cmd = 'drop database ' + rtrim(@dbname)
	Print @cmd
	raiserror('', -1,-1) with nowait
	exec (@cmd)
	goto start_restore_from_backup
   end
Else If (DATABASEPROPERTYEX(@dbname, N'Status') <> N'ONLINE')
   begin
	goto start_restore_from_backup
   end



--  Check for an override to restore from prod
Select @restore_from_prod = 'n'
If exists (select 1 from dbo.ControlTable where subject = 'restore_from_prod' and control01 = rtrim(@dbname) and control02 = @@servername)
   begin
	Select @save_prod_server = (select control03 from dbo.ControlTable where subject = 'restore_from_prod' and control01 = rtrim(@dbname) and control02 = @@servername)

	--  call the restore syntax generator
	Select @Restore_cmd = ''

		
		exec dbaadmin.dbo.dbasp_print 'USING COMMAND: a',1,1,1;
		exec dbaadmin.dbo.dbasp_print 'EXEC [dbaadmin].[dbo].[dbasp_format_BackupRestore]',2,1,1;
		SET @cmd = '@DBName = '''+@dbname+'''';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1;
		SET @cmd = ',@Mode = ''RD''';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1; 
		SET @cmd = ',@FilePath = '''+@save_prod_server+'''';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1; 
		SET @cmd = ',@Verbose = 0';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1;
		SET @cmd = ',@FullReset = 1';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1; 
		SET @cmd = ',@NoDifRestores = 1';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1;
		SET @cmd = ',@NoLogRestores = 1';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1;
		SET @cmd = ',@LeaveNORECOVERY = 1';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1;
		SET @cmd = ',@syntax_out = @Restore_cmd OUTPUT';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1; 
		


	EXEC [dbaadmin].[dbo].[dbasp_format_BackupRestore] 
		 @DBName = @dbname
		,@Mode = 'RD' 
		,@FilePath = @save_prod_server 
		,@Verbose = 0
		,@FullReset = 1 
		,@NoDifRestores = 1
		,@NoLogRestores = 1
		,@LeaveNORECOVERY = 1
		,@syntax_out = @Restore_cmd OUTPUT 

	Select @restore_from_prod = 'y'

	goto Process_the_restore
   end



--  Do we have a current snapshot for this DB
Print 'Check for current snapshot ' + convert(varchar(30),getdate(),9)
raiserror('', -1,-1) with nowait

Select @SnapDBName = 'z_snap_' + @dbname

Select @CustomProperty = 'SnapshotModDate_'+@dbname

IF NOT EXISTS (SELECT value FROM fn_listextendedproperty(@CustomProperty, default, default, default, default, default, default))
   begin
	PRINT 'No snapshot Property Found for DB ' + @dbname + ' ' + convert(varchar(30),getdate(),9)
	goto start_restore_from_backup
   end

IF DB_ID(@SnapDBName) IS NULL
   BEGIN
	PRINT 'No snapshot DB Found for DB ' + @dbname + ' ' + convert(varchar(30),getdate(),9)
	goto start_restore_from_backup
   end

	

--  Does the snapshot match the most recent baseline file on the central server
Print 'Test current snapshot vs most recent central baseline file ' + convert(varchar(30),getdate(),9)
raiserror('', -1,-1) with nowait

PRINT 'Reading Snapshot Property ' + convert(varchar(30),getdate(),9)
SELECT @IsSnapshot = 1, @CurrentModValue = CAST(value AS DateTime)
FROM fn_listextendedproperty(@CustomProperty, default, default, default, default, default, default)


If @CurrentModValue <> @CentralBaselineModDate
   begin
	PRINT 'Baseline Snapshot is NOT up to date ' + convert(varchar(30),getdate(),9)
	goto start_restore_from_backup
   end
Else
   BEGIN
	PRINT 'Baseline Snapshot is up to date ' + convert(varchar(30),getdate(),9)
	SELECT @IsSnapCurrent = 1
   END




--  Revert to snapshot
Print 'Perform the snapshot revert ' + convert(varchar(30),getdate(),9)
raiserror('', -1,-1) with nowait

IF @IsSnapshot = 1 AND @IsSnapCurrent = 1
   BEGIN
	PRINT 'Starting Snapshot Revert ' + convert(varchar(30),getdate(),9)
	PRINT '  Killing All Connections ' + convert(varchar(30),getdate(),9)
	raiserror('', -1,-1) with nowait

	SELECT *
		FROM MASTER.sys.SYSPROCESSES 
		WHERE DB_NAME(DBID) = @DBNAME
	PRINT ''
	raiserror('', -1,-1) with nowait
	
	-- START BY KILLING ALL CONNECTIONS IN DB
	DECLARE USERS CURSOR FOR 
	SELECT SPID
	FROM MASTER.sys.SYSPROCESSES 
	WHERE DB_NAME(DBID) = @DBNAME
	AND SPID > 50 

	OPEN USERS
	FETCH NEXT FROM USERS INTO @SPID

	WHILE @@FETCH_STATUS <> -1
	   BEGIN
		IF @@FETCH_STATUS = 0
		   BEGIN
			SET @STR = 'KILL ' + CONVERT(VARCHAR, @SPID)
			Print @STR
			EXEC (@STR)
		   END
		   
		FETCH NEXT FROM USERS INTO @SPID
	   END
	DEALLOCATE USERS

	IF DB_ID(@SnapDBName) IS NOT NULL
	   BEGIN
		-- Reverting DATABASE
		PRINT ' Reverting to Snapshot for DB ' + @DBName + ' ' + convert(varchar(30),getdate(),9)
		raiserror('', -1,-1) with nowait
		SET @TSQL = 'RESTORE DATABASE '+@DBName+' FROM DATABASE_SNAPSHOT = '''+@SnapDBName+''''

		BEGIN TRY
			Print @TSQL
			raiserror('', -1,-1) with nowait
			EXEC (@TSQL)
		END TRY
		BEGIN CATCH
			Select @miscprint = 'DBA Warning:  Snapshot revert failed in the try\catch. ' + convert(varchar(30),getdate(),9)
			PRINT @miscprint
			raiserror('', -1,-1) with nowait

			PRINT ' Try restore from backup now.'
			raiserror('', -1,-1) with nowait

			goto start_restore_from_backup
		END CATCH

		
		PRINT ' Revert to Snapshot completed for DB ' + @DBName + ' ' + convert(varchar(30),getdate(),9)
		raiserror('', -1,-1) with nowait


		Print 'Double Check the Revert ' + convert(varchar(30),getdate(),9)
		--  Verify the revert worked
		If (DATABASEPROPERTYEX(@dbname, N'Status') != N'ONLINE')
		   begin
			Select @miscprint = 'DBA Warning:  Snapshot revert failed.  Trying restore from backup. ' + convert(varchar(30),getdate(),9)
			Print @miscprint
			raiserror('', -1,-1) with nowait 
			goto start_restore_from_backup
		   end
		Else 
		   begin
			-- Get the baseline date for the post snapshot DB.
			Select @cmd = 'USE ' + quotename(@dbname) + ' SELECT @basedate = (select top 1 dtBuildDate from dbo.build where vchLabel like ''%Baseline%'' order by iBuildID desc)'
			--Print @cmd

			EXEC sp_executesql @cmd, N'@basedate datetime output', @basedate output

			If datediff(hh, @basedate, @CentralBaselineModDate) > 8
			   begin
				Select @miscprint = 'DBA Warning:  Post Snapshot baseline date does not match central baseline date.  Trying restore from backup. ' + convert(varchar(30),getdate(),9)
				Print @miscprint
				raiserror('', -1,-1) with nowait 
				goto start_restore_from_backup
			   end
		   end


		goto update99	
	   END
	ELSE
	   BEGIN
		PRINT ' No Snapshot Found for DB ' + @DBName + ' ' + convert(varchar(30),getdate(),9)
		raiserror('', -1,-1) with nowait
		SELECT @IsSnapshot = 0, @IsSnapCurrent = 0
		goto start_restore_from_backup
	   END
   END







------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
start_restore_from_backup:
Print 'Starting the Restore from Backup Section'
raiserror('', -1,-1) with nowait

--  Drop the related snapshot if it exists
Select @SnapDBName = 'z_snap_' + @dbname
IF DB_ID(@SnapDBName) IS NOT NULL
   BEGIN
	EXEC dbaadmin.dbo.dbasp_KillAllOnDB @SnapDBName
	PRINT 'Dropping Snapshot for DB ' + @dbname
	raiserror('', -1,-1) with nowait
	SET @TSQL = 'DROP DATABASE '+@SnapDBName
	EXEC (@TSQL)
   END

SELECT @IsSnapshot = 0, @IsSnapCurrent = 0


--  If the DB is in suspect or loading mode, drop it
If (DATABASEPROPERTYEX(@dbname, N'Status')) in ('RESTORING', 'RECOVERING', 'SUSPECT')
   begin
	Print 'Droping the database due to DB status at the start of the restore from backup section.'
	Select (DATABASEPROPERTYEX(@dbname, N'Status'))
	Select @cmd = 'drop database ' + rtrim(@dbname)
	raiserror('', -1,-1) with nowait
	exec (@cmd)
   end


Select @trys = 0



--  Restore MINI Section (if control record found)
Select @restore_mini = 'n'
If exists (select 1 from dbo.ControlTable where subject = 'prerestore_mini' and control01 = rtrim(@dbname) and control02 = @@servername)
   begin
	Select @restore_mini = 'y'

	Print 'Restoring mini for DB ' + @dbname
	raiserror('', -1,-1) with nowait

	Print 'Format the restore mini command'
	raiserror('', -1,-1) with nowait

	Select @ForceFileName = @dbname + '_prod'

	Select @mini_backup_path = (select control03 from dbo.ControlTable where subject = 'prerestore_mini' and control01 = rtrim(@dbname) and control02 = @@servername)

	Select @Restore_cmd = ''

		exec dbaadmin.dbo.dbasp_print 'USING COMMAND: b',1,1,1;
		exec dbaadmin.dbo.dbasp_print 'EXEC [dbaadmin].[dbo].[dbasp_format_BackupRestore]',2,1,1;
		SET @cmd = '@DBName = '''+@dbname+'''';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1;
		SET @cmd = ',@Mode = ''RD''';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1; 
		SET @cmd = ',@FilePath = '''+@mini_backup_path+'''';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1;
		SET @cmd = ',@ForceFileName = '''+@ForceFileName+'''';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1; 
		SET @cmd = ',@Verbose = 0';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1;
		SET @cmd = ',@FullReset = 1';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1; 
		SET @cmd = ',@NoDifRestores = 1';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1;
		SET @cmd = ',@NoLogRestores = 1';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1;
		SET @cmd = ',@LeaveNORECOVERY = 0';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1;
		SET @cmd = ',@syntax_out = @Restore_cmd OUTPUT';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1; 

	EXEC [dbaadmin].[dbo].[dbasp_format_BackupRestore] 
		 @DBName = @dbname
		,@Mode = 'RD' 
		,@FilePath = @mini_backup_path 
		,@ForceFileName = @ForceFileName
		,@Verbose = 0
		,@FullReset = 1 
		,@NoDifRestores = 1
		,@NoLogRestores = 1
		,@LeaveNORECOVERY = 0
		,@syntax_out = @Restore_cmd OUTPUT 


	Select @drop_db = 'DROP DATABASE [' + @dbname + ']'
    
	Select @drop_try = ''
	Select @drop_try = @drop_try + 'Begin TRY' + char(13)+char(10)
	Select @drop_try = @drop_try + @drop_db + char(13)+char(10)
	Select @drop_try = @drop_try + 'End TRY' + char(13)+char(10)
	Select @drop_try = @drop_try + 'Begin CATCH' + char(13)+char(10)
	Select @drop_try = @drop_try + 'Print ''DROP DATABASE Failed''' + char(13)+char(10)
	Select @drop_try = @drop_try + 'End CATCH' + char(13)+char(10)
	
	Select @Restore_cmd = Replace(@Restore_cmd, @drop_db, @drop_try) 

	--  Print the restore command
	Print 'Here is the mini DB restore command being executed;'
	exec dbaadmin.dbo.dbasp_PrintLarge @Restore_cmd
	raiserror('', -1,-1) with nowait

	--  Run the restore command
	Exec (@Restore_cmd)

	--  Verify mini DB
	If (DATABASEPROPERTYEX(@dbname, N'Status') != N'ONLINE')
	   begin
		Select @miscprint = 'DBA Warning:  Restore mini failed.'
		Print @miscprint
		raiserror('', -1,-1) with nowait

		Select @restore_mini = 'n'
		goto restore_from_local
	   end

	--  Clean mini and set DB access
	exec SQLdeploy.dbo.dpsp_auto_deny_DBAccess

	EXEC SQLdeploy.dbo.dpsp_auto_DataSync_Restore
    
	exec SQLdeploy.dbo.dpsp_auto_DBsecurity_clean

	exec SQLdeploy.dbo.dpsp_auto_Reset_DBuser_Access

	update SQLdeploy.dbo.DBuser_Access_Ctrl set is_processed = 'n' where DBname = @dbname

	Select @z_dbname_new = 'z_' + @dbname + '_new'
	Print 'Mini DB ' + @dbname + ' is now available.  Starting prerestore for DB ' + @z_dbname_new
	raiserror('', -1,-1) with nowait
   end



-------------------------------------------
--  Restore using the local baseline file
-------------------------------------------
restore_from_local:

If @restore_from_prod = 'y'
   begin
	Print 'Restoring from prod.  Skip restore from local section.'
	raiserror('', -1,-1) with nowait
	goto restore_from_central
   end

If @LocalBaselineModDate is null or @CentralBaselineModDate <> @LocalBaselineModDate
   begin
	Print 'Problem with local baseline.  Trying restore from central.'
	raiserror('', -1,-1) with nowait
	goto restore_from_central
   end


--  call the restore syntax generator
Print 'Format the restore command'
raiserror('', -1,-1) with nowait

If @save_local_baseline_filename like '%[_]FG[_]%'
   begin
	Select @save_local_baseline_filename = reverse(@save_local_baseline_filename)
	Select @charpos = charindex('dorp_', @save_local_baseline_filename)
	IF @charpos <> 0
	   begin
		Select @ForceFileName = substring(@save_local_baseline_filename, @charpos, len(@save_local_baseline_filename)-@charpos+1)
		Select @ForceFileName = reverse(@ForceFileName)
	   end
	Else
	   begin
		Print 'Problem with the @save_local_baseline_filename. ' + reverse(@save_local_baseline_filename)
		raiserror('', -1,-1) with nowait
		goto restore_from_central
	   end
   end
Else
   begin
	Select @ForceFileName = @dbname + '_prod'
   end	


BEGIN TRY

		exec dbaadmin.dbo.dbasp_print 'USING COMMAND: c',1,1,1;
		exec dbaadmin.dbo.dbasp_print 'EXEC [dbaadmin].[dbo].[dbasp_format_BackupRestore]',2,1,1;
		SET @cmd = '@DBName = '''+@dbname+'''';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1;
		SET @cmd = '@NewDBName = '''+@z_dbname_new+'''';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1;
		SET @cmd = ',@Mode = ''RD''';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1; 
		SET @cmd = ',@FilePath = '''+@local_base_path+'''';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1;
		SET @cmd = ',@ForceFileName = '''+@ForceFileName+'''';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1; 
		SET @cmd = ',@Verbose = 0';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1;
		SET @cmd = ',@FullReset = 1';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1; 
		SET @cmd = ',@NoDifRestores = 1';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1;
		SET @cmd = ',@NoLogRestores = 1';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1;
		SET @cmd = ',@LeaveNORECOVERY = 0';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1;
		SET @cmd = ',@syntax_out = @Restore_cmd OUTPUT';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1;


Select @Restore_cmd = ''
EXEC [dbaadmin].[dbo].[dbasp_format_BackupRestore] 
	 @DBName = @dbname
	,@NewDBName = @z_dbname_new
	,@Mode = 'RD' 
	,@FilePath = @local_base_path 
	,@ForceFileName = @ForceFileName
	,@Verbose = 0
	,@FullReset = 1 
	,@NoDifRestores = 1
	,@NoLogRestores = 1
	,@LeaveNORECOVERY = 0
	,@syntax_out = @Restore_cmd OUTPUT 


If @restore_mini = 'y'
   begin
	Select @drop_db = 'DROP DATABASE [' + @z_dbname_new + ']'
   end
Else
   begin
	Select @drop_db = 'DROP DATABASE [' + @dbname + ']'
   end

Select @drop_try = ''
Select @drop_try = @drop_try + 'Begin TRY' + char(13)+char(10)
Select @drop_try = @drop_try + @drop_db + char(13)+char(10)
Select @drop_try = @drop_try + 'End TRY' + char(13)+char(10)
Select @drop_try = @drop_try + 'Begin CATCH' + char(13)+char(10)
Select @drop_try = @drop_try + 'Print ''DROP DATABASE Failed''' + char(13)+char(10)
Select @drop_try = @drop_try + 'End CATCH' + char(13)+char(10)

Select @Restore_cmd = Replace(@Restore_cmd, @drop_db, @drop_try) 


--  Print the restore command
Print 'Here is the DB restore command being executed;'
exec dbaadmin.dbo.dbasp_PrintLarge @Restore_cmd
raiserror('', -1,-1) with nowait


--  Run the restore command
Exec (@Restore_cmd)

END TRY
BEGIN CATCH
	Print ''
	Print 'Restore from local failed.  Trying restore from central.'
	raiserror('', -1,-1) with nowait
	goto restore_from_central
END CATCH


goto final_check





-------------------------------------------
--  Restore using the central baseline file
-------------------------------------------
restore_from_central:


--  call the restore syntax generator
	Print ''
Print 'Format the restore command'
raiserror('', -1,-1) with nowait

If @save_central_baseline_filename like '%[_]FG[_]%'
   begin
	Select @save_central_baseline_filename = reverse(@save_central_baseline_filename)
	Select @charpos = charindex('dorp_', @save_central_baseline_filename)
	IF @charpos <> 0
	   begin
		Select @ForceFileName = substring(@save_central_baseline_filename, @charpos, len(@save_central_baseline_filename)-@charpos+1)
		Select @ForceFileName = reverse(@ForceFileName)
	   end
	Else
	   begin
		Print 'Problem with the @save_central_baseline_filename. ' + reverse(@save_central_baseline_filename)
		raiserror('', -1,-1) with nowait
		goto restore_from_central
	   end
   end
Else
   begin
	Select @ForceFileName = @dbname + '_prod'
   end	


		exec dbaadmin.dbo.dbasp_print 'USING COMMAND: d',1,1,1;
		exec dbaadmin.dbo.dbasp_print 'EXEC [dbaadmin].[dbo].[dbasp_format_BackupRestore]',2,1,1;
		SET @cmd = '@DBName = '''+@dbname+'''';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1;
		SET @cmd = '@NewDBName = '''+@z_dbname_new+'''';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1;
		SET @cmd = ',@Mode = ''RD''';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1; 
		SET @cmd = ',@FilePath = '''+@central_backup_path+'''';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1;
		SET @cmd = ',@ForceFileName = '''+@ForceFileName+'''';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1; 
		SET @cmd = ',@Verbose = 0';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1;
		SET @cmd = ',@FullReset = 1';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1; 
		SET @cmd = ',@NoDifRestores = 1';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1;
		SET @cmd = ',@NoLogRestores = 1';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1;
		SET @cmd = ',@LeaveNORECOVERY = 0';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1;
		SET @cmd = ',@syntax_out = @Restore_cmd OUTPUT';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1;

Select @Restore_cmd = ''
EXEC [dbaadmin].[dbo].[dbasp_format_BackupRestore] 
	 @DBName = @dbname
	,@NewDBName = @z_dbname_new
	,@Mode = 'RD' 
	,@FilePath = @central_backup_path 
	,@ForceFileName = @ForceFileName
	,@Verbose = 0
	,@FullReset = 1 
	,@NoDifRestores = 1
	,@NoLogRestores = 1
	,@LeaveNORECOVERY = 0
	,@syntax_out = @Restore_cmd OUTPUT 


If @restore_mini = 'y'
   begin
	Select @drop_db = 'DROP DATABASE [' + @z_dbname_new + ']'
   end
Else
   begin
	Select @drop_db = 'DROP DATABASE [' + @dbname + ']'
   end

Select @drop_try = ''
Select @drop_try = @drop_try + 'Begin TRY' + char(13)+char(10)
Select @drop_try = @drop_try + @drop_db + char(13)+char(10)
Select @drop_try = @drop_try + 'End TRY' + char(13)+char(10)
Select @drop_try = @drop_try + 'Begin CATCH' + char(13)+char(10)
Select @drop_try = @drop_try + 'Print ''DROP DATABASE Failed''' + char(13)+char(10)
Select @drop_try = @drop_try + 'End CATCH' + char(13)+char(10)

Select @Restore_cmd = Replace(@Restore_cmd, @drop_db, @drop_try) 



--  Process the restore 
Process_the_restore: 



--  Print the restore command
Print ''
Print 'Here is the DB restore command being executed;'
exec dbaadmin.dbo.dbasp_PrintLarge @Restore_cmd
raiserror('', -1,-1) with nowait


--  Run the restore command
Exec (@Restore_cmd)



--  If this was a restore from prod, a differential restore is now needed.
If @restore_from_prod = 'y'
   begin

		exec dbaadmin.dbo.dbasp_print 'USING COMMAND: e',1,1,1;
		exec dbaadmin.dbo.dbasp_print 'EXEC [dbaadmin].[dbo].[dbasp_format_BackupRestore]',2,1,1;
		SET @cmd = '@DBName = '''+@dbname+'''';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1;
		SET @cmd = ',@Mode = ''RD''';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1; 
		SET @cmd = ',@FilePath = '''+@save_prod_server+'''';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1;
		SET @cmd = ',@ForceFileName = '''+@ForceFileName+'''';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1; 
		SET @cmd = ',@Verbose = 0';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1;
		SET @cmd = ',@FullReset = 1';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1; 
		SET @cmd = ',@NoDifRestores = 1';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1;
		SET @cmd = ',@NoLogRestores = 1';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1;
		SET @cmd = ',@syntax_out = @Restore_cmd OUTPUT';exec dbaadmin.dbo.dbasp_print @cmd,3,1,1;

	--  call the restore syntax generator
	Select @Restore_cmd = ''
	EXEC [dbaadmin].[dbo].[dbasp_format_BackupRestore] 
		 @DBName = @dbname
		,@Mode = 'RD' 
		,@FilePath = @save_prod_server
		,@Verbose = 0
		,@FullReset = 1 
		,@NoFullRestores = 1
		,@NoLogRestores = 1
		,@syntax_out = @Restore_cmd OUTPUT 

	Select @Restore_cmd = Replace(@Restore_cmd, 'DROP DATABASE', '--DROP DATABASE') 
	Select @Restore_cmd = Replace(@Restore_cmd, 'EXEC [msdb]', '--EXEC [msdb]') 

	-- Restore the DB
	Print ''
	Print 'Here is the Differential restore command being executed;'
	exec dbaadmin.dbo.dbasp_PrintLarge @Restore_cmd
	raiserror('', -1,-1) with nowait

	Exec (@Restore_cmd)
   end



goto final_check



final_check:

--  If a mini restore was done, flip the DB
If @restore_mini = 'y'
   begin
	If (DATABASEPROPERTYEX(@z_dbname_new, N'Status') != N'ONLINE')
	   begin
		Select @miscprint = 'DBA Warning:  Restore failed for ' + @z_dbname_new
		Print @miscprint
		raiserror('', -1,-1) with nowait
		Select @error_count = @error_count + 1
		goto label99
	   end

	Print ''
	Print 'Starting flip from mini to full DB for ' + @dbname
	raiserror('', -1,-1) with nowait

	EXEC SQLdeploy.dbo.dpsp_auto_DataSync_Save

	exec SQLdeploy.dbo.dpsp_auto_SetStatusForRestore
	EXEC dbaadmin.dbo.dbasp_KillAllOnDB @dbname
	PRINT 'Dropping mini DB ' + @dbname
	raiserror('', -1,-1) with nowait
	SET @TSQL = 'DROP DATABASE '+@dbname
	EXEC (@TSQL)
	print ' '

	exec dbaadmin.dbo.dbasp_renameDB @current_dbname = @z_dbname_new,
					@new_dbname = @dbname,
					@force_newldf  = 'n'

	Print ''
	Print 'DB flip completed'
	raiserror('', -1,-1) with nowait
   end




If (DATABASEPROPERTYEX(@dbname, N'Status') != N'ONLINE')
   begin
	Select @miscprint = 'DBA Warning:  Restore failed.'
	Print @miscprint
	raiserror('', -1,-1) with nowait
	If @trys < 2
	   begin
		If (DATABASEPROPERTYEX(@dbname, N'Status')) is not null
		   begin
			Print 'Droping the database prior to a retry.'
			Select @cmd = 'drop database ' + rtrim(@dbname)
			Print @cmd
			raiserror('', -1,-1) with nowait
			exec (@cmd)
		   end
		Select @trys = @trys + 1
		Select @miscprint = 'Trying restore from central backup'
		Print @miscprint
		raiserror('', -1,-1) with nowait
		goto restore_from_central
	   end
	Else
	   begin
		Select @miscprint = 'DBA WARNING: Restore failed for database ' + @dbname 
		Print @miscprint
		raiserror('', -1,-1) with nowait
		Select @error_count = @error_count + 1
		goto label99
	   end
   end
Else
   begin
	Select DATABASEPROPERTYEX(@dbname, N'Status')
	Select @miscprint = 'Restore completed with success.'
	Print @miscprint
	raiserror('', -1,-1) with nowait 
   end




update99:


--  Create new snapshot if needed
If @IsSnapCurrent = 0 and @nxt_path is not null
   begin
	--  Standard SQL canot create snapshots
	If @@version like '%Standard Edition%'
	   begin
		Select @miscprint = 'Skip snapshot process (Standard Edition) for server ' + @@servername
		Print @miscprint
		raiserror('', -1,-1) with nowait
		goto skip_snapshot
	   end
	
	--  Should we skip snapshot for this DB?
	If exists (select 1 from dbo.ControlTable where subject = 'DB_snapshot_nocheck' and control01 = @dbname)
	   begin
		Select @miscprint = 'Skip snapshot process for DB ' + @dbname 
		Print @miscprint
		raiserror('', -1,-1) with nowait
		goto skip_snapshot
	   end
		


	Select @SnapDBName = 'z_snap_' + @dbname
	Select @CustomProperty = 'SnapshotModDate_'+@dbname

	PRINT 'Snapshot Database AS ' + @SnapDBName
	SET @TSQL = NULL
			
	SELECT @TSQL = COALESCE(@TSQL,'')+',(NAME = '+name+', FILENAME = '''+@nxt_path+'\'+@SnapDBName+'_'+name+'.ss'')'+CHAR(13)+CHAR(10) 
	FROM master.sys.Master_files
	WHERE database_id = DB_ID(@DBName) AND type = 0 AND state = 0
	ORDER BY file_id

	SET @TSQL = 'CREATE DATABASE '+@SnapDBName+' ON' +CHAR(13)+CHAR(10)
			+ STUFF(@TSQL,1,1,'')
			+ 'AS SNAPSHOT OF ' + @DBName
	Print @TSQL
	EXEC (@TSQL)

	IF DB_ID(@SnapDBName) IS NULL
	   BEGIN
		PRINT 'Unable to create snapshot for DB ' + @dbname
		raiserror('', -1,-1) with nowait
		If EXISTS (SELECT value FROM fn_listextendedproperty(@CustomProperty, default, default, default, default, default, default))
		   begin
			EXEC sys.sp_dropextendedproperty @Name = @CustomProperty, @value = @CentralBaselineModDate
		   end
		goto restore_from_central
	   end
	Else IF NOT EXISTS (SELECT value FROM fn_listextendedproperty(@CustomProperty, default, default, default, default, default, default))
	   BEGIN
		PRINT 'Adding Property'
		EXEC sys.sp_addextendedproperty @Name = @CustomProperty, @value = @CentralBaselineModDate
	   END
	ELSE
	   BEGIN
		PRINT 'Updating Property'
		EXEC sys.sp_updateextendedproperty @Name = @CustomProperty, @value = @CentralBaselineModDate
	   END

	skip_snapshot:
   end


--  Update control_local with baseline info
SET @dynamicVAR = '@baseline_info sysname OUTPUT'
SET @dynamicSQL = 'select @baseline_info = (select top (1) convert(nvarchar(10), dtBuildDate, 120) from ' + @dbname + '.dbo.build where vchLabel like ''%baseline%'' order by iBuildID)'
EXEC sp_executesql @dynamicSQL, @dynamicVAR, @baseline_info OUTPUT

If @baseline_info is not null
   begin
	Select @baseline_info = 'Baseline: ' + @baseline_info
   end
Else
   begin
	Select @baseline_info = 'Baseline date not found'
   end

update dbo.Request_local set ProcessDetail = @baseline_info where DeployID = @save_DeployID and DBname = @dbname and status like '%in-work%'


--  Update the request_central DB
If @save_envname = 'local'
   begin
	goto skip_centralupdate_02
   end

Select @CentralSQLname = (select top 1 env_name from dbo.enviro_info where env_type = 'DEPLOYcentralServer')

select @query = 'Update DEPLOYcentral.dbo.Request_central set status = ''in-work_restore'', ProcessDetail = ''' + @baseline_info + ''', ModDate = getdate()'
select @query = @query + ' where DeployID = ' + convert(nvarchar(15), @save_DeployID)
select @query = @query + ' and SQLname = ''' + @@servername + ''''
select @query = @query + ' and process = ''restore'''
select @query = @query + ' and DBname = ''' + @dbname + ''''
Print 'Update DEPLOYcentral.dbo.Request_central 01'
raiserror('', -1,-1) with nowait
Print @query
Select @cmd = 'sqlcmd -S' + @CentralSQLname + ' -dDEPLOYcentral -E -Q"' + @query + '"'
print @cmd
Select @retry = 0
central_update_start02:
delete from #output 
Insert into #output EXEC master.sys.xp_cmdshell @cmd--, no_output

If exists (select 1 from #output where output_data like '%error%')
   begin
	Select @retry = @retry + 1
	Waitfor delay '00:00:10'
	If @retry < @retry_limit
	   begin
		goto central_update_start02
	   end
	Else
	   begin
		Select @miscprint = 'DBA Error:  Unable to update central server via sqlcmd.'
		Print @miscprint 
		raiserror(@miscprint,-1,-1) with log
	   end
   end


skip_centralupdate_02:



--  Finalization  -------------------------------------------------------------------
label99:

If @save_envname = 'local'
   begin
	select @cmd = 'net use /DELETE ' + @central_backup_path
	print @cmd
	exec master.sys.xp_cmdshell @cmd--, no_output
   end


drop table #output



If  @error_count > 0
   begin
	raiserror(67016, 16, -1, @miscprint)

	print 'RETURN (1)'
   end
Else
   begin
	print 'RETURN (0)'
   end

 
 
 
