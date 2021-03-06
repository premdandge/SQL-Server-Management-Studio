USE [DEPLcontrol]
GO
/****** Object:  StoredProcedure [dbo].[dpsp_ahp_RequestInsertTarget]    Script Date: 10/4/2013 11:02:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[dpsp_ahp_RequestInsertTarget]

/*********************************************************
 **  Stored Procedure dpsp_ahp_RequestInsertTarget                  
 **  Written by Jim Wilson, Getty Images                
 **  October 22, 2010                                      
 **  
 **  This sproc will process deployment requests from AHP,
 **  found in the AHP_Import_Requests table, and insert
 **  that information into the control_ahp tables on the 
 **  target servers.
 **
 ***************************************************************/
  as
set nocount on

--	======================================================================================
--	Revision History
--	Date		Author     		Desc
--	==========	====================	=============================================
--	10/26/2010	Jim Wilson		New process.
--	11/19/2010	Jim Wilson		Modified update to AHP_Import_Requests.
--	01/28/2011	Jim Wilson		Changed check for in_work deployments to look at control_ahp table.
--	03/04/2011	Jim Wilson		Added code for manual starts.
--	03/08/2011	Jim Wilson		Removed the start process at the very end.
--	03/17/2011	Jim Wilson		Check for "like 'Central_Inserted%'"
--	======================================================================================


/***

--***/

-----------------  declares  ------------------

DECLARE
	 @miscprint			nvarchar(2000)
	,@query				nvarchar(2000)
	,@cmd				nvarchar(4000)
	,@charpos			int
	,@returncode			int
	,@save_servername		sysname
	,@save_servername2		sysname
	,@save_servername3		sysname
	,@save_Request_id		int
	,@save_Request_Status		sysname
	,@save_handshake_status		sysname
	,@save_Request_start		datetime
	,@save_TargetSQLname		sysname
	,@save_SQLport			sysname
	,@save_SQLname			sysname
	,@save_Request_notes		nvarchar(500)
	,@save_subject			sysname
	,@save_message			nvarchar(2000)
	,@save_DBname			sysname
	,@save_BaseName			sysname
	,@save_APPLname			sysname
	,@save_Request_type		sysname
	,@save_ProjectName		sysname
	,@save_ReleaseNum		sysname
	,@save_BuildNum			sysname
	,@status_success		sysname
	,@status_fail			sysname


/*********************************************************************
 *                Initialization
 ********************************************************************/

Select @save_servername		= @@servername
Select @save_servername2	= @@servername
Select @save_servername3	= @@servername

Select @charpos = charindex('\', @save_servername)
IF @charpos <> 0
   begin
	Select @save_servername = substring(@@servername, 1, (CHARINDEX('\', @@servername)-1))

	Select @save_servername2 = stuff(@save_servername2, @charpos, 1, '$')

	select @save_servername3 = stuff(@save_servername3, @charpos, 1, '(')
	select @save_servername3 = @save_servername3 + ')'
   end


--  Create temp tables
CREATE TABLE #requests (Request_id int
			,SQLname sysname
			,Request_Status sysname)





----------------------  Print the headers  ----------------------

Print  ' '
Select @miscprint = 'SQL AHP Request Insert to Target from Server: ' + @@servername
Print  @miscprint
Select @miscprint = '-- Process run: ' + convert(varchar(30),getdate())
Print  @miscprint
Print  ' '
raiserror('', -1,-1) with nowait



--  Check to see if there are rows to process
If not exists (select 1 from dbo.AHP_Import_Requests where Request_Status like 'Central_Inserted%')
   begin
	Select @miscprint = 'No rows to process at this time'
	Print  @miscprint
	Print  ' '
	goto label99
   end





/****************************************************************
 *                MainLine
 ***************************************************************/

--  Get the Request_id/SQLname rows that need to be processed
delete from #requests
Insert into #requests select Request_id, TargetSQLname, Request_Status from dbo.AHP_Import_Requests where Request_Status like 'Central_Inserted%'
--select * from #requests

-- Loop through #requests
If (select count(*) from #requests) > 0
   begin
	requests_start:
	
	--  get the Request_id to process
	Select @save_Request_id = (select top 1 Request_id from #requests order by Request_id)
	Select @save_TargetSQLname = (select top 1 SQLname from #requests where Request_id = @save_Request_id order by SQLname)
	Select @save_Request_Status = (select top 1 Request_Status from #requests where Request_id = @save_Request_id and SQLname = @save_TargetSQLname order by Request_Status)

	Select @save_SQLport = (select top 1 port from dbacentral.dbo.dba_serverinfo where sqlname = @save_TargetSQLname)

	If (select top 1 SQLEnv from dbacentral.dbo.dba_serverinfo where sqlname = @save_TargetSQLname and Active = 'y') like 'prod%'
	   begin
		Select @status_success = 'Prod_Inserted'
		Select @status_fail = 'Prod_Insert_failed'
	   end
	Else
	   begin
		Select @status_success = 'Local_Inserted'
		Select @status_fail = 'Local_Insert_failed'
	   end

	If @save_Request_Status like '%manual%'
	   begin
		Select @status_success = @status_success + '_manual'
	   end

	--  Determine where we are at with the handshake process
	Select @save_handshake_status = (select top 1 Request_Status from dbo.AHP_Import_Requests where Request_id = @save_Request_id and TargetSQLname = @save_TargetSQLname and Request_type = 'handshake')

	Print ' '
	Print  @save_TargetSQLname + ' Handshake status = ' + @save_handshake_status
	raiserror('', -1,-1) with nowait
	
	If @save_handshake_status = 'queued'
	   begin
		Select @save_Request_start = (select top 1 Request_start from dbo.AHP_Import_Requests where Request_id = @save_Request_id and TargetSQLname = @save_TargetSQLname and Request_type = 'handshake')

		--  If we have already checked this instance within the past 5 minutes, skip it
		If DATEDIFF(ss, @save_Request_start, getdate()) < 300
		   begin
			delete from #requests where Request_id = @save_Request_id and SQLname = @save_TargetSQLname
			goto skip_instance
		   end
		   
		--  Check to see if we have an active deployment in progress for this sql instance
		If exists (select 1 from dbo.control_ahp where Request_id <> @save_Request_id and TargetSQLname = @save_TargetSQLname and (Status like '%in-work%' or Status like '%pending%'))
		   begin
			Select @miscprint = 'Request_id: ' + convert(nvarchar(20), @save_Request_id) + '  TargetSQLname: ' + @save_TargetSQLname + '  Note: Another deployment for this SQL instance is currently in progress'
			Print  @miscprint
			Print  ' '
			raiserror('', -1,-1) with nowait
			Update dbo.AHP_Import_Requests set Request_start = getdate() where Request_id = @save_Request_id and Request_Type = 'handshake' and TargetSQLname = @save_TargetSQLname
			delete from #requests where Request_id = @save_Request_id and SQLname = @save_TargetSQLname
			goto skip_instance
		   end
		   
		--  Perform the handshake process again for this server
		Select @save_SQLport = (select top 1 port from dbacentral.dbo.dba_serverinfo where sqlname = @save_TargetSQLname)

		Select @miscprint = 'Handshake status start for Request_id ' + convert(nvarchar(20), @save_Request_id) + ' and TargetSQLname ' + @save_TargetSQLname + '.'
		Print  @miscprint
		raiserror('', -1,-1) with nowait

		Update dbo.AHP_Import_Requests set Request_Status = 'in-work', Request_start = getdate() where Request_id = @save_Request_id and Request_Type = 'handshake' and TargetSQLname = @save_TargetSQLname

		select @query = 'exec DEPLinfo.dbo.dpsp_ahp_handshake @CentralSQLname = ''' + @@servername + ''', @Request_id = ' + convert(nvarchar(10), @save_Request_id)
		Print @query
		raiserror('', -1,-1) with nowait
		Select @cmd = 'sqlcmd -S' + @save_TargetSQLname + ',' + @save_SQLport + ' -dmaster -E -Q"' + @query + '"'
		print @cmd
		raiserror('', -1,-1) with nowait

		EXEC @returncode = master.sys.xp_cmdshell @cmd--, no_output

		--  handshake request has been sent.  Move on to the next request
		delete from #requests where Request_id = @save_Request_id and SQLname = @save_TargetSQLname
		goto skip_instance

	   end


	--  If a handshake has been in-work for more than 5 minutes, something is very wrong
	If @save_handshake_status = 'in-work'
	   begin
		Select @save_Request_start = (select top 1 Request_start from dbo.AHP_Import_Requests where Request_id = @save_Request_id and TargetSQLname = @save_TargetSQLname and Request_type = 'handshake')

		--  If we have already checked this instance within the past 5 minutes, skip it
		If DATEDIFF(ss, @save_Request_start, getdate()) < 300
		   begin
			delete from #requests where Request_id = @save_Request_id and SQLname = @save_TargetSQLname
			goto skip_instance
		   end
		   
		--  Notify SQLDBA that the handshake to this SQLname is not responding
		Select @save_Request_notes = (select top 1 Request_Notes from dbo.AHP_Import_Requests where Request_id = @save_Request_id and TargetSQLname = @save_TargetSQLname and Request_type = 'handshake')
		Select @save_subject = 'ERROR: DBA DEPLcontrol handshake from ' + @@servername + ' to ' + @save_TargetSQLname
		Select @save_message = 'DEPL handshake error for server ' + @save_TargetSQLname + ' and Request_id ' + convert(nvarchar(10), @save_Request_id) + '.  No reply from the target server.' + char(13)+char(10)
		Select @save_message = @save_message  + ' ' + char(13)+char(10)
		If @save_Request_notes is not null and @save_Request_notes <> ''
		   begin
			Select @save_message = @save_message  + 'Handshake error: ' + @save_Request_notes + char(13)+char(10)
		   end
		Select @save_message = @save_message  + ' ' + char(13)+char(10)
		Select @save_message = @save_message  + 'Please resolve the issue at the target server (' + convert(nvarchar(20), @save_Request_id)  + ') and run the following code from that server.' + char(13)+char(10)
		Select @save_message = @save_message  + ' ' + char(13)+char(10)
		Select @save_message = @save_message  + 'Use DEPLinfo' + char(13)+char(10)
		Select @save_message = @save_message  + 'go' + char(13)+char(10)
		Select @save_message = @save_message  + ' ' + char(13)+char(10)
		Select @save_message = @save_message  + 'exec dbo.dpsp_ahp_handshake @CentralSQLname = ''' + @@servername + ''', @Request_id = ' + convert(nvarchar(10), @save_Request_id) + '' + char(13)+char(10)
		Select @save_message = @save_message  + 'go' + char(13)+char(10)
		EXEC dbaadmin.dbo.dbasp_sendmail 
			@recipients = 'jim.wilson@gettyimages.com',  
			--@recipients = 'tssqldba@gettyimages.com',  
			@subject = @save_subject,
			@message = @save_message

		--  Set this back to 'queued' to reprocess in 5 minutes
		Update dbo.AHP_Import_Requests set Request_Status = 'queued', Request_start = getdate() where Request_id = @save_Request_id and Request_Type = 'handshake' and TargetSQLname = @save_TargetSQLname
		delete from #requests where Request_id = @save_Request_id and SQLname = @save_TargetSQLname
		Select @miscprint = 'Reset handshake from in-work to queued for re-processing.  Request_id: ' + convert(nvarchar(20), @save_Request_id) + '  TargetSQLname: ' + @save_TargetSQLname
		Print  @miscprint
		Print  ' '
		raiserror('', -1,-1) with nowait
		goto skip_instance
	   end


	---  Now process the rows that have not yet been processed
	If @save_handshake_status like 'Central_Inserted%'
	   begin		   
		--  Check to see if we have an active deployment in progress for this sql instance
		If exists (select 1 from dbo.control_ahp where Request_id <> @save_Request_id and TargetSQLname = @save_TargetSQLname and (Status like '%in-work%' or Status like '%pending%'))
		   begin
			Select @miscprint = 'Request_id: ' + convert(nvarchar(20), @save_Request_id) + '  TargetSQLname: ' + @save_TargetSQLname + '  Note: Another deployment for this SQL instance is currently in progress'
			Print  @miscprint
			Print  ' '
			raiserror('', -1,-1) with nowait
			Update dbo.AHP_Import_Requests set Request_start = getdate() where Request_id = @save_Request_id and Request_Type = 'handshake' and TargetSQLname = @save_TargetSQLname
			delete from #requests where Request_id = @save_Request_id and SQLname = @save_TargetSQLname
			goto skip_instance
		   end
		   
		--  Perform the handshake process again for this server
		Select @save_SQLport = (select top 1 port from dbacentral.dbo.dba_serverinfo where sqlname = @save_TargetSQLname)

		Select @miscprint = 'Handshake status start for Request_id ' + convert(nvarchar(20), @save_Request_id) + ' and TargetSQLname ' + @save_TargetSQLname + '.'
		Print  @miscprint
		raiserror('', -1,-1) with nowait

		Update dbo.AHP_Import_Requests set Request_Status = 'in-work', Request_start = getdate() where Request_id = @save_Request_id and Request_Type = 'handshake' and TargetSQLname = @save_TargetSQLname

		select @query = 'exec DEPLinfo.dbo.dpsp_ahp_handshake @CentralSQLname = ''' + @@servername + ''', @Request_id = ' + convert(nvarchar(10), @save_Request_id)
		Print @query
		raiserror('', -1,-1) with nowait
		Select @cmd = 'sqlcmd -S' + @save_TargetSQLname + ',' + @save_SQLport + ' -dmaster -E -Q"' + @query + '"'
		print @cmd
		raiserror('', -1,-1) with nowait

		EXEC @returncode = master.sys.xp_cmdshell @cmd--, no_output

		--  handshake request has been sent.  Move on to the next request
		delete from #requests where Request_id = @save_Request_id and SQLname = @save_TargetSQLname
		goto skip_instance
	   end


	--  Check to make sure handshake is completed
	If @save_handshake_status <> 'completed'
	   begin
		Select @save_subject = 'ERROR: DBA DEPLcontrol handshake from ' + @@servername + ' to ' + @save_TargetSQLname
		Select @save_message = 'DEPL handshake error for server ' + @save_TargetSQLname + ' and Request_id ' + convert(nvarchar(10), @save_Request_id) + '.  No reply from the target server.' + char(13)+char(10)
		Select @save_message = @save_message  + ' ' + char(13)+char(10)
		If @save_Request_notes is not null and @save_Request_notes <> ''
		   begin
			Select @save_message = @save_message  + 'Handshake error: ' + @save_Request_notes + char(13)+char(10)
		   end
		Select @save_message = @save_message  + ' ' + char(13)+char(10)
		Select @save_message = @save_message  + 'Invalid handshake status found for Request_id ' + convert(nvarchar(10), @save_Request_id) + ' and target server (' + @save_TargetSQLname  + ').' + char(13)+char(10)
		Select @save_message = @save_message  + ' ' + char(13)+char(10)
		Print @save_message
		EXEC dbaadmin.dbo.dbasp_sendmail 
			@recipients = 'jim.wilson@gettyimages.com',  
			--@recipients = 'tssqldba@gettyimages.com',  
			@subject = @save_subject,
			@message = @save_message

		--  Move on to the next request
		delete from #requests where Request_id = @save_Request_id and SQLname = @save_TargetSQLname
		goto skip_instance
	   end

----------------------------------
--  END OF HANDSHAKE SECTION
----------------------------------


	-- at this point, we know the handshake was good and we have rows that were not inserted to the local server
	start_local_insert:
	
	--  Capture data for the local insert, one DBname at a time
	Select @save_DBname = (select top 1 DBname from dbo.AHP_Import_Requests where Request_id = @save_Request_id and TargetSQLname = @save_TargetSQLname and Request_Status like 'Central_Inserted%')
	Select @save_Request_type = (select top 1 Request_type from dbo.AHP_Import_Requests where Request_id = @save_Request_id and TargetSQLname = @save_TargetSQLname and DBname = @save_DBname and Request_Status like 'Central_Inserted%')
	Select @save_BaseName = (select top 1 BaseName from dbo.AHP_Import_Requests where Request_id = @save_Request_id and TargetSQLname = @save_TargetSQLname and DBname = @save_DBname and Request_Status like 'Central_Inserted%')
	Select @save_ProjectName = (select top 1 ProjectName from dbo.AHP_Import_Requests where Request_id = @save_Request_id and TargetSQLname = @save_TargetSQLname and DBname = @save_DBname and Request_Status like 'Central_Inserted%')
	Select @save_ReleaseNum = (select top 1 ReleaseNum from dbo.AHP_Import_Requests where Request_id = @save_Request_id and TargetSQLname = @save_TargetSQLname and DBname = @save_DBname and Request_Status like 'Central_Inserted%')
	Select @save_BuildNum = (select top 1 BuildNum from dbo.AHP_Import_Requests where Request_id = @save_Request_id and TargetSQLname = @save_TargetSQLname and DBname = @save_DBname and Request_Status like 'Central_Inserted%')

	Select @save_APPLname = @save_BaseName
	Select @charpos = charindex('_', @save_APPLname)
	IF @charpos <> 0
	   begin
		Select @save_APPLname = substring(@save_APPLname, 1, @charpos-1)
	   end 
	   
		
	Select @miscprint = 'Processing DBname [' + @save_DBname + '] for Request_id: ' + convert(nvarchar(20), @save_Request_id) + '  TargetSQLname: ' + @save_TargetSQLname + '  Request Type: ' + @save_Request_type
	Print  @miscprint
	Print  ' '
	raiserror('', -1,-1) with nowait
	
	--  Insert restore row
	If @save_Request_type in ('normal', 'restore')
	   begin
		print 'Restore Insert Local Starting for DBname [' + @save_DBname + ']'
		raiserror('', -1,-1) with nowait

		select @query = 'If not exists (select 1 from DEPLinfo.dbo.control_ahp where Request_id = ' + convert(nvarchar(20), @save_Request_id) + ' and Process = ''restore'' and DBname = ''' + @save_DBname + ''') begin '
		select @query = @query + 'insert into DEPLinfo.dbo.control_ahp (Request_id, ProjectName, ProjectNum, status, Process, DBname, APPLname, BASEfolder, CreateDate)'
		select @query = @query + ' values (' + convert(nvarchar(20), @save_Request_id) + ', ''' + @save_ProjectName + ''''
		select @query = @query + ', ''' + @save_ReleaseNum + ''', ''pending'', ''restore'''
		select @query = @query + ', ''' + @save_DBname + ''', ''' + @save_APPLname + ''', ''' +  @save_BaseName + ''', getdate()) end'
		Print @query
		raiserror('', -1,-1) with nowait
		Select @cmd = 'sqlcmd -S' + @save_TargetSQLname + ',' + @save_SQLport + ' -dmaster -E -Q"' + @query + '"'
		print @cmd
		raiserror('', -1,-1) with nowait

		EXEC @returncode = master.sys.xp_cmdshell @cmd--, no_output		
        		
		If @returncode <> 0
		   begin
			print 'Restore Insert Failed'
			raiserror('', -1,-1) with nowait
			Update dbo.AHP_Import_Requests set Request_Status = @status_fail, Request_start = getdate() where Request_id = @save_Request_id and TargetSQLname = @save_TargetSQLname and DBname = @save_DBname
			goto skip_local_insert
		   end
		Else
		   begin
			Update dbo.AHP_Import_Requests set Request_Status = @status_success, Request_start = getdate() 
				where Request_id = @save_Request_id 
				and TargetSQLname = @save_TargetSQLname 
				and DBname = @save_DBname 
				and Request_type in ('normal', 'restore')
		   end
	   end
	   
	

	--  Insert deploy row
	If @save_Request_type in ('normal', 'deploy')
	   begin
   		print 'Deploy Full Local Insert Starting for DBname [' + @save_DBname + ']'
		raiserror('', -1,-1) with nowait

		select @query = 'If not exists (select 1 from DEPLinfo.dbo.control_ahp where Request_id = ' + convert(nvarchar(20), @save_Request_id) + ' and Process = ''deploy'' and DBname = ''' + @save_DBname + ''') begin '
		select @query = @query + 'insert into DEPLinfo.dbo.control_ahp (Request_id, ProjectName, ProjectNum, status, Process, ProcessType, ProcessDetail, DBname, APPLname, BASEfolder, CreateDate)'
		select @query = @query + ' values (' + convert(nvarchar(20), @save_Request_id) + ', ''' + @save_ProjectName + ''''
		select @query = @query + ', ''' + @save_ReleaseNum + ''', ''pending'', ''deploy'', ''full_on'', ''' + @save_BuildNum + ''''
		select @query = @query + ', ''' + @save_DBname + ''', ''' + @save_APPLname + ''', ''' +  @save_BaseName + ''', getdate()) end'
		Print @query
		raiserror('', -1,-1) with nowait
		Select @cmd = 'sqlcmd -S' + @save_TargetSQLname + ',' + @save_SQLport + ' -dmaster -E -Q"' + @query + '"'
		print @cmd
		raiserror('', -1,-1) with nowait

		EXEC @returncode = master.sys.xp_cmdshell @cmd--, no_output		
        		
		If @returncode <> 0
		   begin
			print 'Deploy Insert Failed'
			raiserror('', -1,-1) with nowait
			Update dbo.AHP_Import_Requests set Request_Status = @status_fail, Request_start = getdate() where Request_id = @save_Request_id and TargetSQLname = @save_TargetSQLname and DBname = @save_DBname
			goto skip_local_insert
		   end
		Else
		   begin
			Update dbo.AHP_Import_Requests set Request_Status = @status_success, Request_start = getdate() 
				where Request_id = @save_Request_id 
				and TargetSQLname = @save_TargetSQLname 
				and DBname = @save_DBname
				and Request_type in ('normal', 'deploy')
		   end
	   end
	   

	--  Insert sprocs_only row
	If @save_Request_type in ('sprocs_only')
	   begin
   		print 'Deploy Sprocs Local Insert Starting for DBname [' + @save_DBname + ']'
		raiserror('', -1,-1) with nowait
		
		select @query = 'If not exists (select 1 from DEPLinfo.dbo.control_ahp where Request_id = ' + convert(nvarchar(20), @save_Request_id) + ' and Process = ''deploy'' and DBname = ''' + @save_DBname + ''') begin '
		select @query = @query + 'insert into DEPLinfo.dbo.control_ahp (Request_id, ProjectName, ProjectNum, status, Process, ProcessType, ProcessDetail, DBname, APPLname, BASEfolder, CreateDate)'
		select @query = @query + ' values (' + convert(nvarchar(20), @save_Request_id) + ', ''' + @save_ProjectName + ''''
		select @query = @query + ', ''' + @save_ReleaseNum + ''', ''pending'', ''deploy'', ''sprocs'', ''' + @save_BuildNum + ''''
		select @query = @query + ', ''' + @save_DBname + ''', ''' + @save_APPLname + ''', ''' +  @save_BaseName + ''', getdate()) end'
		Print @query
		raiserror('', -1,-1) with nowait
		Select @cmd = 'sqlcmd -S' + @save_TargetSQLname + ',' + @save_SQLport + ' -dmaster -E -Q"' + @query + '"'
		print @cmd
		raiserror('', -1,-1) with nowait

		EXEC @returncode = master.sys.xp_cmdshell @cmd--, no_output		
        		
		If @returncode <> 0
		   begin
			print 'Sprocs_Only Insert Failed'
			raiserror('', -1,-1) with nowait
			Update dbo.AHP_Import_Requests set Request_Status = @status_fail, Request_start = getdate() where Request_id = @save_Request_id and TargetSQLname = @save_TargetSQLname and DBname = @save_DBname
			goto skip_local_insert
		   end
		Else
		   begin
			Update dbo.AHP_Import_Requests set Request_Status = @status_success, Request_start = getdate() 
				where Request_id = @save_Request_id 
				and TargetSQLname = @save_TargetSQLname 
				and DBname = @save_DBname
				and Request_type in ('sprocs_only')
		   end
	   end
	
	
	
	skip_local_insert:

	--  Check for more rows to process for this request/sqlname
	If exists (select 1 from dbo.AHP_Import_Requests where Request_id = @save_Request_id and TargetSQLname = @save_TargetSQLname and Request_Status like 'Central_Inserted%')
	   begin
		goto start_local_insert
	   end



	skip_instance:
	
	delete from #requests where Request_id = @save_Request_id and SQLname = @save_TargetSQLname

	If (select count(*) from #requests) > 0
	   begin
		goto requests_start
	   end

   end







-----------------  Finalizations  ------------------

label99:




drop TABLE #requests








GO
EXEC sys.sp_addextendedproperty @name=N'BuildApplication', @value=N'' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'dpsp_ahp_RequestInsertTarget'
GO
EXEC sys.sp_addextendedproperty @name=N'BuildBranch', @value=N'' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'dpsp_ahp_RequestInsertTarget'
GO
EXEC sys.sp_addextendedproperty @name=N'BuildNumber', @value=N'' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'dpsp_ahp_RequestInsertTarget'
GO
EXEC sys.sp_addextendedproperty @name=N'Version', @value=N'1.0.0' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'dpsp_ahp_RequestInsertTarget'
GO
