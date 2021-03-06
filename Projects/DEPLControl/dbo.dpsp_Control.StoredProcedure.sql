USE [DEPLcontrol]
GO
/****** Object:  StoredProcedure [dbo].[dpsp_Control]    Script Date: 10/4/2013 11:02:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[dpsp_Control] (@domain sysname = 'amer')

/*********************************************************
 **  Stored Procedure dpsp_Control                  
 **  Written by Jim Wilson, Getty Images                
 **  October 01, 2008                                      
 **  
 **  This sproc will control the SQL deployment process as
 **  part of the SQL Request Driven Process.
 **
 ***************************************************************/
  as
set nocount on

--	======================================================================================
--	Revision History
--	Date		Author     		Desc
--	==========	====================	=============================================
--	01/26/2009	Jim Wilson		New process.
--	02/25/2009	Jim Wilson		Added join for request_detail query to force 
--						db_sequence deploy order.
--	03/02/2009	Jim Wilson		Added gmail sendmail output for Jim W. 
--	03/06/2009	Jim Wilson		Added Retry in the handshake section. 
--	03/13/2009	Jim Wilson		Added %cancel% to check for new restore and deploy 
--	03/16/2009	Jim Wilson		Modified pre-handshake process to avoid deployments
--						to the same SQLname at the same time. 
--	03/26/2009	Jim Wilson		New status "manual" for requests with no components.
--	04/09/2009	Jim Wilson		Added raiserror with nowait for print statements.
--	04/10/2009	Jim Wilson		Added extra check section and new code for job check (never run).
--	04/14/2009	Jim Wilson		Added extra check for job "not running" (timing issue).
--	04/16/2009	Jim Wilson		Added Waitfor delay before extra check.
--	05/06/2009	Jim Wilson		Added error checking and retries for all sqlcmd statements.
--	05/07/2009	Jim Wilson		New lables to fix Gears update issue.
--	06/15/2009	Jim Wilson		Fixed bug with pre_release Diff backups (process = 'Deploy').
--	09/22/2009	Jim Wilson		Now updating Gears staus with sproc ChangeTicketStatus_sql.
--	09/30/2009	Jim Wilson		Added 'off' as a valid condition for next_build.
--	10/09/2009	Jim Wilson		New code for next override.
--	10/14/2009	Jim Wilson		Added check for pre-completed before we change from queued to pending.
--	12/01/2009	Jim Wilson		Added status update for long running restores.
--						Removed xp_cmdshell retrys.
--	12/02/2009	Jim Wilson		Added Gears status update for long running restores.
--	02/17/2010	Jim Wilson		Set row status back to pending for cases where the depl_rd job 
--						does not start.  All remote inserts are now conditional.
--	02/25/2010	Jim Wilson		New code to run dpsp_diag_jobs when DEPL_RD job is not running. 
--	08/04/2010	Jim Wilson		Updated gmail address.
--	08/11/2010	Jim Wilson		Updated updates for AHP.
--	11/08/2010	Jim Wilson		Added more updates for AHP.
--	11/11/2010	Jim Wilson		comment out updates for AHP.
--	05/12/2011	Jim Wilson		Removed all AHP related code.
--	09/15/2011	Jim Wilson		Updated central server name.
--	01/14/2013	Jim Wilson		Change to create a new timestamp just before we need it.
--	03/27/2013	Jim Wilson		Limit sendmail to one an hour per server.
--	05/02/2013	Jim Wilson		Added check for SQLdeploy activity.
--	======================================================================================


/***
Declare @domain sysname

Select @domain = 'production'
--***/

-----------------  declares  ------------------

DECLARE
	 @miscprint			nvarchar(2000)
	,@query				nvarchar(2000)
	,@cmd				nvarchar(4000)
	,@save_central_server		sysname
	,@temp_servername		sysname
	,@temp_servername2		sysname
	,@save_servername		sysname
	,@save_servername2		sysname
	,@save_servername3		sysname
	,@save_gears_id			int
	,@save_alt_gears_id		int
	,@save_projectname		sysname
	,@save_projectnum		sysname
	,@save_Project			sysname
	,@save_startdate		datetime
	,@save_starttime		nvarchar(50)
	,@save_Start			sysname
	,@save_environment		sysname
	,@save_notes			nvarchar(4000)
	,@hold_notes			nvarchar(4000)
	,@save_DBname			sysname
	,@save_component_option		sysname
	,@save_build_number		sysname
	,@save_component_restore	sysname
	,@save_next_build		sysname
	,@save_APPLname			sysname
	,@save_BASEfolder		sysname
	,@save_SQLname			sysname
	,@save_SQLport			nvarchar(5)
	,@save_domain			sysname
	,@save_BuildType		sysname
	,@save_Restore			char(1)
	,@save_RestoreType		sysname
	,@save_Build			sysname
	,@save_envnum			sysname
	,@save_APPLname_dependent_on	sysname
	,@save_dependent_SQLname	sysname
	,@DataExtract_flag		char(1)
	,@save_DBAapproved		char(1)
	,@save_DBAapprover		sysname
	,@change_flag			char(1)
	,@save_rq_stamp			sysname
	,@save_more_info		nvarchar(4000)
	,@save_more_info2		nvarchar(4000)
	,@db_query1			nvarchar(4000)
	,@db_query2			sysname
	,@pong_count			smallint
	,@returncode			int
	,@try_count			smallint


DECLARE
	 @error_count			int
	,@charpos			int
	,@detail_report			char(1)
	,@save_Status			sysname
	,@save_ProcessType		sysname
	,@save_ProcessDetail		sysname
	,@save_ModDate			datetime
	,@save_subject			sysname
	,@save_message			nvarchar(4000)
	,@save_central_domain		sysname
	,@update_file_path		nvarchar(2000)
	,@RDupdate_file_name		sysname
	,@save_timestamp		char(14)
	,@Hold_hhmmss			varchar(8)
	,@target_share			sysname
	,@save2_SQLname			sysname
	,@save2_DBname			sysname
	,@save2_APPLname		sysname
	,@save2_Process			sysname
	,@save2_ProcessDetail		sysname
	,@save2_Status			sysname
	,@save2_Domain			sysname
	,@save2_ModDate			datetime
	,@GEARSupdate_file_name		sysname
	,@save_reqdet_id		int
	,@save_targetpath		nvarchar(500)
	,@save_folder			sysname
	,@save_alt_folder		sysname
	,@save_latest_buildnum		sysname
	,@save_restore_status		sysname
	,@save_restore_reqdet_id	int



/*********************************************************************
 *                Initialization
 ********************************************************************/
Select @save_central_server = 'seapsqldba01'
Select @save_central_domain = 'amer'

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

Select @update_file_path = '\\' + @save_servername + '\' + @save_servername2 + '_dbasql\dba_reports'
Select @target_share = @save_central_server + '_DEPLcontrol'

Set @Hold_hhmmss = convert(varchar(8), getdate(), 8)
Set @save_timestamp = convert(char(8), getdate(), 112) + substring(@Hold_hhmmss, 1, 2) + substring(@Hold_hhmmss, 4, 2) + substring(@Hold_hhmmss, 7, 2) 


--  Create temp tables
create table #DirectoryTempTable(rowID int IDENTITY (1, 1) NOT NULL
				,cmdoutput nvarchar(255) null
				)

create table #DirectoryTempTable2(rowID int IDENTITY (1, 1) NOT NULL
				,cmdoutput nvarchar(255) null
				,alt_folder sysname null
				)

create table #fileexists ( 
	doesexist smallint,
	fileindir smallint,
	direxist smallint)

CREATE TABLE #insert_hl (gears_id int
			,SQLname sysname
			,Domain sysname
			)

CREATE TABLE #SQLname (gears_id int
			,SQLname sysname)

CREATE TABLE #applname (APPLname sysname
			,BASEfolder sysname)

CREATE TABLE #applname2 (APPLname sysname)

CREATE TABLE #dbname (DBname sysname)

CREATE TABLE #temp_reqdet (DBname sysname
			    ,status sysname
			    ,APPLname sysname
			    ,SQLname sysname
			    ,Domain sysname
			    ,Process sysname
			    ,ProcessDetail sysname
			    ,ModDate datetime)




----------------------  Print the headers  ----------------------

Print  ' '
Select @miscprint = 'SQL Automated Deployment Request Processing Controlled from Server: ' + @@servername
Print  @miscprint
Select @miscprint = '-- Process run: ' + convert(varchar(30),getdate())
Print  @miscprint
Print  ' '
raiserror('', -1,-1) with nowait


--  Check the rows with status "pending"
check_pending:
select @change_flag = 'n'
If exists (select 1 from dbo.Request where status = 'pending' 
					and DBAapproved = 'y'
					and (convert(nvarchar(10), startdate, 121) < convert(nvarchar(10), getdate(), 121)
					or (convert(nvarchar(10), startdate, 121) = convert(nvarchar(10), getdate(), 121) 
					and convert(nvarchar(5), starttime) < convert(nvarchar(5), getdate(), 108))
					)
					)
   begin
	Select @save_gears_id = (select top 1 gears_id from dbo.Request where status = 'pending' 
							and DBAapproved = 'y'
							and (convert(nvarchar(10), startdate, 121) < convert(nvarchar(10), getdate(), 121)
							or (convert(nvarchar(10), startdate, 121) = convert(nvarchar(10), getdate(), 121) 
							and convert(nvarchar(5), starttime) < convert(nvarchar(5), getdate(), 108))
							)
							)

	--  Make sure this request has SQL components before we get started
	If exists (select 1 from dbo.request_detail where gears_id = @save_gears_id)
	   begin
		--  At this point we are ready to mark this one "in-work" and get started
		Update dbo.Request set status = 'in-work' where gears_id = @save_gears_id

		If @@servername = @save_central_server
		   begin
			   begin
				EXECUTE gears.dbo.ChangeTicketStatus_sql @Action = 1, @BuildRequestID = @save_gears_id, @NewStatus = 'IN WORK' 
			   end
		   end

		Select @miscprint = 'Set Request ' + convert(nvarchar(20), @save_gears_id) + ' to status = ''in-work'''
		Print  @miscprint
		Print  ' '
		raiserror('', -1,-1) with nowait

		select @change_flag = 'y'


		--  If there are "next" build requests, update those at this time with the most recent build number available
		If exists (select 1 from dbo.request_detail where gears_id = @save_gears_id and process = 'Deploy' and ProcessDetail = 'next')
		   begin
			Select @save_ProjectName = (select top 1 ProjectName from dbo.request where gears_id = @save_gears_id)
			Select @save_ProjectNum = (select top 1 ProjectNum from dbo.request where gears_id = @save_gears_id)
			

			-- Verify path to central server
			Select @save_targetpath = '\\' + rtrim(@save_servername) + '\' + rtrim(@save_servername) + '_builds\VSTS_Source\' + rtrim(@save_ProjectName) + '_' + rtrim(@save_ProjectNum)
			Print @save_targetpath

			delete from #fileexists
			Insert into #fileexists exec master.sys.xp_fileexist @save_targetpath
			--select * from #fileexists

			If not exists (select 1 from #fileexists where fileindir = 1)
			   begin
				Select @miscprint = 'DBA Warning: Path to the build code on the central server could not be found. ' + @save_targetpath
				Print @miscprint 
				GOTO skip_next_override
			   end


			--  Find the most recent build code for this project name and release number
			select @cmd = 'dir ' + @save_targetpath + ' /B'
			--print @cmd

			delete from #DirectoryTempTable
			insert into #DirectoryTempTable exec master.sys.xp_cmdshell @cmd
			delete from #DirectoryTempTable where cmdoutput is null
			delete from #DirectoryTempTable where cmdoutput not like '%' + @save_ProjectName + '_%'
			delete from #DirectoryTempTable where cmdoutput not like '%_' + @save_ProjectNum + '_%'
			--select * from #DirectoryTempTable order by rowid desc

			If (select count(*) from #DirectoryTempTable) = 0
			   begin
				Select @miscprint = 'DBA Warning: No Build Code files found at Path ' + @save_targetpath
				Print @miscprint 
				GOTO skip_next_override
			   end

			--  Load #DirectoryTempTable2 by looping through #DirectoryTempTable
			delete from #DirectoryTempTable2
			start_dir_Loop01:

			Select @save_folder = (select top 1 cmdoutput from #DirectoryTempTable order by rowID desc)

			If @save_folder like '%.1'
			   or @save_folder like '%.2'
			   or @save_folder like '%.3'
			   or @save_folder like '%.4'
			   or @save_folder like '%.5'
			   or @save_folder like '%.6'
			   or @save_folder like '%.7'
			   or @save_folder like '%.8'
			   or @save_folder like '%.9'
			   begin
				Select @save_alt_folder = reverse(@save_folder)
				Select @save_alt_folder = left(@save_alt_folder, 1) + '0' + right(@save_alt_folder, len(@save_alt_folder)-1)
				Select @save_alt_folder = reverse(@save_alt_folder)
			   end
			Else
			   begin
				Select @save_alt_folder = @save_folder
			   end


			insert into #DirectoryTempTable2 values (@save_folder, @save_alt_folder)
	
			delete from #DirectoryTempTable where cmdoutput = @save_folder
			If (select count(*) from #DirectoryTempTable) > 0
			   begin
				goto start_dir_Loop01
			   end


			If (select count(*) from #DirectoryTempTable2) = 0
			   begin
				Select @miscprint = 'DBA Warning: No Build Code files found (2nd try) at Path ' + @save_targetpath
				Print @miscprint 
				GOTO skip_next_override
			   end


			Select @save_latest_buildnum  = (select top 1 cmdoutput from #DirectoryTempTable2 order by alt_folder desc)


			If @save_latest_buildnum like '%/_b%' escape '/'
			   begin
				Select @charpos = charindex('_b', @save_latest_buildnum )
				IF @charpos <> 0
				   begin
					Select @save_latest_buildnum  = substring(@save_latest_buildnum ,  @charpos+2, 200)
				   end
			   end

			update dbo.request_detail set ProcessDetail = @save_latest_buildnum where gears_id = @save_gears_id and ProcessDetail = 'next'
		   end

		skip_next_override:

	   end
	Else
	   begin
		--  Set the status for this request to "manual"
		Update dbo.Request set status = 'manual' where gears_id = @save_gears_id

		Select @miscprint = 'Set Gears Request ' + convert(nvarchar(20), @save_gears_id) + ' to status = ''manual'''
		Print  @miscprint
		Print  ' '
		raiserror('', -1,-1) with nowait

		select @change_flag = 'y'
	   end
   end



--  Loop back to see if there are more "pending" requests ready to start
If @change_flag = 'y'
   begin
	goto check_pending
   end


--  If there are no "in-work" items at this point, end this process
If not exists (select 1 from dbo.Request where status = 'in-work')
   begin
	Select @miscprint = 'No items to process at this time.'
	Print  @miscprint
	Print  ' '
	raiserror('', -1,-1) with nowait
	goto label99
   end


/****************************************************************
 *                MainLine
 ***************************************************************/

--  Start new requests not previously started

--  First, make sure new requests get inserted into the control_HL table
Insert into #insert_hl (Gears_id, SQLname, domain) 
select rd.gears_id, rd.SQLname , rd.domain
from dbo.request_detail rd, dbo.request r
where rd.gears_id = r.gears_id
and r.status = 'in-work'
and rd.status in ('pending', 'queued')
and rd.Process = 'start'
and rd.domain = @domain
group by rd.gears_id, rd.SQLname, rd.domain
--select * from #insert_hl


-- Loop through #insert_hl 
If (select count(*) from #insert_hl) > 0
   begin
	hl_insert_start_01:

	Select @save_gears_id = (select top 1 gears_id from #insert_hl order by gears_id)
	Select @save_SQLname = (select top 1 SQLname from #insert_hl where gears_id = @save_gears_id order by SQLname)
	Select @save_SQLport = (select top 1 port from dbacentral.dbo.dba_serverinfo where sqlname = @save_SQLname)
	Select @save_domain = (select top 1 domain from #insert_hl where gears_id = @save_gears_id and SQLname = @save_SQLname order by domain)

	If exists (select 1 from dbo.control_HL where gears_id = @save_gears_id and SQLname = @save_SQLname and End_Status is null)
	   begin
		Select @miscprint = 'Skip control_HL insert for Gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.  This row is already in the control_HL table.'
		Print  @miscprint
		raiserror('', -1,-1) with nowait
	   end

	If exists (select 1 from dbo.control_HL where SQLname = @save_SQLname and (End_Status is null or End_Status = 'pre-completed'))
	   begin
		Update dbo.Request_detail set status = 'queued' where gears_id = @save_gears_id and SQLname = @save_SQLname and Process = 'start'

		Select @save_alt_gears_id = (select top 1 gears_id from dbo.control_HL where SQLname = @save_SQLname and End_Status is null)
		Select @miscprint = 'Request_detail set to ''queued'' for Gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.  There is another active deployment for this SQL instance (Gears_id = ' + convert(nvarchar(20), @save_alt_gears_id) + ').'
		Print  @miscprint
		raiserror('', -1,-1) with nowait

		goto hl_insert_skip_01
	   end

	-- At this point, we should be good to go for this SQLname.  Make sure the start row is set back to 'pending'.
	If exists (select 1 from dbo.request_detail where gears_id = @save_gears_id and SQLname = @save_SQLname and Process = 'start' and status = 'queued')
	   begin
		Update dbo.Request_detail set status = 'pending' where gears_id = @save_gears_id and SQLname = @save_SQLname and Process = 'start'
	   end

	Insert into dbo.control_HL (Gears_id, SQLname, domain) values (@save_gears_id, @save_SQLname, @save_domain)


	hl_insert_skip_01:

	delete from #insert_hl where gears_id = @save_gears_id and SQLname = @save_SQLname and domain = @save_domain
	If (select count(*) from #insert_hl) > 0
	   begin
		goto hl_insert_start_01
	   end

   end




-------------------------------------------------------------------------------------------------------------------
--  Hand-shake process  -------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------


-- when handshake status is in-work for more than 1 minute
If exists (select 1 from dbo.control_HL where HandShake_Status in ('in-work', 'notify-DBA') and (HandShake_start is null or DATEDIFF(ss, HandShake_start, getdate()) > 60))
   begin
	delete from #sqlname
	Insert into #sqlname select gears_id, SQLname from dbo.control_HL where HandShake_Status in ('in-work', 'notify-DBA') and (HandShake_start is null or DATEDIFF(ss, HandShake_start, getdate()) > 60)
	--select * from #sqlname

	-- Loop through #sqlname 
	If (select count(*) from #sqlname) > 0
	   begin
		handshake_start_01:

		Select @save_gears_id = (select top 1 gears_id from #sqlname order by gears_id)
		Select @save_SQLname = (select top 1 SQLname from #sqlname where gears_id = @save_gears_id order by SQLname)
		Select @save_SQLport = (select top 1 port from dbacentral.dbo.dba_serverinfo where sqlname = @save_SQLname)


		--  one last check to make sure we dont have anything active on this sql instance
		If exists(select 1 from dbo.Request r, dbo.request_detail rd
			    where r.gears_id = rd.gears_id
			    and r.gears_id <> @save_gears_id
			    and r.status = 'in_work'
			    and rd.status in ('pending', 'in-work')
			    and rd.SQLname = @save_SQLname)
		   begin
			--  We should never be here.  This is bad!
			Select @save_subject = 'ERROR: DEPL_RD Central Control Process Error from ' + @@servername
			Select @save_message = 'DEPL_RD Central Control Process had more than one "active" deployments for the same SQL instance (' + @save_SQLname + ').  Gears number ' + convert(nvarchar(10), @save_gears_id) + '.'

			EXEC dbaadmin.dbo.dbasp_sendmail 
				--@recipients = 'jim.wilson@gettyimages.com',  
				@recipients = 'tssqldba@gettyimages.com',  
				@subject = @save_subject,
				@message = @save_message

			--EXEC dbaadmin.dbo.dbasp_sendmail @recipients = 'jdtorpedo58@gmail.com', @subject = @save_subject, @message = @save_message


			Select @miscprint = 'Handshake status is null for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.  Email sent to TSSQLDBA'
			Print  @miscprint
			raiserror('', -1,-1) with nowait

			goto skip_handshake_01
		   end

		--  run hand-shake process for this SQLname
		--  This will check to make sure sql and sql agent are running and that the standard DEPL RD job stream is in place
		Select @miscprint = 'Handshake status re-start for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.'
		Print  @miscprint
		raiserror('', -1,-1) with nowait

		update dbo.control_HL set HandShake_start = getdate()
			where gears_id = @save_gears_id and SQLname = @save_SQLname 

		select @query = 'exec DEPLinfo.dbo.dpsp_central_handshake @CentralSQLname = ''' + @@servername + ''', @gears_id = ' + convert(nvarchar(10), @save_gears_id)
		Print @query
		raiserror('', -1,-1) with nowait
		Select @cmd = 'sqlcmd -S' + @save_SQLname + ',' + @save_SQLport + ' -dmaster -E -Q"' + @query + '"'
		print @cmd
		raiserror('', -1,-1) with nowait

		Select @try_count = 0
		try_handshake_01:
		EXEC @returncode = master.sys.xp_cmdshell @cmd--, no_output

--		If @returncode <> 0
--		   begin
--			Waitfor delay '00:00:05'
--			If @try_count < 5
--			   begin
--				Select @try_count = @try_count + 1
--				print '@Try = ' + convert(nvarchar(10), @try_count)
--				raiserror('', -1,-1) with nowait
--				goto try_handshake_01
--			   end
--		   end

		skip_handshake_01:

		Delete from #sqlname where SQLname = @save_SQLname and gears_id = @save_gears_id 
		If (select count(*) from #sqlname) > 0
		   begin
			goto handshake_start_01
		   end
	   end
   end


-- when handshake status is in-work for more than 5 minutes
If exists (select 1 from dbo.control_HL where HandShake_Status in ('in-work', 'notify-DBA') and (HandShake_start is null or DATEDIFF(ss, HandShake_start, getdate()) > 300))
   begin
	delete from #sqlname
	Insert into #sqlname select gears_id, SQLname from dbo.control_HL where HandShake_Status in ('in-work', 'notify-DBA') and (HandShake_start is null or DATEDIFF(ss, HandShake_start, getdate()) > 300)
	--select * from #sqlname

	-- Loop through #sqlname 
	If (select count(*) from #sqlname) > 0
	   begin
		handshake_start_02:

		Select @save_gears_id = (select top 1 gears_id from #sqlname order by gears_id)
		Select @save_SQLname = (select top 1 SQLname from #sqlname where gears_id = @save_gears_id order by SQLname)
		Select @save_SQLport = (select top 1 port from dbacentral.dbo.dba_serverinfo where sqlname = @save_SQLname)

		update dbo.control_HL set HandShake_Status = 'notify-DBA'
			where gears_id = @save_gears_id and SQLname = @save_SQLname 

		Select @save_subject = 'ERROR: DBA DEPLcontrol from ' + @@servername
		Select @save_message = 'DEPL handshake error for server ' + @save_SQLname + ' and gears_id ' + convert(nvarchar(10), @save_gears_id) + '.  No reply from the target server.' + char(13)+char(10)
		Select @save_message = @save_message  + ' ' + char(13)+char(10)
		Select @save_message = @save_message  + 'Please resolve the issue at the target server (' + @save_SQLname  + ') and run the following code from that server.' + char(13)+char(10)
		Select @save_message = @save_message  + ' ' + char(13)+char(10)
		Select @save_message = @save_message  + 'Use DEPLinfo' + char(13)+char(10)
		Select @save_message = @save_message  + 'go' + char(13)+char(10)
		Select @save_message = @save_message  + ' ' + char(13)+char(10)
		Select @save_message = @save_message  + 'exec dbo.dpsp_central_handshake @CentralSQLname = ''' + @@servername + ''', @gears_id = ' + convert(nvarchar(10), @save_gears_id) + '' + char(13)+char(10)
		Select @save_message = @save_message  + 'go' + char(13)+char(10)
		EXEC dbaadmin.dbo.dbasp_sendmail 
			--@recipients = 'jim.wilson@gettyimages.com',  
			@recipients = 'tssqldba@gettyimages.com',  
			@subject = @save_subject,
			@message = @save_message

		--EXEC dbaadmin.dbo.dbasp_sendmail @recipients = 'jdtorpedo58@gmail.com', @subject = @save_subject, @message = @save_message


		Select @miscprint = 'Handshake status is in-work process for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.  Email sent to TSSQLDBA'
		Print  @miscprint
		raiserror('', -1,-1) with nowait


		Delete from #sqlname where SQLname = @save_SQLname
		If (select count(*) from #sqlname) > 0
		   begin
			goto handshake_start_02
		   end
	   end
   end

-- when handshake status is null 
If exists (select 1 from dbo.control_HL where HandShake_Status is null)
   begin
	delete from #sqlname
	Insert into #sqlname select gears_id, SQLname from dbo.control_HL where HandShake_Status is null
	--select * from #sqlname

	-- Loop through #sqlname 
	If (select count(*) from #sqlname) > 0
	   begin
		handshake_start_03:

		Select @save_gears_id = (select top 1 gears_id from #sqlname order by gears_id)
		Select @save_SQLname = (select top 1 SQLname from #sqlname where gears_id = @save_gears_id order by SQLname)
		Select @save_SQLport = (select top 1 port from dbacentral.dbo.dba_serverinfo where sqlname = @save_SQLname)


		--  SQLdeploy activity check
		Select @save_rq_stamp = convert(sysname, getdate(), 121) + convert(nvarchar(40), newid())
		Select @db_query1 = 'select count(*) from sqldeploy.dbo.request_local where status like ''''pending%'''' or status like ''''in-work%'''''
		Select @db_query2 = ''
		select @query = 'exec dbaadmin.dbo.dbasp_pong @rq_servername = ''' + @@servername 
			    + ''', @rq_stamp = ''' + @save_rq_stamp 
			    + ''', @rq_type = ''db_query'', @rq_detail01 = ''' + @db_query1 + ''', @rq_detail02 = ''' + @db_query2 + ''''
		Select @miscprint = 'Requesting info from server ' + @save_SQLname + '.'
		Print @miscprint
		Select @cmd = 'sqlcmd -S' + @save_SQLname + ',' + @save_SQLport + ' -E -Q"' + @query + '"'
		print @cmd
		raiserror('', -1,-1) with nowait
		EXEC master.sys.xp_cmdshell @cmd, no_output 

		--  capture pong results
		select @pong_count = 0
		start_pong_result_hs:
		Waitfor delay '00:00:05'
		If exists (select 1 from dbaadmin.dbo.pong_return where pong_stamp = @save_rq_stamp)
		   begin
			Select @save_more_info = (select pong_detail01 from dbaadmin.dbo.pong_return where pong_stamp = @save_rq_stamp)
		   end
		Else If @pong_count < 5
		   begin
			Select @pong_count = @pong_count + 1
			goto start_pong_result_hs
		   end
   
		If @save_more_info <> '0'
		   begin	
			Select @miscprint = 'Activity found in the local SQLdeploy DB on server ' + @save_SQLname + '.  Skipping this process for now.'
			Print @miscprint
			goto skip_handshake_03
		   end




		--  one last check to make sure we dont have anything active on this sql instance
		If exists(select 1 from dbo.Request r, dbo.request_detail rd
			    where r.gears_id = rd.gears_id
			    and r.gears_id <> @save_gears_id
			    and r.status = 'in_work'
			    and rd.status in ('pending', 'in-work')
			    and rd.SQLname = @save_SQLname)
		   begin
			--  We should never be here.  This is bad!
			Select @save_subject = 'ERROR: DEPL_RD Central Control Process Error from ' + @@servername
			Select @save_message = 'DEPL_RD Central Control Process had more than one "active" deployments for the same SQL instance (' + @save_SQLname + ').  Gears number ' + convert(nvarchar(10), @save_gears_id) + '.'

			EXEC dbaadmin.dbo.dbasp_sendmail 
				--@recipients = 'jim.wilson@gettyimages.com',  
				@recipients = 'tssqldba@gettyimages.com',  
				@subject = @save_subject,
				@message = @save_message

			--EXEC dbaadmin.dbo.dbasp_sendmail @recipients = 'jdtorpedo58@gmail.com', @subject = @save_subject, @message = @save_message


			Select @miscprint = 'Handshake status is null for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.  Email sent to TSSQLDBA'
			Print  @miscprint
			raiserror('', -1,-1) with nowait

			goto skip_handshake_03
		   end


		--  run hand-shake process for this SQLname
		--  This will check to make sure sql and sql agent are running and that the standard DEPL RD job stream is in place
		Select @miscprint = 'Handshake status start for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.'
		Print  @miscprint
		raiserror('', -1,-1) with nowait

		update dbo.control_HL set HandShake_Status = 'in-work', HandShake_start = getdate()
			where gears_id = @save_gears_id and SQLname = @save_SQLname 

		select @query = 'exec DEPLinfo.dbo.dpsp_central_handshake @CentralSQLname = ''' + @@servername + ''', @gears_id = ' + convert(nvarchar(10), @save_gears_id)
		Print @query
		raiserror('', -1,-1) with nowait
		Select @cmd = 'sqlcmd -S' + @save_SQLname + ',' + @save_SQLport + ' -dmaster -E -Q"' + @query + '"'
		print @cmd
		raiserror('', -1,-1) with nowait

		Select @try_count = 0
		try_handshake_03:
		EXEC @returncode = master.sys.xp_cmdshell @cmd--, no_output

--		If @returncode <> 0
--		   begin
--			Waitfor delay '00:00:05'
--			If @try_count < 5
--			   begin
--				Select @try_count = @try_count + 1
--				print '@Try = ' + convert(nvarchar(10), @try_count)
--				raiserror('', -1,-1) with nowait
--				goto try_handshake_03
--			   end
--		   end

		skip_handshake_03:

		Delete from #sqlname where SQLname = @save_SQLname and gears_id = @save_gears_id 
		If (select count(*) from #sqlname) > 0
		   begin
			goto handshake_start_03
		   end
	   end
   end




-------------------------------------------------------------------------------------------------------------------
--  Set-up process  -----------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------

-- when setup status is "in-work" 
If exists (select 1 from dbo.control_HL where HandShake_Status = 'completed' and Setup_Status = 'in-work')
   begin
	delete from #sqlname
	Insert into #sqlname select gears_id, SQLname from dbo.control_HL where HandShake_Status = 'completed' and Setup_Status = 'in-work'
	--select * from #sqlname

	-- Loop through #sqlname 
	If (select count(*) from #sqlname) > 0
	   begin
		setup_start_01:

		Select @save_gears_id = (select top 1 gears_id from #sqlname order by gears_id)
		Select @save_SQLname = (select top 1 SQLname from #sqlname where gears_id = @save_gears_id order by SQLname)
		Select @save_SQLport = (select top 1 port from dbacentral.dbo.dba_serverinfo where sqlname = @save_SQLname)

		Select @miscprint = 'Setup status in-work process for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.'
		Print  @miscprint
		raiserror('', -1,-1) with nowait

		If exists (select 1 from dbo.request_detail where Process = 'start' and gears_id = @save_gears_id and SQLname = @save_SQLname and status like 'completed%')
		   begin
			Select @save_status = (select top 1 status from dbo.request_detail where Process = 'start' and gears_id = @save_gears_id and SQLname = @save_SQLname)

			update dbo.control_HL set Setup_Status = @save_status, Setup_complete = getdate()
				where gears_id = @save_gears_id and SQLname = @save_SQLname 

			Select @miscprint = 'Setup status marked completed for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.'
			Print  @miscprint
			raiserror('', -1,-1) with nowait
		   end

		Delete from #sqlname where gears_id = @save_gears_id and SQLname = @save_SQLname
		If (select count(*) from #sqlname) > 0
		   begin
			goto setup_start_01
		   end
	   end
   end


-- when setup status has been "in-work" for awhile (5 minutes = 300 seconds) 
If exists (select 1 from dbo.control_HL where HandShake_Status = 'completed' and Setup_Status = 'in-work' and datediff(ss, Setup_Start, getdate()) > 300)
   begin
	delete from #sqlname
	Insert into #sqlname select gears_id, SQLname from dbo.control_HL where HandShake_Status = 'completed' and Setup_Status = 'in-work' and datediff(ss, Setup_Start, getdate()) > 300
	--select * from #sqlname

	-- Loop through #sqlname 
	If (select count(*) from #sqlname) > 0
	   begin
		setup_start_02:

		Select @save_gears_id = (select top 1 gears_id from #sqlname order by gears_id)
		Select @save_SQLname = (select top 1 SQLname from #sqlname where gears_id = @save_gears_id order by SQLname)
		Select @save_SQLport = (select top 1 port from dbacentral.dbo.dba_serverinfo where sqlname = @save_SQLname)

		If exists (select 1 from dbo.job_pong_log where gears_id = @save_gears_id and SQLname = @save_SQLname and Process = 'start' and status = 'running' and datediff(ss, ModDate, getdate()) < 300)
		   begin
			--  wait for 5 minutes before we pong again
			goto skip_start_pong
		   end

		--  Ping this server using the auto_pong process to determine the status of the DEPL_RD start job
		Select @miscprint = 'Setup status in-work for extended time for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.  Sending ping to check on job.'
		Print  @miscprint
		raiserror('', -1,-1) with nowait

		Select @save_rq_stamp = convert(sysname, getdate(), 121) + convert(nvarchar(40), newid())
		Select @db_query1 = 'DEPL_RD - 00 - Deployment Start'
		Select @db_query2 = ''
		select @query = 'exec DEPLinfo.dbo.dpsp_auto_pong_to_control @rq_servername = ''' + @@servername 
			    + ''', @rq_stamp = ''' + @save_rq_stamp 
			    + ''', @rq_type = ''job'', @rq_detail01 = ''' + @db_query1 + ''', @rq_detail02 = ''' + @db_query2 + ''''
		Select @miscprint = 'Requesting start job info from server ' + @save_SQLname + '.'
		Print @miscprint
		raiserror('', -1,-1) with nowait
		Select @cmd = 'sqlcmd -S' + @save_SQLname + ',' + @save_SQLport + ' -E -Q"' + @query + '"'
		print @cmd
		raiserror('', -1,-1) with nowait

		Select @try_count = 0
		try_start_pong_01:
		EXEC @returncode = master.sys.xp_cmdshell @cmd--, no_output

--		If @returncode <> 0
--		   begin
--			Waitfor delay '00:00:05'
--			If @try_count < 5
--			   begin
--				Select @try_count = @try_count + 1
--				print '@Try = ' + convert(nvarchar(10), @try_count)
--				raiserror('', -1,-1) with nowait
--				goto try_start_pong_01
--			   end
--			Else
--			   begin
--				print '@Try count maxed out.  Skip this process'
--				raiserror('', -1,-1) with nowait
--				goto skip_start_pong
--			   end
--		   end

		If @returncode <> 0
		   begin
			print 'Skip this process'
			raiserror('', -1,-1) with nowait
			goto skip_start_pong
		   end



		--  capture pong results
		select @pong_count = 0
		start_pong_result:
		Waitfor delay '00:00:05'
		If exists (select 1 from DEPLcontrol.dbo.pong_return where pong_stamp = @save_rq_stamp)
		   begin
			Select @save_more_info = (select pong_detail01 from dbo.pong_return where pong_stamp = @save_rq_stamp)

			If @save_more_info like '%running%'
			   begin
				insert into dbo.job_pong_log values (@save_gears_id, @save_SQLname, 'start', 'running', getdate())

				Select @miscprint = 'Setup status in-work - post job ping for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.  SQL job is still running.'
				Print  @miscprint
				raiserror('', -1,-1) with nowait
			   end
			Else If @save_more_info like '%JOB Failed%'
			   begin
				Select @save_subject = 'ERROR: DEPL_RD Central Job Check Error for SQL instance ' + @save_SQLname
				Select @save_message = 'DEPL_RD Central Job Check Error detected for server ' + @save_SQLname + '.  The start job has failed.'


				--  If this job has been reported in the past 1 hours, skip this section
				If exists (select 1 from dbaadmin.dbo.No_Check where NoCheck_type = 'DEPL_RD_job' and detail01 = @save_SQLname and datediff(hh, createdate, getdate()) < 1) 
				   begin
					Print 'Skip sendmail for failed job on server ' + @save_SQLname
				   end
				Else
				   begin
					Delete from dbaadmin.dbo.No_Check where NoCheck_type = 'DEPL_RD_job' and detail01 = @save_SQLname
					insert into dbaadmin.dbo.No_Check values ('DEPL_RD_job', @save_SQLname, '', '', '', 'depl_control', getdate(), getdate())

					EXEC dbaadmin.dbo.dbasp_sendmail 
						--@recipients = 'jim.wilson@gettyimages.com',  
						@recipients = 'tssqldba@gettyimages.com',  
						@subject = @save_subject,
						@message = @save_message
				   end


				insert into job_pong_log values (@save_gears_id, @save_SQLname, 'start', 'failed', getdate())

				Select @miscprint = 'Setup status in-work - post job ping for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.  SQL job Failed.  Email sent.'
				Print  @miscprint
				raiserror('', -1,-1) with nowait
			   end
			Else If @save_more_info like '%Last Job Completed%' or @save_more_info like '%never run%'
			   begin
				--  One last check before we send the email
				Waitfor delay '00:00:05'
				If not exists (select 1 from dbo.request_detail where gears_id = @save_gears_id and SQLname = @save_SQLname and status like 'in-work%')
				   begin
					goto skip_start_pong
				   end

				--  for some reason the depl_rd job is not running and had not reported back.  Run the job diag process.
				Select @miscprint = 'Running the job diag process for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.  DEPL_RD job not running.'
				Print  @miscprint
				raiserror('', -1,-1) with nowait

				Select @save_ProjectName = (select top 1 ProjectName from dbo.request where gears_id = @save_gears_id)
				Select @save_ProjectNum = (select top 1 ProjectNum from dbo.request where gears_id = @save_gears_id)
				Select @save_ProcessDetail = (select top 1 ProcessDetail from dbo.request_detail where gears_id = @save_gears_id and SQLname = @save_SQLname and status like 'in-work%')

				select @query = 'exec DEPLinfo.dbo.dpsp_diag_jobs @Gears_id = ' + convert(nvarchar(10), @save_gears_id)
				select @query = @query + ', @ProjectName = ''' + @save_ProjectName + ''''
				select @query = @query + ', @ProjectNum = ''' + @save_ProjectNum + ''''
				select @query = @query + ', @central_server = ''' +  @@servername + ''''
				select @query = @query + ', @Process = ''start'''
				Print @query
				raiserror('', -1,-1) with nowait
				Select @cmd = 'sqlcmd -S' + @save_SQLname + ',' + @save_SQLport + ' -dmaster -E -Q"' + @query + '"'
				print @cmd
				raiserror('', -1,-1) with nowait

				EXEC @returncode = master.sys.xp_cmdshell @cmd--, no_output
			   end
		   end
		Else If @pong_count < 5
		   begin
			Select @pong_count = @pong_count + 1
			goto start_pong_result
		   end


		skip_start_pong:

		Delete from #sqlname where gears_id = @save_gears_id and SQLname = @save_SQLname
		If (select count(*) from #sqlname) > 0
		   begin
			goto setup_start_02
		   end
	   end
   end



-- when setup status is null 
If exists (select 1 from dbo.control_HL where HandShake_Status = 'completed' and Setup_Status is null)
   begin
	delete from #sqlname
	Insert into #sqlname select gears_id, SQLname from dbo.control_HL where HandShake_Status = 'completed' and Setup_Status is null
	--select * from #sqlname

	-- Loop through #sqlname 
	If (select count(*) from #sqlname) > 0
	   begin
		setup_start_03:

		Select @save_gears_id = (select top 1 gears_id from #sqlname order by gears_id)
		Select @save_SQLname = (select top 1 SQLname from #sqlname where gears_id = @save_gears_id order by SQLname)
		Select @save_SQLport = (select top 1 port from dbacentral.dbo.dba_serverinfo where sqlname = @save_SQLname)
		Select @save_ProjectName = (select top 1 ProjectName from dbo.request where gears_id = @save_gears_id)
		Select @save_ProjectNum = (select top 1 ProjectNum from dbo.request where gears_id = @save_gears_id)


		--  one last check to make sure we dont have anything active on this sql instance
		If exists(select 1 from dbo.Request r, dbo.request_detail rd
			    where r.gears_id = rd.gears_id
			    and r.gears_id <> @save_gears_id
			    and r.status = 'in_work'
			    and rd.status in ('pending', 'in-work')
			    and rd.SQLname = @save_SQLname)
		   begin
			--  We should never be here.  This is bad!
			Select @save_subject = 'ERROR: DEPL_RD Central Control Process Error from ' + @@servername
			Select @save_message = 'DEPL_RD Central Control Process had more than one "active" deployments for the same SQL instance (' + @save_SQLname + ').  Gears number ' + convert(nvarchar(10), @save_gears_id) + '.'

			EXEC dbaadmin.dbo.dbasp_sendmail 
				--@recipients = 'jim.wilson@gettyimages.com',  
				@recipients = 'tssqldba@gettyimages.com',  
				@subject = @save_subject,
				@message = @save_message

			--EXEC dbaadmin.dbo.dbasp_sendmail @recipients = 'jdtorpedo58@gmail.com', @subject = @save_subject, @message = @save_message


			Select @miscprint = 'Note: Gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.  Email sent to TSSQLDBA'
			Print  @miscprint
			raiserror('', -1,-1) with nowait

			goto skip_setup_03
		   end


		--  run setup process for this SQLname
		--  insert the initial setup row into the control_local table on the target server
		Select @miscprint = 'Setup status start process for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.'
		Print  @miscprint
		raiserror('', -1,-1) with nowait

		select @query = 'If not exists (select 1 from DEPLinfo.dbo.control_local where Gears_id = ' + convert(nvarchar(10), @save_gears_id) + ' and Process = ''start'') begin '
		select @query = @query + 'insert into DEPLinfo.dbo.control_local (Gears_id, ProjectName, ProjectNum, central_server, status, Process, CreateDate)'
		select @query = @query + ' values (' + convert(nvarchar(10), @save_gears_id) + ', ''' + @save_ProjectName + ''''
		select @query = @query + ', ''' + @save_ProjectNum + ''', ''' +  @@servername + ''', ''pending'', ''start'', getdate()) end'
		Print @query
		raiserror('', -1,-1) with nowait
		Select @cmd = 'sqlcmd -S' + @save_SQLname + ',' + @save_SQLport + ' -dmaster -E -Q"' + @query + '"'
		print @cmd
		raiserror('', -1,-1) with nowait

		Select @try_count = 0
		try_setup_03a:
		EXEC @returncode = master.sys.xp_cmdshell @cmd--, no_output

--		If @returncode <> 0
--		   begin
--			Waitfor delay '00:00:05'
--			If @try_count < 5
--			   begin
--				Select @try_count = @try_count + 1
--				print '@Try = ' + convert(nvarchar(10), @try_count)
--				raiserror('', -1,-1) with nowait
--				goto try_setup_03a
--			   end
--			Else
--			   begin
--				print '@Try count maxed out.  Skip this process'
--				raiserror('', -1,-1) with nowait
--				goto skip_setup_03
--			   end
--		   end

		If @returncode <> 0
		   begin
			print 'Skip this process'
			raiserror('', -1,-1) with nowait
			goto skip_setup_03
		   end


		--  Create the local job restore rows (matching the DB restore components in the ticket)
		if exists (select 1 from dbo.request_detail where gears_id = @save_gears_id and SQLname = @save_SQLname and process = 'start' and ProcessType = 'JobRestore-y')
		   begin
			delete from #applname
			Insert into #applname select APPLname, BASEfolder from dbo.request_detail where gears_id = @save_gears_id and SQLname = @save_SQLname and process = 'restore'
			--select * from #applname

			-- Loop through #applname 
			If (select count(*) from #applname) > 0
			   begin
				setup_applname_03:

				Select @save_APPLname = (select top 1 APPLname from #applname order by APPLname)
				Select @save_BASEfolder = (select top 1 BASEfolder from #applname where APPLname = @save_APPLname)

				--  insert JobRestore row(s) into the control_local table on the target server
				select @query = 'If not exists (select 1 from DEPLinfo.dbo.control_local where Gears_id = ' + convert(nvarchar(10), @save_gears_id) + ' and Process = ''JobRestore'') begin '
				select @query = @query + 'insert into DEPLinfo.dbo.control_local (Gears_id, ProjectName, ProjectNum, central_server, status, Process, APPLname, BASEfolder, CreateDate)'
				select @query = @query + ' values (' + convert(nvarchar(10), @save_gears_id) + ', ''' + @save_ProjectName + ''''
				select @query = @query + ', ''' + @save_ProjectNum + ''', ''' +  @@servername + ''', ''pending'', ''JobRestore'''
				select @query = @query + ', ''' + @save_APPLname + ''', ''' +  @save_BASEfolder + ''', getdate()) end'
				Print @query
				raiserror('', -1,-1) with nowait
				Select @cmd = 'sqlcmd -S' + @save_SQLname + ',' + @save_SQLport + ' -dmaster -E -Q"' + @query + '"'
				print @cmd
				raiserror('', -1,-1) with nowait

				Select @try_count = 0
				try_setup_03b:
				EXEC @returncode = master.sys.xp_cmdshell @cmd--, no_output

--				If @returncode <> 0
--				   begin
--					Waitfor delay '00:00:05'
--					If @try_count < 5
--					   begin
--						Select @try_count = @try_count + 1
--						print '@Try = ' + convert(nvarchar(10), @try_count)
--						raiserror('', -1,-1) with nowait
--						goto try_setup_03b
--					   end
--					Else
--					   begin
--						print '@Try count maxed out.  Skip this process'
--						raiserror('', -1,-1) with nowait
--						goto skip_setup_03
--					   end
--				   end

				If @returncode <> 0
				   begin
					print 'Skip this process'
					raiserror('', -1,-1) with nowait
					goto skip_setup_03
				   end


				Delete from #applname where APPLname = @save_APPLname
				If (select count(*) from #applname) > 0
				   begin
					goto setup_applname_03
				   end
			   end
		   end


		--  Create the local production pre-deployment backup rows (matching the DB deployment components in the ticket)
		If (Select top 1 Environment from dbo.Request where gears_id = @save_gears_id order by req_id) = 'production'
		   and exists (select 1 from dbo.request_detail where gears_id = @save_gears_id and SQLname = @save_SQLname and process = 'deploy')
		   begin
			delete from #dbname
			Insert into #dbname select DBname from dbo.request_detail where gears_id = @save_gears_id and SQLname = @save_SQLname and process = 'deploy'
			--select * from #dbname

			-- Loop through #dbname 
			If (select count(*) from #dbname) > 0
			   begin
				setup_backup_03:

				Select @save_DBname = (select top 1 DBname from #dbname order by DBname)

				--  insert JobRestore row(s) into the control_local table on the target server
				select @query = 'If not exists (select 1 from DEPLinfo.dbo.control_local where Gears_id = ' + convert(nvarchar(10), @save_gears_id) + ' and Process = ''PreBackup'') begin '
				select @query = @query + 'insert into DEPLinfo.dbo.control_local (Gears_id, ProjectName, ProjectNum, central_server, status, Process, DBname, CreateDate)'
				select @query = @query + ' values (' + convert(nvarchar(10), @save_gears_id) + ', ''' + @save_ProjectName + ''''
				select @query = @query + ', ''' + @save_ProjectNum + ''', ''' +  @@servername + ''', ''pending'', ''PreBackup'''
				select @query = @query + ', ''' + @save_DBname + ''', getdate()) end'
				Print @query
				raiserror('', -1,-1) with nowait
				Select @cmd = 'sqlcmd -S' + @save_SQLname + ',' + @save_SQLport + ' -dmaster -E -Q"' + @query + '"'
				print @cmd
				raiserror('', -1,-1) with nowait

				Select @try_count = 0
				try_setup_03c:
				EXEC @returncode = master.sys.xp_cmdshell @cmd--, no_output

--				If @returncode <> 0
--				   begin
--					Waitfor delay '00:00:05'
--					If @try_count < 5
--					   begin
--						Select @try_count = @try_count + 1
--						print '@Try = ' + convert(nvarchar(10), @try_count)
--						raiserror('', -1,-1) with nowait
--						goto try_setup_03c
--					   end
--					Else
--					   begin
--						print '@Try count maxed out.  Skip this process'
--						raiserror('', -1,-1) with nowait
--						goto skip_setup_03
--					   end
--				   end

				If @returncode <> 0
				   begin
					print 'Skip this process'
					raiserror('', -1,-1) with nowait
					goto skip_setup_03
				   end

				Delete from #dbname where DBname = @save_DBname
				If (select count(*) from #dbname) > 0
				   begin
					goto setup_backup_03
				   end
			   end
		   end


		--  Set the row in the control_HL table to in-work
		update dbo.control_HL set Setup_Status = 'in-work', Setup_start = getdate()
			where gears_id = @save_gears_id and SQLname = @save_SQLname 

		Select @miscprint = 'Table dbo.control_HL setup_start set to in-work for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.'
		Print  @miscprint
		raiserror('', -1,-1) with nowait


		--  Set the start row in the request_detail table to in-work
		update dbo.request_detail set Status = 'in-work', ModDate = getdate()
			where gears_id = @save_gears_id and SQLname = @save_SQLname and Process = 'start' 

		Select @miscprint = 'Table dbo.request_detail status set to in-work for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.'
		Print  @miscprint
		raiserror('', -1,-1) with nowait


		--  Now, Start the DEPL_RD - 00 - Deployment Start job on the target server
		Select @miscprint = 'Starting SQL job "DEPL_RD - 00 - Deployment Start" for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.'
		Print  @miscprint
		raiserror('', -1,-1) with nowait

		select @query = 'exec msdb.dbo.sp_start_job @job_name = ''DEPL_RD - 00 - Deployment Start'''
		Print @query
		raiserror('', -1,-1) with nowait
		Select @cmd = 'sqlcmd -S' + @save_SQLname + ',' + @save_SQLport + ' -dmaster -E -Q"' + @query + '"'
		print @cmd
		raiserror('', -1,-1) with nowait

		Select @try_count = 0
		try_setup_03d:
		EXEC @returncode = master.sys.xp_cmdshell @cmd--, no_output

--		If @returncode <> 0
--		   begin
--			Waitfor delay '00:00:05'
--			If @try_count < 5
--			   begin
--				Select @try_count = @try_count + 1
--				print '@Try = ' + convert(nvarchar(10), @try_count)
--				raiserror('', -1,-1) with nowait
--				goto try_setup_03d
--			   end
--			Else
--			   begin
--				print '@Try count maxed out.  Skip this process'
--				raiserror('', -1,-1) with nowait
--				goto skip_setup_03
--			   end
--		   end

		If @returncode <> 0
		   begin
			print 'Skip this process'
			raiserror('', -1,-1) with nowait
			goto skip_setup_03
		   end


		skip_setup_03:

		Delete from #sqlname where SQLname = @save_SQLname
		If (select count(*) from #sqlname) > 0
		   begin
			goto setup_start_03
		   end
	   end
   end





-------------------------------------------------------------------------------------------------------------------
--  Restore process  ----------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------

-- when restore status is "in-work" 
If exists (select 1 from dbo.control_HL where HandShake_Status = 'completed' and Setup_Status like 'completed%' and restore_status = 'in-work')
   begin
	delete from #sqlname
	Insert into #sqlname select gears_id, SQLname from dbo.control_HL where HandShake_Status = 'completed' and Setup_Status like 'completed%' and restore_status = 'in-work'
	--select * from #sqlname

	-- Loop through #sqlname 
	If (select count(*) from #sqlname) > 0
	   begin
		restore_start_01:

		Select @save_gears_id = (select top 1 gears_id from #sqlname order by gears_id)
		Select @save_SQLname = (select top 1 SQLname from #sqlname where gears_id = @save_gears_id order by SQLname)
		Select @save_SQLport = (select top 1 port from dbacentral.dbo.dba_serverinfo where sqlname = @save_SQLname)
		
		Select @miscprint = 'Restore check in-work status for request_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.'
		Print  @miscprint
		raiserror('', -1,-1) with nowait
		

		--  If all restores are completed, update the control_HL table
		If not exists (select 1 from dbo.request_detail where Process = 'restore' and gears_id = @save_gears_id and SQLname = @save_SQLname and status not like 'completed%' and status not like '%cancelled%')
		   begin
			update dbo.control_HL set Restore_Status = 'completed', Restore_complete = getdate()
				where gears_id = @save_gears_id and SQLname = @save_SQLname 

			Select @miscprint = 'Restore status marked completed for request_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.'
			Print  @miscprint
			Print ''
			raiserror('', -1,-1) with nowait	

			goto restore_01_skip_a
		   end


		--  If there are no current restores in-work, and there is more to do, start the next one
		If exists (select 1 from dbo.request_detail where Process = 'restore' and gears_id = @save_gears_id and SQLname = @save_SQLname and status like 'in-work%')
		   begin
			Select @save_DBname = (select top 1 DBname from dbo.request_detail where Process = 'restore' and gears_id = @save_gears_id and SQLname = @save_SQLname and status like 'in-work%')
			Select @miscprint = 'Restore(s) still processing for request_id_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + ' and DBname ' + @save_DBname + '.'
			Print  @miscprint
			Print ''
			raiserror('', -1,-1) with nowait

			goto restore_01_skip_a
		   end


		--  If we are here, we know there were restores in this request, that they have not all completed, and none are currently running .  Get the next DBname to restore
		Select @save_DBname = (select top 1 rd.DBname 
						from dbo.request_detail rd, dbo.db_sequence s 
						where rd.DBname = s.DBname
						and rd.Process = 'restore' 
						and rd.gears_id = @save_gears_id 
						and rd.SQLname = @save_SQLname 
						and rd.status not like 'completed%' 
						and rd.status not like '%cancelled%' 
						order by s.seq_id) 
		Select @save_ProjectName = (select top 1 ProjectName from dbo.request where gears_id = @save_gears_id)
		Select @save_ProjectNum = (select top 1 ProjectNum from dbo.request where gears_id = @save_gears_id)
		Select @save_APPLname = (select APPLname from dbo.request_detail where gears_id = @save_gears_id and SQLname = @save_SQLname and process = 'restore' and DBname = @save_DBname)
		Select @save_BASEfolder = (select BASEfolder from dbo.request_detail where gears_id = @save_gears_id and SQLname = @save_SQLname and process = 'restore' and DBname = @save_DBname)

		--  insert the restore row into the control_local table on the target server
		Select @miscprint = 'Restores continue for gears_id ' + convert(nvarchar(20), @save_gears_id) + ', SQLname ' + @save_SQLname + ' and DB ' + @save_DBname + '.'
		Print  @miscprint
		raiserror('', -1,-1) with nowait

		select @query = 'If not exists (select 1 from DEPLinfo.dbo.control_local where Gears_id = ' + convert(nvarchar(10), @save_gears_id) + ' and Process = ''restore'' and DBname = ''' + @save_DBname + ''') begin '
		select @query = @query + 'insert into DEPLinfo.dbo.control_local (Gears_id, ProjectName, ProjectNum, central_server, status, Process, DBname, APPLname, BASEfolder, CreateDate)'
		select @query = @query + ' values (' + convert(nvarchar(10), @save_gears_id) + ', ''' + @save_ProjectName + ''''
		select @query = @query + ', ''' + @save_ProjectNum + ''', ''' +  @@servername + ''', ''pending'', ''restore'''
		select @query = @query + ', ''' + @save_DBname + ''', ''' + @save_APPLname + ''', ''' +  @save_BASEfolder + ''', getdate()) end'
		Print @query
		raiserror('', -1,-1) with nowait
		Select @cmd = 'sqlcmd -S' + @save_SQLname + ',' + @save_SQLport + ' -dmaster -E -Q"' + @query + '"'
		print @cmd
		raiserror('', -1,-1) with nowait

		Select @try_count = 0
		try_restore_01a:
		EXEC @returncode = master.sys.xp_cmdshell @cmd--, no_output

--		If @returncode <> 0
--		   begin
--			Waitfor delay '00:00:05'
--			If @try_count < 5
--			   begin
--				Select @try_count = @try_count + 1
--				print '@Try = ' + convert(nvarchar(10), @try_count)
--				raiserror('', -1,-1) with nowait
--				goto try_restore_01a
--			   end
--			Else
--			   begin
--				print '@Try count maxed out.  Skip this process'
--				raiserror('', -1,-1) with nowait
--				goto restore_01_skip_b
--			   end
--		   end

		If @returncode <> 0
		   begin
			print 'Skip this process'
			raiserror('', -1,-1) with nowait
			goto restore_01_skip_b
		   end


		--  Set the restore row for this DBname in the request_detail table to in-work
		update dbo.request_detail set Status = 'in-work', ModDate = getdate()
			where gears_id = @save_gears_id and Process = 'restore' and DBname = @save_DBname and SQLname = @save_SQLname

		Select @miscprint = 'Table dbo.request_detail status for restore of DB ' + @save_DBname + ' set to in-work for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.'
		Print  @miscprint
		raiserror('', -1,-1) with nowait
		
		


		--  Now, Start the DEPL_RD - 01 - Deployment Start job on the target server
		Select @miscprint = 'Starting SQL job "DEPL_RD - 01 - Restore" for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + ' and DB ' + @save_DBname + '.'
		Print  @miscprint
		raiserror('', -1,-1) with nowait

		select @query = 'exec msdb.dbo.sp_start_job @job_name = ''DEPL_RD - 01 - Restore'''
		Print @query
		raiserror('', -1,-1) with nowait
		Select @cmd = 'sqlcmd -S' + @save_SQLname + ',' + @save_SQLport + ' -dmaster -E -Q"' + @query + '"'
		print @cmd
		raiserror('', -1,-1) with nowait

		Select @try_count = 0
		try_restore_01b:
		EXEC @returncode = master.sys.xp_cmdshell @cmd--, no_output

--		If @returncode <> 0
--		   begin
--			Waitfor delay '00:00:05'
--			If @try_count < 5
--			   begin
--				Select @try_count = @try_count + 1
--				print '@Try = ' + convert(nvarchar(10), @try_count)
--				raiserror('', -1,-1) with nowait
--				goto try_restore_01b
--			   end
--			Else
--			   begin
--				print '@Try count maxed out.  Skip this process'
--				raiserror('', -1,-1) with nowait
--				goto restore_01_skip_b
--			   end
--		   end


		If @returncode <> 0
		   begin
			print 'Skip this process'
			raiserror('', -1,-1) with nowait
			goto restore_01_skip_b
		   end
		   
		   

		restore_01_skip_a:



		--  Update Gears for restores
		If @@servername = @save_central_server
		   begin
		   	Select @miscprint = 'Updating Gears restore request ' + convert(nvarchar(10), @save_gears_id) + ' for SQLname ' + @save_SQLname + '.'
			Print  @miscprint
			raiserror('', -1,-1) with nowait

			update brc set brc.status = rd.status, brc.build_deployed = rd.process, brc.date_deployed = getdate(), brc.server_name = @save_SQLname, brc.deployed_by = 24 
				from gears.dbo.BUILD_REQUEST_COMPONENTS brc, gears.dbo.COMPONENTS c, dbo.Request_detail rd
				where brc.build_request_id = @save_gears_id 
				and brc.next_build in ('', 'off')
				and brc.build_number = ''
				and brc.component_id = c.component_id
				and c.component_name = rd.DBname
				and rd.gears_id = brc.build_request_id
				and rd.process = 'restore'
				and rd.SQLname = @save_SQLname
				and (rd.status like '%completed%' or rd.status like '%cancelled%')

			update brc set brc.status = rd.status, brc.build_deployed = rd.process, brc.server_name = @save_SQLname, brc.deployed_by = null 
				from gears.dbo.BUILD_REQUEST_COMPONENTS brc, gears.dbo.COMPONENTS c, dbo.Request_detail rd
				where brc.build_request_id = @save_gears_id 
				and brc.component_id = c.component_id
				and c.component_name = rd.DBname
				and rd.gears_id = brc.build_request_id
				and rd.process = 'restore'
				and rd.SQLname = @save_SQLname
				and rd.status like '%in-work%'

			update brc set brc.status = 'in-work RD', brc.build_deployed = rd.process, brc.server_name = @save_SQLname, brc.deployed_by = null 
				from gears.dbo.BUILD_REQUEST_COMPONENTS brc, gears.dbo.COMPONENTS c, dbo.Request_detail rd
				where brc.build_request_id = @save_gears_id 
				and (brc.next_build = 'on' or brc.build_number <> '')
				and brc.component_id = c.component_id
				and c.component_name = rd.DBname
				and rd.gears_id = brc.build_request_id
				and rd.process = 'restore'
				and rd.SQLname = @save_SQLname
				and (rd.status like '%completed%' or rd.status like '%cancelled%')
		   end


		restore_01_skip_b:


		Delete from #sqlname where gears_id = @save_gears_id and SQLname = @save_SQLname
		If (select count(*) from #sqlname) > 0
		   begin
			goto restore_start_01
		   end
	   end
   end



-- when restore status has been "in-work" for awhile (5 minutes = 300 seconds) 
If exists (select 1 from dbo.control_HL h, dbo.Request_detail rd
			where h.gears_id = rd.gears_id
			and h.HandShake_Status = 'completed' 
			and h.Setup_Status like 'completed%' 
			and h.restore_status like 'in-work%'
			and rd.process = 'restore'
			and rd.status like 'in-work%' 
			and datediff(ss, rd.ModDate, getdate()) > 200)
   begin
	delete from #sqlname
	Insert into #sqlname select h.gears_id, h.SQLname from dbo.control_HL h, dbo.Request_detail rd
							where h.gears_id = rd.gears_id
							and h.HandShake_Status = 'completed' 
							and h.Setup_Status like 'completed%' 
							and h.restore_status like 'in-work%'
							and rd.process = 'restore'
							and rd.status like 'in-work%' 
							and datediff(ss, rd.ModDate, getdate()) > 200
	--select * from #sqlname

	-- Loop through #sqlname 
	If (select count(*) from #sqlname) > 0
	   begin
		restore_start_02:

		Select @save_gears_id = (select top 1 gears_id from #sqlname order by gears_id)
		Select @save_SQLname = (select top 1 SQLname from #sqlname where gears_id = @save_gears_id order by SQLname)
		Select @save_SQLport = (select top 1 port from dbacentral.dbo.dba_serverinfo where sqlname = @save_SQLname)
	    
		If exists (select 1 from dbo.job_pong_log where gears_id = @save_gears_id and SQLname = @save_SQLname and Process = 'restore' and status = 'running' and datediff(ss, ModDate, getdate()) < 300)
		   begin
			--  wait for 5 minutes before we pong again
			goto skip_restore_pong
		   end


		--  Ping this server using the auto_pong process to determine the status of the DEPL_RD restore job
		Select @miscprint = 'Restore status in-work for extended time for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.  Sending ping to check on job.'
		Print  @miscprint
		raiserror('', -1,-1) with nowait

		Select @save_rq_stamp = convert(sysname, getdate(), 121) + convert(nvarchar(40), newid())
		Select @db_query1 = 'DEPL_RD - 01 - Restore'
		Select @db_query2 = ''
		select @query = 'exec DEPLinfo.dbo.dpsp_auto_pong_to_control @rq_servername = ''' + @@servername 
			    + ''', @rq_stamp = ''' + @save_rq_stamp 
			    + ''', @rq_type = ''job'', @rq_detail01 = ''' + @db_query1 + ''', @rq_detail02 = ''' + @db_query2 + ''''
		Select @miscprint = 'Requesting restore job info from server ' + @save_SQLname + '.'
		Print @miscprint
		raiserror('', -1,-1) with nowait
		Select @cmd = 'sqlcmd -S' + @save_SQLname + ',' + @save_SQLport + ' -E -Q"' + @query + '"'
		print @cmd
		raiserror('', -1,-1) with nowait

		Select @try_count = 0
		try_restore_pong_01:
		EXEC @returncode = master.sys.xp_cmdshell @cmd--, no_output

--		If @returncode <> 0
--		   begin
--			Waitfor delay '00:00:05'
--			If @try_count < 5
--			   begin
--				Select @try_count = @try_count + 1
--				print '@Try = ' + convert(nvarchar(10), @try_count)
--				raiserror('', -1,-1) with nowait
--				goto try_restore_pong_01
--			   end
--			Else
--			   begin
--				print '@Try count maxed out.  Skip this process'
--				raiserror('', -1,-1) with nowait
--				goto skip_restore_pong
--			   end
--		   end


		If @returncode <> 0
		   begin
			print 'Skip this process'
			raiserror('', -1,-1) with nowait
			goto skip_restore_pong
		   end

		--  capture pong results
		select @pong_count = 0
		restore_pong_result:
		Waitfor delay '00:00:05'

		If exists (select 1 from DEPLcontrol.dbo.pong_return where pong_stamp = @save_rq_stamp)
		   begin
			Select @save_more_info = (select pong_detail01 from dbo.pong_return where pong_stamp = @save_rq_stamp)
			Select @save_more_info2 = (select pong_detail02 from dbo.pong_return where pong_stamp = @save_rq_stamp)

			If @save_more_info like '%running%'
			   begin
				Select @save_restore_status = 'in-work'

				If @save_more_info2 is not null and @save_more_info2 <> ''
				   begin
					Select @save_restore_status = @save_restore_status + ' ' + rtrim(ltrim(@save_more_info2)) + '%'
				   end


				Select @save_restore_reqdet_id = (select top 1 reqdet_id from dbo.request_detail where gears_id = @save_gears_id and Process = 'restore' and Status like 'in-work%' and SQLname = @save_SQLname)

				update dbo.request_detail set Status = @save_restore_status, ModDate = getdate() where reqdet_id = @save_restore_reqdet_id
	

				insert into dbo.job_pong_log values (@save_gears_id, @save_SQLname, 'restore', 'running', getdate())

				Select @miscprint = 'Restore status ' + @save_restore_status + ' - Restore job ping for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.  SQL job is still running.'
				Print  @miscprint
				raiserror('', -1,-1) with nowait



				--  Update Gears restore status
				If @@servername = @save_central_server
				   begin
					Select @miscprint = 'Updating restore request ' + convert(nvarchar(10), @save_gears_id) + ' for SQLname ' + @save_SQLname + '.'
					Print  @miscprint
					Print @save_restore_status
					raiserror('', -1,-1) with nowait

					Update brc set brc.status = @save_restore_status 
						from gears.dbo.BUILD_REQUEST_COMPONENTS brc, gears.dbo.COMPONENTS c, dbo.Request_detail rd
						where brc.build_request_id = @save_gears_id 
						and brc.component_id = c.component_id
						and c.component_name = rd.DBname
						and rd.gears_id = brc.build_request_id
						and rd.process = 'restore'
						and rd.SQLname = @save_SQLname
						and rd.status like '%in-work%'
				   end
			   end
			Else If @save_more_info like '%Last Job Completed%' or @save_more_info like '%never run%'
			   begin
				--  One last check before we send the email
				Waitfor delay '00:00:05'
				If not exists (select 1 from dbo.request_detail where gears_id = @save_gears_id and SQLname = @save_SQLname and status like 'in-work%')
				   begin
					goto skip_restore_pong
				   end

				--  for some reason the depl_rd job is not running and had not reported back.  Run the job diag process.
				Select @miscprint = 'Running the job diag process for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.  DEPL_RD job not running.'
				Print  @miscprint
				raiserror('', -1,-1) with nowait

				Select @save_ProjectName = (select top 1 ProjectName from dbo.request where gears_id = @save_gears_id)
				Select @save_ProjectNum = (select top 1 ProjectNum from dbo.request where gears_id = @save_gears_id)
				Select @save_DBname = (select top 1 DBname from dbo.request_detail where gears_id = @save_gears_id and SQLname = @save_SQLname and status like 'in-work%')
				Select @save_ProcessDetail = (select top 1 ProcessDetail from dbo.request_detail where gears_id = @save_gears_id and SQLname = @save_SQLname and status like 'in-work%')
				Select @save_APPLname = (select top 1 APPLname from dbo.request_detail where gears_id = @save_gears_id and SQLname = @save_SQLname and status like 'in-work%')
				Select @save_BASEfolder = (select top 1 BASEfolder from dbo.request_detail where gears_id = @save_gears_id and SQLname = @save_SQLname and status like 'in-work%')

				select @query = 'exec DEPLinfo.dbo.dpsp_diag_jobs @Gears_id = ' + convert(nvarchar(10), @save_gears_id)
				select @query = @query + ', @ProjectName = ''' + @save_ProjectName + ''''
				select @query = @query + ', @ProjectNum = ''' + @save_ProjectNum + ''''
				select @query = @query + ', @central_server = ''' +  @@servername + ''''
				select @query = @query + ', @Process = ''restore'''
				select @query = @query + ', @DBname = ''' + @save_DBname + ''''
				select @query = @query + ', @ProcessDetail = ''' + @save_ProcessDetail + ''''
				select @query = @query + ', @APPLname = ''' + @save_APPLname + ''''
				select @query = @query + ', @BASEfolder = ''' +  @save_BASEfolder + ''''
				Print @query
				raiserror('', -1,-1) with nowait
				Select @cmd = 'sqlcmd -S' + @save_SQLname + ',' + @save_SQLport + ' -dmaster -E -Q"' + @query + '"'
				print @cmd
				raiserror('', -1,-1) with nowait

				EXEC @returncode = master.sys.xp_cmdshell @cmd--, no_output
			   end
			Else If @save_more_info like '%JOB Failed%'
			   begin
				Select @save_subject = 'ERROR: DEPL_RD Central Job Check Error for SQL instance ' + @save_SQLname
				Select @save_message = 'DEPL_RD Central Job Check Error detected for server ' + @save_SQLname + '.  The restore job has failed.'

				--  If this job has been reported in the past 1 hours, skip this section
				If exists (select 1 from dbaadmin.dbo.No_Check where NoCheck_type = 'DEPL_RD_job' and detail01 = @save_SQLname and datediff(hh, createdate, getdate()) < 1) 
				   begin
					Print 'Skip sendmail for failed job on server ' + @save_SQLname
				   end
				Else
				   begin
					Delete from dbaadmin.dbo.No_Check where NoCheck_type = 'DEPL_RD_job' and detail01 = @save_SQLname
					insert into dbaadmin.dbo.No_Check values ('DEPL_RD_job', @save_SQLname, '', '', '', 'depl_control', getdate(), getdate())

					EXEC dbaadmin.dbo.dbasp_sendmail 
						--@recipients = 'jim.wilson@gettyimages.com',  
						@recipients = 'tssqldba@gettyimages.com',  
						@subject = @save_subject,
						@message = @save_message
				   end


				insert into dbo.job_pong_log values (@save_gears_id, @save_SQLname, 'restore', 'failed', getdate())

				Select @miscprint = 'Restore status in-work - Restore job ping for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.  SQL job Failed.  Email sent.'
				Print  @miscprint
				raiserror('', -1,-1) with nowait
			   end
		   end
		Else If @pong_count < 5
		   begin
			Select @pong_count = @pong_count + 1
			goto restore_pong_result
		   end


		skip_restore_pong:


		Delete from #sqlname where gears_id = @save_gears_id and SQLname = @save_SQLname
		If (select count(*) from #sqlname) > 0
		   begin
			goto restore_start_02
		   end
	   end
   end



-- when restore status is null 
If exists (select 1 from dbo.control_HL where HandShake_Status = 'completed' and Setup_Status like 'completed%' and restore_status is null)
   begin
	delete from #sqlname
	Insert into #sqlname select gears_id, SQLname from dbo.control_HL where HandShake_Status = 'completed' and Setup_Status like 'completed%' and restore_status is null
	--select * from #sqlname

	-- Loop through #sqlname 
	If (select count(*) from #sqlname) > 0
	   begin
		restore_start_03:

		Select @save_gears_id = (select top 1 gears_id from #sqlname order by gears_id)
		Select @save_SQLname = (select top 1 SQLname from #sqlname where gears_id = @save_gears_id order by SQLname)
		Select @save_SQLport = (select top 1 port from dbacentral.dbo.dba_serverinfo where sqlname = @save_SQLname)
		Select @save_ProjectName = (select top 1 ProjectName from dbo.request where gears_id = @save_gears_id)
		Select @save_ProjectNum = (select top 1 ProjectNum from dbo.request where gears_id = @save_gears_id)

		--  if there are no restore requests for this ticket, skip the restore section
		If not exists (select 1 from dbo.request_detail where Process = 'restore' and gears_id = @save_gears_id and SQLname = @save_SQLname and status not like '%cancel%')
		   begin
			update dbo.control_HL set Restore_Status = 'completed-none', Restore_complete = getdate()
				where gears_id = @save_gears_id and SQLname = @save_SQLname 

			Select @miscprint = 'No restores for this ticket and SQL instance.  Restore status marked completed for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.'
			Print  @miscprint
			raiserror('', -1,-1) with nowait

			goto restore_skip_03
		   end

		--  one last check to make sure we dont have anything active on this sql instance
		If exists(select 1 from dbo.Request r, dbo.request_detail rd
			    where r.gears_id = rd.gears_id
			    and r.gears_id <> @save_gears_id
			    and r.status = 'in_work'
			    and rd.status in ('pending', 'in-work')
			    and rd.SQLname = @save_SQLname)
		   begin
			--  We should never be here.  This is bad!
			Select @save_subject = 'ERROR: DEPL_RD Central Control Process Error from ' + @@servername
			Select @save_message = 'DEPL_RD Central Control Process had more than one "active" deployments for the same SQL instance (' + @save_SQLname + ').  Gears number ' + convert(nvarchar(10), @save_gears_id) + '.'

			EXEC dbaadmin.dbo.dbasp_sendmail 
				--@recipients = 'jim.wilson@gettyimages.com',  
				@recipients = 'tssqldba@gettyimages.com',  
				@subject = @save_subject,
				@message = @save_message

			--EXEC dbaadmin.dbo.dbasp_sendmail @recipients = 'jdtorpedo58@gmail.com', @subject = @save_subject, @message = @save_message


			Select @miscprint = 'Note: Gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.  Email sent to TSSQLDBA'
			Print  @miscprint
			raiserror('', -1,-1) with nowait

			goto restore_skip_03
		   end


		--  get the next DBname to be restored
		Select @save_DBname = (select top 1 rd.DBname 
						from dbo.request_detail rd, dbo.db_sequence s 
						where rd.DBname = s.DBname
						and rd.Process = 'restore' 
						and rd.gears_id = @save_gears_id 
						and rd.SQLname = @save_SQLname 
						and rd.status not like 'completed%' 
						and rd.status not like '%cancelled%' 
						order by s.seq_id) 
		Select @save_APPLname = (select APPLname from dbo.request_detail where gears_id = @save_gears_id and SQLname = @save_SQLname and process = 'restore' and DBname = @save_DBname)
		Select @save_BASEfolder = (select BASEfolder from dbo.request_detail where gears_id = @save_gears_id and SQLname = @save_SQLname and process = 'restore' and DBname = @save_DBname)

	
		--  run restore process for this SQLname
		--  insert the initial restore row into the control_local table on the target server
		Select @miscprint = 'Starting restore process for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.'
		Print  @miscprint
		raiserror('', -1,-1) with nowait

		select @query = 'If not exists (select 1 from DEPLinfo.dbo.control_local where Gears_id = ' + convert(nvarchar(10), @save_gears_id) + ' and Process = ''restore'' and DBname = ''' + @save_DBname + ''') begin '
		select @query = @query + 'insert into DEPLinfo.dbo.control_local (Gears_id, ProjectName, ProjectNum, central_server, status, Process, DBname, APPLname, BASEfolder, CreateDate)'
		select @query = @query + ' values (' + convert(nvarchar(10), @save_gears_id) + ', ''' + @save_ProjectName + ''''
		select @query = @query + ', ''' + @save_ProjectNum + ''', ''' +  @@servername + ''', ''pending'', ''restore'''
		select @query = @query + ', ''' + @save_DBname + ''', ''' + @save_APPLname + ''', ''' +  @save_BASEfolder + ''', getdate()) end'
		Print @query
		raiserror('', -1,-1) with nowait
		Select @cmd = 'sqlcmd -S' + @save_SQLname + ',' + @save_SQLport + ' -dmaster -E -Q"' + @query + '"'
		print @cmd
		raiserror('', -1,-1) with nowait

		Select @try_count = 0
		try_restore_03a:
		EXEC @returncode = master.sys.xp_cmdshell @cmd--, no_output

--		If @returncode <> 0
--		   begin
--			Waitfor delay '00:00:05'
--			If @try_count < 5
--			   begin
--				Select @try_count = @try_count + 1
--				print '@Try = ' + convert(nvarchar(10), @try_count)
--				raiserror('', -1,-1) with nowait
--				goto try_restore_03a
--			   end
--			Else
--			   begin
--				print '@Try count maxed out.  Skip this process'
--				raiserror('', -1,-1) with nowait
--				goto restore_skip_03
--			   end
--		   end

		If @returncode <> 0
		   begin
			print 'Skip this process'
			raiserror('', -1,-1) with nowait
			goto restore_skip_03
		   end


		--  Set the row in the control_HL table to in-work
		update dbo.control_HL set Restore_Status = 'in-work', Restore_start = getdate()
			where gears_id = @save_gears_id and SQLname = @save_SQLname 

		Select @miscprint = 'Table dbo.control_HL restore_start set to in-work for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.'
		Print  @miscprint
		raiserror('', -1,-1) with nowait


		--  Set the restore row in the request_detail table to in-work
		update dbo.request_detail set Status = 'in-work', ModDate = getdate()
			where gears_id = @save_gears_id and Process = 'restore' and DBname = @save_DBname and SQLname = @save_SQLname

		Select @miscprint = 'Table dbo.request_detail status set to in-work for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + ' and DBname ' + @save_DBname + '.'
		Print  @miscprint
		raiserror('', -1,-1) with nowait


		--  Now, Start the DEPL_RD - 01 - Restore job on the target server
		Select @miscprint = 'Starting SQL job "DEPL_RD - 01 - Restore" for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.'
		Print  @miscprint
		raiserror('', -1,-1) with nowait

		select @query = 'exec msdb.dbo.sp_start_job @job_name = ''DEPL_RD - 01 - Restore'''
		Print @query
		raiserror('', -1,-1) with nowait
		Select @cmd = 'sqlcmd -S' + @save_SQLname + ',' + @save_SQLport + ' -dmaster -E -Q"' + @query + '"'
		print @cmd
		raiserror('', -1,-1) with nowait

		Select @try_count = 0
		try_restore_03b:
		EXEC @returncode = master.sys.xp_cmdshell @cmd--, no_output

--		If @returncode <> 0
--		   begin
--			Waitfor delay '00:00:05'
--			If @try_count < 5
--			   begin
--				Select @try_count = @try_count + 1
--				print '@Try = ' + convert(nvarchar(10), @try_count)
--				raiserror('', -1,-1) with nowait
--				goto try_restore_03b
--			   end
--			Else
--			   begin
--				print '@Try count maxed out.  Skip this process'
--				raiserror('', -1,-1) with nowait
--				goto restore_skip_03
--			   end
--		   end


		If @returncode <> 0
		   begin
			print 'Skip this process'
			raiserror('', -1,-1) with nowait
			goto restore_skip_03
		   end



		restore_skip_03:

		Delete from #sqlname where SQLname = @save_SQLname
		If (select count(*) from #sqlname) > 0
		   begin
			goto restore_start_03
		   end
	   end
   end





-------------------------------------------------------------------------------------------------------------------
--  deploy process  -----------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------

-- when deploy status is "in-work" 
If exists (select 1 from dbo.control_HL where HandShake_Status = 'completed' and Setup_Status like 'completed%' and restore_status like 'completed%' and deploy_status = 'in-work')
   begin
	delete from #sqlname
	Insert into #sqlname select gears_id, SQLname from dbo.control_HL where HandShake_Status = 'completed' and Setup_Status like 'completed%' and restore_status like 'completed%' and deploy_status = 'in-work'
	--select * from #sqlname

	-- Loop through #sqlname 
	If (select count(*) from #sqlname) > 0
	   begin
		deploy_start_01:

		Select @save_gears_id = (select top 1 gears_id from #sqlname order by gears_id)
		Select @save_SQLname = (select top 1 SQLname from #sqlname where gears_id = @save_gears_id order by SQLname)
		Select @save_SQLport = (select top 1 port from dbacentral.dbo.dba_serverinfo where sqlname = @save_SQLname)
		

		Select @miscprint = 'Deploy check in-work status for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.'
		Print  @miscprint
		raiserror('', -1,-1) with nowait

		--  If all deploys are completed, update the control_HL table
		If not exists (select 1 from dbo.request_detail where Process = 'deploy' and gears_id = @save_gears_id and SQLname = @save_SQLname and status not like 'completed%' and status not like '%cancelled%')
		   begin
			update dbo.control_HL set deploy_Status = 'completed', deploy_complete = getdate()
				where gears_id = @save_gears_id and SQLname = @save_SQLname 

			Select @miscprint = 'Deploy status marked completed for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.'
			Print  @miscprint
			Print ''
			raiserror('', -1,-1) with nowait
										
			goto deploy_skip_01a
		   end


		--  If this deployment is still running...
		If exists (select 1 from dbo.request_detail where Process = 'deploy' and gears_id = @save_gears_id and SQLname = @save_SQLname and status like 'in-work%')
		   begin
			Select @save_DBname = (select top 1 DBname from dbo.request_detail where Process = 'deploy' and gears_id = @save_gears_id and SQLname = @save_SQLname and status like 'in-work%')
			Select @miscprint = 'Deployment(s) still processing for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + ' and DBname ' + @save_DBname + '.'
			Print  @miscprint
			Print ''
			raiserror('', -1,-1) with nowait

			goto deploy_skip_01a
		   end


		--  If we are here, we know there were deployments in this request, that they have not all completed, and none are currently running .  Get the next DBname to deploy
		Select @save_reqdet_id = (select top 1 rd.reqdet_id 
						from dbo.request_detail rd, dbo.db_sequence s 
						where rd.DBname = s.DBname
						and rd.Process = 'deploy' 
						and rd.gears_id = @save_gears_id 
						and rd.SQLname = @save_SQLname 
						and rd.status not like 'completed%' 
						and rd.status not like '%cancelled%' 
						order by s.seq_id, rd.processdetail) 
		Select @save_DBname = (select DBname from dbo.request_detail where reqdet_id = @save_reqdet_id)
		Select @save_ProjectName = (select top 1 ProjectName from dbo.request where gears_id = @save_gears_id)
		Select @save_ProjectNum = (select top 1 ProjectNum from dbo.request where gears_id = @save_gears_id)
		Select @save_APPLname = (select APPLname from dbo.request_detail where reqdet_id = @save_reqdet_id)

		--  Double check dependencies
		If exists (select 1 from dbo.Appl_Dependencies where APPLname_primary = @save_APPLname)
		   begin
			--  This APPLname does have a dependency.  
			--  Check for non-completed restore dependencies.
			If exists (select 1 from dbo.Appl_Dependencies ad, dbo.request_detail rd
					    where rd.gears_id = @save_gears_id
					    and rd.SQLname = @save_SQLname
					    and rd.DBname = @save_DBname
					    and rd.process = 'Deploy'
					    and rd.APPLname = ad.APPLname_primary
					    and ad.dependency_type = 'restore'
					    and ad.APPLname_dependent_on in (select APPLname from dbo.request_detail
											    where gears_id = @save_gears_id
											    and Domain = @domain
											    and process = 'restore'
											    and status not like 'completed%'
											    and status not like '%cancelled%'
											    and APPLname <> @save_APPLname)
					)
			   begin
				Select @miscprint = 'Non-completed restore dependency was found for gears_id ' + convert(nvarchar(20), @save_gears_id) + ', SQLname ' + @save_SQLname + ' and DBname ' + @save_DBname + '.  Skipping deployments for this SQL instance for now.'
				Print  @miscprint
				raiserror('', -1,-1) with nowait

				goto deploy_skip_01a
			   end

			--  Check for non-completed "all" dependencies.
			If exists (select 1 from dbo.Appl_Dependencies ad, dbo.request_detail rd
					    where rd.gears_id = @save_gears_id
					    and rd.SQLname = @save_SQLname
					    and rd.DBname = @save_DBname
					    and rd.process = 'Deploy'
					    and rd.APPLname = ad.APPLname_primary
					    and ad.dependency_type = 'all'
					    and ad.APPLname_dependent_on in (select APPLname from dbo.request_detail
											    where gears_id = @save_gears_id
											    and Domain = @domain
											    and status not like 'completed%'
											    and status not like '%cancelled%'
											    and APPLname <> @save_APPLname)
					)
			   begin
				Select @miscprint = 'Non-completed full dependency was found for gears_id ' + convert(nvarchar(20), @save_gears_id) + ', SQLname ' + @save_SQLname + ' and DBname ' + @save_DBname + '.  Skipping deployments for this SQL instance for now.'
				Print  @miscprint
				raiserror('', -1,-1) with nowait

				goto deploy_skip_01a
			   end

		   end


		Select @save_ProcessType = (select ProcessType from dbo.request_detail where reqdet_id = @save_reqdet_id)
		Select @save_ProcessDetail = (select ProcessDetail from dbo.request_detail where reqdet_id = @save_reqdet_id)


		--  insert the deploy row into the control_local table on the target server
		Select @miscprint = 'Deployments continue for gears_id ' + convert(nvarchar(20), @save_gears_id) + ', SQLname ' + @save_SQLname + ' and DB ' + @save_DBname + '.'
		Print  @miscprint
		raiserror('', -1,-1) with nowait

		select @query = 'If not exists (select 1 from DEPLinfo.dbo.control_local where Gears_id = ' + convert(nvarchar(10), @save_gears_id) + ' and Process = ''deploy'' and DBname = ''' + @save_DBname + ''') begin '
		select @query = @query + 'insert into DEPLinfo.dbo.control_local (Gears_id, ProjectName, ProjectNum, central_server, status, Process, DBname, APPLname, ProcessType, ProcessDetail, CreateDate)'
		select @query = @query + ' values (' + convert(nvarchar(10), @save_gears_id) + ', ''' + @save_ProjectName + ''''
		select @query = @query + ', ''' + @save_ProjectNum + ''', ''' +  @@servername + ''', ''pending'', ''deploy'''
		select @query = @query + ', ''' + @save_DBname + ''', ''' + @save_APPLname + ''', ''' +  @save_ProcessType + ''', ''' +  @save_ProcessDetail + ''', getdate()) end'
		Print @query
		raiserror('', -1,-1) with nowait
		Select @cmd = 'sqlcmd -S' + @save_SQLname + ',' + @save_SQLport + ' -dmaster -E -Q"' + @query + '"'
		print @cmd
		raiserror('', -1,-1) with nowait

		Select @try_count = 0
		try_deploy_01a:
		EXEC @returncode = master.sys.xp_cmdshell @cmd--, no_output

--		If @returncode <> 0
--		   begin
--			Waitfor delay '00:00:05'
--			If @try_count < 5
--			   begin
--				Select @try_count = @try_count + 1
--				print '@Try = ' + convert(nvarchar(10), @try_count)
--				raiserror('', -1,-1) with nowait
--				goto try_deploy_01a
--			   end
--			Else
--			   begin
--				print '@Try count maxed out.  Skip this process'
--				raiserror('', -1,-1) with nowait
--				goto deploy_skip_01b
--			   end
--		   end


		If @returncode <> 0
		   begin
			print 'Skip this process'
			raiserror('', -1,-1) with nowait
			goto deploy_skip_01b
		   end


		--  Set the deploy row for this DBname in the request_detail table to in-work
		update dbo.request_detail set Status = 'in-work', ModDate = getdate()
			where gears_id = @save_gears_id and Process = 'deploy' and DBname = @save_DBname and SQLname = @save_SQLname 

		Select @miscprint = 'Table dbo.request_detail status for deploy of DB ' + @save_DBname + ' set to in-work for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.'
		Print  @miscprint
		raiserror('', -1,-1) with nowait


		--  Now, Start the DEPL_RD - 51 - SQLDeploy job on the target server
		Select @miscprint = 'Starting SQL job "DEPL_RD - 51 - SQLDeploy" for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + ' and DB ' + @save_DBname + '.'
		Print  @miscprint
		raiserror('', -1,-1) with nowait

		select @query = 'exec msdb.dbo.sp_start_job @job_name = ''DEPL_RD - 51 - SQLDeploy'''
		Print @query
		raiserror('', -1,-1) with nowait
		Select @cmd = 'sqlcmd -S' + @save_SQLname + ',' + @save_SQLport + ' -dmaster -E -Q"' + @query + '"'
		print @cmd
		raiserror('', -1,-1) with nowait

		Select @try_count = 0
		try_deploy_01b:
		EXEC @returncode = master.sys.xp_cmdshell @cmd--, no_output

--		If @returncode <> 0
--		   begin
--			Waitfor delay '00:00:05'
--			If @try_count < 5
--			   begin
--				Select @try_count = @try_count + 1
--				print '@Try = ' + convert(nvarchar(10), @try_count)
--				raiserror('', -1,-1) with nowait
--				goto try_deploy_01b
--			   end
--			Else
--			   begin
--				print '@Try count maxed out.  Skip this process'
--				raiserror('', -1,-1) with nowait
--				goto deploy_skip_01b
--			   end
--		   end

		If @returncode <> 0
		   begin
			print 'Skip this process'
			raiserror('', -1,-1) with nowait
			goto deploy_skip_01b
		   end



		deploy_skip_01a:


		--  Update Gears for deployments
		If @@servername = @save_central_server
		   begin
			Select @miscprint = 'Updating Gears deployment request ' + convert(nvarchar(10), @save_gears_id) + ' for SQLname ' + @save_SQLname + '.'
			Print  @miscprint
			raiserror('', -1,-1) with nowait
			
			update brc set brc.status = rd.status, brc.build_deployed = rd.ProcessDetail, brc.date_deployed = getdate(), brc.server_name = @save_SQLname, brc.deployed_by = 24 
				from gears.dbo.BUILD_REQUEST_COMPONENTS brc, gears.dbo.COMPONENTS c, dbo.Request_detail rd
				where brc.build_request_id = @save_gears_id 
				and (brc.next_build = 'on' or build_number <> '')
				and brc.component_id = c.component_id
				and c.component_name = rd.DBname
				and rd.gears_id = brc.build_request_id
				and rd.process = 'deploy'
				and rd.SQLname = @save_SQLname
				and rd.status like '%completed%'

			update brc set brc.status = rd.status, brc.build_deployed = rd.process, brc.server_name = @save_SQLname, brc.deployed_by = null 
				from gears.dbo.BUILD_REQUEST_COMPONENTS brc, gears.dbo.COMPONENTS c, dbo.Request_detail rd
				where brc.build_request_id = @save_gears_id 
				and (brc.next_build = 'on' or build_number <> '')
				and brc.component_id = c.component_id
				and c.component_name = rd.DBname
				and rd.gears_id = brc.build_request_id
				and rd.process = 'deploy'
				and rd.SQLname = @save_SQLname
				and rd.status like '%in-work%'

			update brc set brc.status = rd.status, brc.build_deployed = rd.process, brc.server_name = null, brc.deployed_by = 24 
				from gears.dbo.BUILD_REQUEST_COMPONENTS brc, gears.dbo.COMPONENTS c, dbo.Request_detail rd
				where brc.build_request_id = @save_gears_id 
				and (brc.next_build = 'on' or build_number <> '')
				and brc.component_id = c.component_id
				and c.component_name = rd.DBname
				and rd.gears_id = brc.build_request_id
				and rd.process = 'deploy'
				and rd.SQLname = @save_SQLname
				and rd.status like '%cancelled%'
		   end


		deploy_skip_01b:


		Delete from #sqlname where gears_id = @save_gears_id and SQLname = @save_SQLname
		If (select count(*) from #sqlname) > 0
		   begin
			goto deploy_start_01
		   end
	   end
   end




-- when deploy status has been "in-work" for awhile (5 minutes = 300 seconds) 
If exists (select 1 from dbo.control_HL h, dbo.Request_detail rd
			where h.gears_id = rd.gears_id
			and h.HandShake_Status = 'completed' 
			and h.Setup_Status like 'completed%' 
			and h.restore_status like 'completed%'
			and h.deploy_status = 'in-work'
			and rd.process = 'deploy'
			and rd.status like 'in-work%' 
			and datediff(ss, rd.ModDate, getdate()) > 300)
   begin
	delete from #sqlname
	Insert into #sqlname select h.gears_id, h.SQLname from dbo.control_HL h, dbo.Request_detail rd
							where h.gears_id = rd.gears_id
							and h.HandShake_Status = 'completed' 
							and h.Setup_Status like 'completed%' 
							and h.restore_status like 'completed%' 
							and h.deploy_status = 'in-work'
							and rd.process = 'deploy'
							and rd.status like 'in-work%' 
							and datediff(ss, rd.ModDate, getdate()) > 300
	--select * from #sqlname

	-- Loop through #sqlname 
	If (select count(*) from #sqlname) > 0
	   begin
		deploy_start_02:

		Select @save_gears_id = (select top 1 gears_id from #sqlname order by gears_id)
		Select @save_SQLname = (select top 1 SQLname from #sqlname where gears_id = @save_gears_id order by SQLname)
		Select @save_SQLport = (select top 1 port from dbacentral.dbo.dba_serverinfo where sqlname = @save_SQLname)

		If exists (select 1 from dbo.job_pong_log where gears_id = @save_gears_id and SQLname = @save_SQLname and Process = 'deploy' and status = 'running' and datediff(ss, ModDate, getdate()) < 300)
		   begin
			--  wait for 5 minutes before we pong again
			goto skip_deploy_pong
		   end

		--  Ping this server using the auto_pong process to determine the status of the DEPL_RD deploy job
		Select @miscprint = 'Deploy status in-work for extended time for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.  Sending ping to check on job.'
		Print  @miscprint
		raiserror('', -1,-1) with nowait

		Select @save_rq_stamp = convert(sysname, getdate(), 121) + convert(nvarchar(40), newid())
		Select @db_query1 = 'DEPL_RD - 51 - SQLDeploy'
		Select @db_query2 = ''
		select @query = 'exec DEPLinfo.dbo.dpsp_auto_pong_to_control @rq_servername = ''' + @@servername 
			    + ''', @rq_stamp = ''' + @save_rq_stamp 
			    + ''', @rq_type = ''job'', @rq_detail01 = ''' + @db_query1 + ''', @rq_detail02 = ''' + @db_query2 + ''''
		Select @miscprint = 'Requesting deploy job info from server ' + @save_SQLname + '.'
		Print @miscprint
		raiserror('', -1,-1) with nowait
		Select @cmd = 'sqlcmd -S' + @save_SQLname + ',' + @save_SQLport + ' -E -Q"' + @query + '"'
		print @cmd
		raiserror('', -1,-1) with nowait

		Select @try_count = 0
		try_deploy_pong_01:
		EXEC @returncode = master.sys.xp_cmdshell @cmd--, no_output

--		If @returncode <> 0
--		   begin
--			Waitfor delay '00:00:05'
--			If @try_count < 5
--			   begin
--				Select @try_count = @try_count + 1
--				print '@Try = ' + convert(nvarchar(10), @try_count)
--				raiserror('', -1,-1) with nowait
--				goto try_deploy_pong_01
--			   end
--			Else
--			   begin
--				print '@Try count maxed out.  Skip this process'
--				raiserror('', -1,-1) with nowait
--				goto skip_deploy_pong
--			   end
--		   end


		If @returncode <> 0
		   begin
			print 'Skip this process'
			raiserror('', -1,-1) with nowait
			goto skip_deploy_pong
		   end


		--  capture pong results
		select @pong_count = 0
		deploy_pong_result:
		Waitfor delay '00:00:05'
		If exists (select 1 from DEPLcontrol.dbo.pong_return where pong_stamp = @save_rq_stamp)
		   begin
			Select @save_more_info = (select pong_detail01 from dbo.pong_return where pong_stamp = @save_rq_stamp)

			If @save_more_info like '%running%'
			   begin
				insert into dbo.job_pong_log values (@save_gears_id, @save_SQLname, 'deploy', 'running', getdate())

				Select @miscprint = 'Deployment status in-work - deploy job ping for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.  SQL job is still running.'
				Print  @miscprint
				raiserror('', -1,-1) with nowait
			   end
			Else If @save_more_info like '%JOB Failed%'
			   begin
				Select @save_subject = 'ERROR: DEPL_RD Central Job Check Error for SQL instance ' + @save_SQLname
				Select @save_message = 'DEPL_RD Central Job Check Error detected for server ' + @save_SQLname + '.  The SQLdeploy job has failed.'

				--  If this job has been reported in the past 1 hours, skip this section
				If exists (select 1 from dbaadmin.dbo.No_Check where NoCheck_type = 'DEPL_RD_job' and detail01 = @save_SQLname and datediff(hh, createdate, getdate()) < 1) 
				   begin
					Print 'Skip sendmail for failed job on server ' + @save_SQLname
				   end
				Else
				   begin
					Delete from dbaadmin.dbo.No_Check where NoCheck_type = 'DEPL_RD_job' and detail01 = @save_SQLname
					insert into dbaadmin.dbo.No_Check values ('DEPL_RD_job', @save_SQLname, '', '', '', 'depl_control', getdate(), getdate())

					EXEC dbaadmin.dbo.dbasp_sendmail 
						--@recipients = 'jim.wilson@gettyimages.com',  
						@recipients = 'tssqldba@gettyimages.com',  
						@subject = @save_subject,
						@message = @save_message
				   end


				insert into dbo.job_pong_log values (@save_gears_id, @save_SQLname, 'deploy', 'failed', getdate())

				Select @miscprint = 'deploy status in-work - deploy job ping for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.  SQL job Failed.  Email sent.'
				Print  @miscprint
				raiserror('', -1,-1) with nowait
			   end
			Else If @save_more_info like '%Last Job Completed%' or @save_more_info like '%never run%'
			   begin
				--  One last check before we send the email
				Waitfor delay '00:00:05'
				If not exists (select 1 from dbo.request_detail where gears_id = @save_gears_id and SQLname = @save_SQLname and status like 'in-work%')
				   begin
					goto skip_deploy_pong
				   end

				--  for some reason the depl_rd job is not running and had not reported back.  Run the job diag process.
				Select @miscprint = 'Running the job diag process for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.  DEPL_RD job not running.'
				Print  @miscprint
				raiserror('', -1,-1) with nowait

				Select @save_ProjectName = (select top 1 ProjectName from dbo.request where gears_id = @save_gears_id)
				Select @save_ProjectNum = (select top 1 ProjectNum from dbo.request where gears_id = @save_gears_id)
				Select @save_DBname = (select top 1 DBname from dbo.request_detail where gears_id = @save_gears_id and SQLname = @save_SQLname and status like 'in-work%')
				Select @save_ProcessType = (select top 1 ProcessType from dbo.request_detail where gears_id = @save_gears_id and SQLname = @save_SQLname and status like 'in-work%')
				Select @save_ProcessDetail = (select top 1 ProcessDetail from dbo.request_detail where gears_id = @save_gears_id and SQLname = @save_SQLname and status like 'in-work%')
				Select @save_APPLname = (select top 1 APPLname from dbo.request_detail where gears_id = @save_gears_id and SQLname = @save_SQLname and status like 'in-work%')
				Select @save_BASEfolder = (select top 1 BASEfolder from dbo.request_detail where gears_id = @save_gears_id and SQLname = @save_SQLname and status like 'in-work%')

				select @query = 'exec DEPLinfo.dbo.dpsp_diag_jobs @Gears_id = ' + convert(nvarchar(10), @save_gears_id)
				select @query = @query + ', @ProjectName = ''' + @save_ProjectName + ''''
				select @query = @query + ', @ProjectNum = ''' + @save_ProjectNum + ''''
				select @query = @query + ', @central_server = ''' +  @@servername + ''''
				select @query = @query + ', @Process = ''deploy'''
				select @query = @query + ', @DBname = ''' + @save_DBname + ''''
				select @query = @query + ', @ProcessType = ''' + @save_ProcessType + ''''
				select @query = @query + ', @ProcessDetail = ''' + @save_ProcessDetail + ''''
				select @query = @query + ', @APPLname = ''' + @save_APPLname + ''''
				select @query = @query + ', @BASEfolder = ''' +  @save_BASEfolder + ''''
				Print @query
				raiserror('', -1,-1) with nowait
				Select @cmd = 'sqlcmd -S' + @save_SQLname + ',' + @save_SQLport + ' -dmaster -E -Q"' + @query + '"'
				print @cmd
				raiserror('', -1,-1) with nowait

				EXEC @returncode = master.sys.xp_cmdshell @cmd--, no_output
			   end

		   end
		Else If @pong_count < 5
		   begin
			Select @pong_count = @pong_count + 1
			goto deploy_pong_result
		   end


		skip_deploy_pong:

		Delete from #sqlname where gears_id = @save_gears_id and SQLname = @save_SQLname
		If (select count(*) from #sqlname) > 0
		   begin
			goto deploy_start_02
		   end
	   end
   end



-- when deploy status is null 
If exists (select 1 from dbo.control_HL where HandShake_Status = 'completed' and Setup_Status like 'completed%' and restore_status like 'completed%' and deploy_status is null)
   begin
	delete from #sqlname
	Insert into #sqlname select gears_id, SQLname from dbo.control_HL where HandShake_Status = 'completed' and Setup_Status like 'completed%' and restore_status like 'completed%' and deploy_status is null
	--select * from #sqlname

	-- Loop through #sqlname 
	If (select count(*) from #sqlname) > 0
	   begin
		deploy_start_03:

		Select @save_gears_id = (select top 1 gears_id from #sqlname order by gears_id)
		Select @save_SQLname = (select top 1 SQLname from #sqlname where gears_id = @save_gears_id order by SQLname)
		Select @save_SQLport = (select top 1 port from dbacentral.dbo.dba_serverinfo where sqlname = @save_SQLname)
		Select @save_ProjectName = (select top 1 ProjectName from dbo.request where gears_id = @save_gears_id)
		Select @save_ProjectNum = (select top 1 ProjectNum from dbo.request where gears_id = @save_gears_id)

		--  if there are no deploy requests for this ticket, skip the deploy section
		If not exists (select 1 from dbo.request_detail where Process = 'deploy' and gears_id = @save_gears_id and SQLname = @save_SQLname and status not like '%cancel%')
		   begin
			update dbo.control_HL set deploy_Status = 'completed-none', deploy_complete = getdate()
				where gears_id = @save_gears_id and SQLname = @save_SQLname 

			Select @miscprint = 'No deployment requests for this ticket and SQL instance.  Deploy status marked completed for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.'
			Print  @miscprint
			raiserror('', -1,-1) with nowait

			goto deploy_skip_03
		   end


		--  one last check to make sure we dont have anything active on this sql instance
		If exists(select 1 from dbo.Request r, dbo.request_detail rd
			    where r.gears_id = rd.gears_id
			    and r.gears_id <> @save_gears_id
			    and r.status = 'in_work'
			    and rd.status in ('pending', 'in-work')
			    and rd.SQLname = @save_SQLname)
		   begin
			--  We should never be here.  This is bad!
			Select @save_subject = 'ERROR: DEPL_RD Central Control Process Error from ' + @@servername
			Select @save_message = 'DEPL_RD Central Control Process had more than one "active" deployments for the same SQL instance (' + @save_SQLname + ').  Gears number ' + convert(nvarchar(10), @save_gears_id) + '.'

			EXEC dbaadmin.dbo.dbasp_sendmail 
				--@recipients = 'jim.wilson@gettyimages.com',  
				@recipients = 'tssqldba@gettyimages.com',  
				@subject = @save_subject,
				@message = @save_message

			--EXEC dbaadmin.dbo.dbasp_sendmail @recipients = 'jdtorpedo58@gmail.com', @subject = @save_subject, @message = @save_message


			Select @miscprint = 'Note: Gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.  Email sent to TSSQLDBA'
			Print  @miscprint
			raiserror('', -1,-1) with nowait

			goto deploy_skip_03
		   end


		--  get the next DBname to be deployed
		Select @save_reqdet_id = (select top 1 rd.reqdet_id 
						from dbo.request_detail rd, dbo.db_sequence s 
						where rd.DBname = s.DBname
						and rd.Process = 'deploy' 
						and rd.gears_id = @save_gears_id 
						and rd.SQLname = @save_SQLname 
						and rd.status not like 'completed%' 
						and rd.status not like '%cancelled%' 
						order by s.seq_id, rd.processdetail) 

		Select @save_DBname = (select DBname from dbo.request_detail where reqdet_id = @save_reqdet_id)
		Select @save_APPLname = (select APPLname from dbo.request_detail where reqdet_id = @save_reqdet_id)

		-- Check dependencies for this DB deployment
		If exists (select 1 from dbo.Appl_Dependencies where APPLname_primary = @save_APPLname)
		   begin
			--  This APPLname does have a dependency.  
			--  Check for non-completed restore dependencies.
			If exists (select 1 from dbo.Appl_Dependencies ad, dbo.request_detail rd
					    where rd.gears_id = @save_gears_id
					    and rd.SQLname = @save_SQLname
					    and rd.DBname = @save_DBname
					    and rd.process = 'Deploy'
					    and rd.APPLname = ad.APPLname_primary
					    and ad.dependency_type = 'restore'
					    and ad.APPLname_dependent_on in (select APPLname from dbo.request_detail
											    where gears_id = @save_gears_id
											    and Domain = @domain
											    and process = 'restore'
											    and status not like 'completed%'
											    and status not like '%cancelled%'
											    and APPLname <> @save_APPLname)
					)
			   begin
				Select @miscprint = 'Non-completed restore dependency was found for gears_id ' + convert(nvarchar(20), @save_gears_id) + ', SQLname ' + @save_SQLname + ' and DBname ' + @save_DBname + '.  Skipping deployments for this SQL instance for now.'
				Print  @miscprint
				raiserror('', -1,-1) with nowait

				goto deploy_skip_03
			   end

			--  Check for non-completed "all" dependencies.
			If exists(select 1 from dbo.Appl_Dependencies where APPLname_primary = @save_APPLname and dependency_type = 'all')
			   begin
				--  Save the APPLname we are dependent on
				Select @save_APPLname_dependent_on = (select top 1 APPLname_dependent_on from dbo.Appl_Dependencies where APPLname_primary = @save_APPLname and dependency_type = 'all')

				If exists (select 1 from dbo.request_detail where gears_id = @save_gears_id and APPLname = @save_APPLname_dependent_on)
				   begin
					Select @save_dependent_SQLname = (select top 1 SQLname from dbo.request_detail where gears_id = @save_gears_id and APPLname = @save_APPLname_dependent_on)
					If exists (select 1 from dbo.request_detail where gears_id = @save_gears_id 
										    and SQLname = @save_dependent_SQLname 
										    and Process = 'end' 
										    and status not like '%completed%'			    
										    and status not like '%cancelled%')
					   begin
						Select @miscprint = 'Non-completed full dependency was found for gears_id ' + convert(nvarchar(20), @save_gears_id) + ', SQLname ' + @save_SQLname + ' and DBname ' + @save_DBname + '.  Skipping deployments for this SQL instance for now.'
						Print  @miscprint
						raiserror('', -1,-1) with nowait
						goto deploy_skip_03
					   end
				   end
			   end
		   end


		Select @save_ProcessType = (select ProcessType from dbo.request_detail where reqdet_id = @save_reqdet_id)
		Select @save_ProcessDetail = (select ProcessDetail from dbo.request_detail where reqdet_id = @save_reqdet_id)

	
		--  run deploy process for this SQLname
		--  insert the initial deploy row into the control_local table on the target server
		Select @miscprint = 'Starting SQLdeploy process for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.'
		Print  @miscprint
		raiserror('', -1,-1) with nowait


		select @query = 'If not exists (select 1 from DEPLinfo.dbo.control_local where Gears_id = ' + convert(nvarchar(10), @save_gears_id) + ' and Process = ''deploy'' and DBname = ''' + @save_DBname + ''') begin '
		select @query = @query + 'insert into DEPLinfo.dbo.control_local (Gears_id, ProjectName, ProjectNum, central_server, status, Process, DBname, APPLname, ProcessType, ProcessDetail, CreateDate)'
		select @query = @query + ' values (' + convert(nvarchar(10), @save_gears_id) + ', ''' + @save_ProjectName + ''''
		select @query = @query + ', ''' + @save_ProjectNum + ''', ''' +  @@servername + ''', ''pending'', ''deploy'''
		select @query = @query + ', ''' + @save_DBname + ''', ''' + @save_APPLname + ''', ''' +  @save_ProcessType + ''', ''' +  @save_ProcessDetail + ''', getdate()) end'
		Print @query
		raiserror('', -1,-1) with nowait
		Select @cmd = 'sqlcmd -S' + @save_SQLname + ',' + @save_SQLport + ' -dmaster -E -Q"' + @query + '"'
		print @cmd
		raiserror('', -1,-1) with nowait

		Select @try_count = 0
		try_deploy_03a:
		EXEC @returncode = master.sys.xp_cmdshell @cmd--, no_output

--		If @returncode <> 0
--		   begin
--			Waitfor delay '00:00:05'
--			If @try_count < 5
--			   begin
--				Select @try_count = @try_count + 1
--				print '@Try = ' + convert(nvarchar(10), @try_count)
--				raiserror('', -1,-1) with nowait
--				goto try_deploy_03a
--			   end
--			Else
--			   begin
--				print '@Try count maxed out.  Skip this process'
--				raiserror('', -1,-1) with nowait
--				goto deploy_skip_03
--			   end
--		   end

		If @returncode <> 0
		   begin
			print 'Skip this process'
			raiserror('', -1,-1) with nowait
			goto deploy_skip_03
		   end



		--  Set the row in the control_HL table to in-work
		update dbo.control_HL set deploy_Status = 'in-work', deploy_start = getdate()
			where gears_id = @save_gears_id and SQLname = @save_SQLname 

		Select @miscprint = 'Table dbo.control_HL deploy_start set to in-work for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.'
		Print  @miscprint
		raiserror('', -1,-1) with nowait


		--  Set the deploy row in the request_detail table to in-work
		update dbo.request_detail set Status = 'in-work', ModDate = getdate()
			where gears_id = @save_gears_id and Process = 'deploy' and DBname = @save_DBname and SQLname = @save_SQLname

		Select @miscprint = 'Table dbo.request_detail status set to in-work for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + ' and DBname ' + @save_DBname + '.'
		Print  @miscprint
		raiserror('', -1,-1) with nowait


		--  Now, Start the DEPL_RD - 51 - SQLDeploy job on the target server
		Select @miscprint = 'Starting SQL job "DEPL_RD - 51 - SQLDeploy" for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.'
		Print  @miscprint
		raiserror('', -1,-1) with nowait

		select @query = 'exec msdb.dbo.sp_start_job @job_name = ''DEPL_RD - 51 - SQLDeploy'''
		Print @query
		raiserror('', -1,-1) with nowait
		Select @cmd = 'sqlcmd -S' + @save_SQLname + ',' + @save_SQLport + ' -dmaster -E -Q"' + @query + '"'
		print @cmd
		raiserror('', -1,-1) with nowait

		Select @try_count = 0
		try_deploy_03b:
		EXEC @returncode = master.sys.xp_cmdshell @cmd--, no_output

--		If @returncode <> 0
--		   begin
--			Waitfor delay '00:00:05'
--			If @try_count < 5
--			   begin
--				Select @try_count = @try_count + 1
--				print '@Try = ' + convert(nvarchar(10), @try_count)
--				raiserror('', -1,-1) with nowait
--				goto try_deploy_03b
--			   end
--			Else
--			   begin
--				print '@Try count maxed out.  Skip this process'
--				raiserror('', -1,-1) with nowait
--				goto deploy_skip_03
--			   end
--		   end

		If @returncode <> 0
		   begin
			print 'Skip this process'
			raiserror('', -1,-1) with nowait
			goto deploy_skip_03
		   end



		deploy_skip_03:

		Delete from #sqlname where SQLname = @save_SQLname
		If (select count(*) from #sqlname) > 0
		   begin
			goto deploy_start_03
		   end
	   end
   end




-------------------------------------------------------------------------------------------------------------------
--  End process  --------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------

-- when End status is "in-work" 
If exists (select 1 from dbo.control_HL where HandShake_Status = 'completed' and Setup_Status like 'completed%' and restore_status like 'completed%' and deploy_status like 'completed%' and End_Status like 'in-work%')
   begin
	delete from #sqlname
	Insert into #sqlname select gears_id, SQLname from dbo.control_HL where HandShake_Status = 'completed' and Setup_Status like 'completed%' and restore_status like 'completed%' and deploy_status like 'completed%' and End_Status like 'in-work%'
	--select * from #sqlname

	-- Loop through #sqlname 
	If (select count(*) from #sqlname) > 0
	   begin
		End_start_01:

		Select @save_gears_id = (select top 1 gears_id from #sqlname order by gears_id)
		Select @save_SQLname = (select top 1 SQLname from #sqlname where gears_id = @save_gears_id order by SQLname)
		Select @save_SQLport = (select top 1 port from dbacentral.dbo.dba_serverinfo where sqlname = @save_SQLname)

		Select @miscprint = 'End status in-work process for request_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.'
		Print  @miscprint
		raiserror('', -1,-1) with nowait

		If exists (select 1 from dbo.request_detail where Process = 'end' and gears_id = @save_gears_id and SQLname = @save_SQLname and status like 'completed%')
		   begin
			Select @save_status = (select top 1 status from dbo.request_detail where Process = 'end' and gears_id = @save_gears_id and SQLname = @save_SQLname)

			update dbo.control_HL set End_Status = @save_status, End_complete = getdate()
				where gears_id = @save_gears_id and SQLname = @save_SQLname 

			Select @miscprint = 'End status marked completed for request_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.'
			Print  @miscprint
			raiserror('', -1,-1) with nowait
			
		   end


		--  If all request detail rows for this gears_id are completed or cancelled, mark the request completed
		If not exists (select 1 from dbo.request_detail where gears_id = @save_gears_id and (status not like 'completed%' and status not like 'cancelled%'))
		   begin
			Select @save_status = (select top 1 status from dbo.request_detail where Process = 'end' and gears_id = @save_gears_id and SQLname = @save_SQLname)

			update dbo.request set Status = 'completed', ModDate = getdate() where gears_id = @save_gears_id

			Select @miscprint = 'DEPLcontrol.dbo.Request marked completed for gears_id ' + convert(nvarchar(20), @save_gears_id) + '.'
			Print  @miscprint
			raiserror('', -1,-1) with nowait

			--  If all components of the request are completed, close the ticket
			If @@servername = @save_central_server
			   begin
				If not exists (SELECT * FROM gears.dbo.build_request_components where build_request_id = @save_gears_id and status is null)
				   begin
					Print 'DBA Note:  Closing Gears Ticket ' + convert(nvarchar(20), @save_gears_id) + '.'
					raiserror('', -1,-1) with nowait
					exec gears.dbo.update_request_status @build_request_id = @save_gears_id
				   end
			   end

			--  If this process is not running on the "main" central server, 
			--  create update command files and "fle transit" them to the main central server
			If @@servername <> @save_central_server
			   begin
				--  First we create update commands for the dbo.request_detail and dbo.request tables
				Print 'Create update commands for the dbo.request_detail and dbo.request tables on ' + @save_central_server + '.'
				raiserror('', -1,-1) with nowait

				--  Create the output file
				WAITFOR delay '00:00:02'
				Set @Hold_hhmmss = convert(varchar(8), getdate(), 8)
				Set @save_timestamp = convert(char(8), getdate(), 112) + substring(@Hold_hhmmss, 1, 2) + substring(@Hold_hhmmss, 4, 2) + substring(@Hold_hhmmss, 7, 2) 

				SELECT @RDupdate_file_name = 'RDupdate_' + @save_servername3 + '_' + @save_timestamp + '.gsql'

				Select @cmd = 'copy nul ' + @update_file_path + '\' + @RDupdate_file_name
				EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output

				Select @cmd = 'echo.>' + @update_file_path + '\' + @RDupdate_file_name
				EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output

				Select @miscprint = 'Use DEPLcontrol'
				Select @cmd = 'echo ' + @miscprint + '>>' + @update_file_path + '\' + @RDupdate_file_name
				EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output

				Select @miscprint = 'go'
				Select @cmd = 'echo ' + @miscprint + '>>' + @update_file_path + '\' + @RDupdate_file_name
				EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output

				Select @cmd = 'echo.>>' + @update_file_path + '\' + @RDupdate_file_name
				EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output


				--  Capture all the details related to this request
				delete from #temp_reqdet
				Insert into #temp_reqdet select DBname, status, APPLname, SQLname, Domain, Process, ProcessDetail, ModDate 
							from dbo.request_detail where gears_id = @save_gears_id
				--select * from #temp_reqdet

				-- Loop through #temp_reqdet (request detail items)
				If (select count(*) from #temp_reqdet) > 0
				   begin
					start_reqdet:

					Select @save2_SQLname = (select top 1 SQLname from #temp_reqdet order by SQLname)
					Select @save2_DBname = (select top 1 DBname from #temp_reqdet where SQLname = @save2_SQLname)
					Select @save2_Process = (select top 1 Process from #temp_reqdet where SQLname = @save2_SQLname and DBname = @save2_DBname)
					Select @save2_ModDate = (select top 1 ModDate from #temp_reqdet where SQLname = @save2_SQLname and DBname = @save2_DBname and Process = @save2_Process)
					Select @save2_status = (select status from #temp_reqdet where SQLname = @save2_SQLname and DBname = @save2_DBname and Process = @save2_Process and ModDate = @save2_ModDate)
					Select @save2_APPLname = (select APPLname from #temp_reqdet where SQLname = @save2_SQLname and DBname = @save2_DBname and Process = @save2_Process and ModDate = @save2_ModDate)
					Select @save2_Domain = (select Domain from #temp_reqdet where SQLname = @save2_SQLname and DBname = @save2_DBname and Process = @save2_Process and ModDate = @save2_ModDate)
					Select @save2_ProcessDetail = (select ProcessDetail from #temp_reqdet where SQLname = @save2_SQLname and DBname = @save2_DBname and Process = @save2_Process and ModDate = @save2_ModDate)

					If @save2_ProcessDetail is null
					   begin
						Select @save2_ProcessDetail = ''
					   end

					Select @miscprint = 'Update DEPLcontrol.dbo.request_detail'
					Select @cmd = 'echo ' + @miscprint + '>>' + @update_file_path + '\' + @RDupdate_file_name
					EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output

					Select @miscprint = '   set status = ''' + @save2_status + ''', ProcessDetail = ''' + @save2_ProcessDetail + ''', ModDate = ''' + convert(nvarchar(30), @save2_ModDate, 100) + ''''
					Select @cmd = 'echo ' + @miscprint + '>>' + @update_file_path + '\' + @RDupdate_file_name
					EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output

					Select @miscprint = '      Where gears_id = ' + convert(nvarchar(10), @save_gears_id) 
					Select @cmd = 'echo ' + @miscprint + '>>' + @update_file_path + '\' + @RDupdate_file_name
					EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output

					Select @miscprint = '        and DBname = ''' + @save2_DBname + ''''
					Select @cmd = 'echo ' + @miscprint + '>>' + @update_file_path + '\' + @RDupdate_file_name
					EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output

					Select @miscprint = '        and SQLname = ''' + @save2_SQLname + ''''
					Select @cmd = 'echo ' + @miscprint + '>>' + @update_file_path + '\' + @RDupdate_file_name
					EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output

					Select @miscprint = '        and Process = ''' + @save2_Process + ''''
					Select @cmd = 'echo ' + @miscprint + '>>' + @update_file_path + '\' + @RDupdate_file_name
					EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output

					Select @miscprint = '        and APPLname = ''' + @save2_APPLname + ''''
					Select @cmd = 'echo ' + @miscprint + '>>' + @update_file_path + '\' + @RDupdate_file_name
					EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output

					Select @miscprint = '        and Domain = ''' + @save2_Domain + ''''
					Select @cmd = 'echo ' + @miscprint + '>>' + @update_file_path + '\' + @RDupdate_file_name
					EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output

					Select @miscprint = 'go'
					Select @cmd = 'echo ' + @miscprint + '>>' + @update_file_path + '\' + @RDupdate_file_name
					EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output

					Select @cmd = 'echo.>>' + @update_file_path + '\' + @RDupdate_file_name
					EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output


					-- check for more rows to process
					delete from #temp_reqdet where SQLname = @save2_SQLname and DBname = @save2_DBname and Process = @save2_Process and ModDate = @save2_ModDate
					If (select count(*) from #temp_reqdet) > 0
					   begin
						goto start_reqdet
					   end


					--  Code to mark dbo.request complete if all detail items are complete.
					Select @miscprint = 'If not exists (select 1 from dbo.request_detail where gears_id = ' + convert(nvarchar(10), @save_gears_id) + ' and (status not like ''completed%'' and status not like ''cancelled%''))'
					Select @cmd = 'echo ' + @miscprint + '>>' + @update_file_path + '\' + @RDupdate_file_name
					EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output

					Select @miscprint = '   begin'
					Select @cmd = 'echo ' + @miscprint + '>>' + @update_file_path + '\' + @RDupdate_file_name
					EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output

					Select @miscprint = '      update DEPLcontrol.dbo.request set Status = ''completed'', ModDate = getdate() where gears_id = ' + convert(nvarchar(10), @save_gears_id)
					Select @cmd = 'echo ' + @miscprint + '>>' + @update_file_path + '\' + @RDupdate_file_name
					EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output

					Select @miscprint = '   end'
					Select @cmd = 'echo ' + @miscprint + '>>' + @update_file_path + '\' + @RDupdate_file_name
					EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output

					Select @miscprint = 'go'
					Select @cmd = 'echo ' + @miscprint + '>>' + @update_file_path + '\' + @RDupdate_file_name
					EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output

					Select @cmd = 'echo.>>' + @update_file_path + '\' + @RDupdate_file_name
					EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output
				   end


				-- Send the central DEPLcontrol updates to the main central server via file transit
				exec dbaadmin.dbo.dbasp_File_Transit @source_name = @RDupdate_file_name
					,@source_path = @update_file_path
					,@target_env = @save_central_domain
					,@target_server = @save_central_server
					,@target_share = @target_share




				-- Second, we create update commands for Gears
				Print 'Create update commands for Gears on ' + @save_central_server + '.'
				raiserror('', -1,-1) with nowait

				--  Create the output file
				WAITFOR delay '00:00:02'
				Set @Hold_hhmmss = convert(varchar(8), getdate(), 8)
				Set @save_timestamp = convert(char(8), getdate(), 112) + substring(@Hold_hhmmss, 1, 2) + substring(@Hold_hhmmss, 4, 2) + substring(@Hold_hhmmss, 7, 2) 

				SELECT @GEARSupdate_file_name = 'GEARSupdate_' + @save_servername3 + '_' + @save_timestamp + '.gsql'

				Select @cmd = 'copy nul ' + @update_file_path + '\' + @GEARSupdate_file_name
				EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output

				Select @cmd = 'echo.>' + @update_file_path + '\' + @GEARSupdate_file_name
				EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output

				Select @miscprint = 'Use Gears'
				Select @cmd = 'echo ' + @miscprint + '>>' + @update_file_path + '\' + @GEARSupdate_file_name
				EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output

				Select @miscprint = 'go'
				Select @cmd = 'echo ' + @miscprint + '>>' + @update_file_path + '\' + @GEARSupdate_file_name
				EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output

				Select @cmd = 'echo.>>' + @update_file_path + '\' + @GEARSupdate_file_name
				EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output

				Select @miscprint = 'EXECUTE gears.dbo.ChangeTicketStatus_sql @Action = 1, @BuildRequestID = ' + convert(nvarchar(10), @save_gears_id) + ', @NewStatus = ''IN WORK'''
				Select @cmd = 'echo ' + @miscprint + '>>' + @update_file_path + '\' + @GEARSupdate_file_name
				EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output

				Select @miscprint = 'go'
				Select @cmd = 'echo ' + @miscprint + '>>' + @update_file_path + '\' + @GEARSupdate_file_name
				EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output

				Select @cmd = 'echo.>>' + @update_file_path + '\' + @GEARSupdate_file_name
				EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output


				--  Capture all the details related to the restore and deploment processes
				delete from #temp_reqdet
				Insert into #temp_reqdet select DBname, status, APPLname, SQLname, Domain, Process, ProcessDetail, ModDate 
							from dbo.request_detail where gears_id = @save_gears_id and Process in ('restore', 'deploy')
				--select * from #temp_reqdet

				-- Loop through #temp_reqdet (request detail items)
				If (select count(*) from #temp_reqdet) > 0
				   begin
					start_reqdet02:

					Select @save2_DBname = (select top 1 DBname from #temp_reqdet order by DBname)
					Select @save2_Process = (select top 1 Process from #temp_reqdet where DBname = @save2_DBname order by process)
					Select @save2_ModDate = (select top 1 ModDate from #temp_reqdet where DBname = @save2_DBname and Process = @save2_Process)
					Select @save2_status = (select status from #temp_reqdet where DBname = @save2_DBname and Process = @save2_Process and ModDate = @save2_ModDate)
					Select @save2_SQLname = (select SQLname from #temp_reqdet where DBname = @save2_DBname and Process = @save2_Process and ModDate = @save2_ModDate)
					Select @save2_APPLname = (select APPLname from #temp_reqdet where DBname = @save2_DBname and Process = @save2_Process and ModDate = @save2_ModDate)
					Select @save2_Domain = (select Domain from #temp_reqdet where DBname = @save2_DBname and Process = @save2_Process and ModDate = @save2_ModDate)
					Select @save2_ProcessDetail = (select ProcessDetail from #temp_reqdet where DBname = @save2_DBname and Process = @save2_Process and ModDate = @save2_ModDate)

					Select @miscprint = 'update brc set brc.status = ''' + @save2_status + ''''
					Select @cmd = 'echo ' + @miscprint + '>>' + @update_file_path + '\' + @GEARSupdate_file_name
					EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output

					Select @miscprint = '              ,brc.date_deployed = getdate()'
					Select @cmd = 'echo ' + @miscprint + '>>' + @update_file_path + '\' + @GEARSupdate_file_name
					EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output

					Select @miscprint = '              ,brc.server_name = ''' + @save2_SQLname + ''''
					Select @cmd = 'echo ' + @miscprint + '>>' + @update_file_path + '\' + @GEARSupdate_file_name
					EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output

					Select @miscprint = '              ,brc.deployed_by = 24'
					Select @cmd = 'echo ' + @miscprint + '>>' + @update_file_path + '\' + @GEARSupdate_file_name
					EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output


					If @save2_Process = 'deploy'
					   begin
						Select @miscprint = '              ,brc.build_deployed = ''' + @save2_ProcessDetail + ''''
						Select @cmd = 'echo ' + @miscprint + '>>' + @update_file_path + '\' + @GEARSupdate_file_name
						EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output
					   end
					Else
					   begin
						Select @miscprint = '              ,brc.build_deployed = ''restore'''
						Select @cmd = 'echo ' + @miscprint + '>>' + @update_file_path + '\' + @GEARSupdate_file_name
						EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output
					   end
				
					Select @miscprint = 'From gears.dbo.BUILD_REQUEST_COMPONENTS brc, gears.dbo.COMPONENTS c'
					Select @cmd = 'echo ' + @miscprint + '>>' + @update_file_path + '\' + @GEARSupdate_file_name
					EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output

					Select @miscprint = 'Where brc.build_request_id = ' + convert(nvarchar(10), @save_gears_id) 
					Select @cmd = 'echo ' + @miscprint + '>>' + @update_file_path + '\' + @GEARSupdate_file_name
					EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output

					Select @miscprint = '  and brc.component_id = c.component_id'
					Select @cmd = 'echo ' + @miscprint + '>>' + @update_file_path + '\' + @GEARSupdate_file_name
					EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output

					Select @miscprint = '  and c.component_name = ''' + @save2_DBname + ''''
					Select @cmd = 'echo ' + @miscprint + '>>' + @update_file_path + '\' + @GEARSupdate_file_name
					EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output

					Select @miscprint = 'go'
					Select @cmd = 'echo ' + @miscprint + '>>' + @update_file_path + '\' + @GEARSupdate_file_name
					EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output

					Select @cmd = 'echo.>>' + @update_file_path + '\' + @GEARSupdate_file_name
					EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output


					-- check for more rows to process
					delete from #temp_reqdet where DBname = @save2_DBname
					If (select count(*) from #temp_reqdet) > 0
					   begin
						goto start_reqdet02
					   end


					--  Code to mark the Gears ticket complete if all build_request_components are complete.
					Select @miscprint = 'If not exists (SELECT * FROM gears.dbo.build_request_components where build_request_id = ' + convert(nvarchar(10), @save_gears_id) + ' and status is null)' 
					Select @cmd = 'echo ' + @miscprint + '>>' + @update_file_path + '\' + @GEARSupdate_file_name
					EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output

					Select @miscprint = '   begin'
					Select @cmd = 'echo ' + @miscprint + '>>' + @update_file_path + '\' + @GEARSupdate_file_name
					EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output

					Select @miscprint = '      exec gears.dbo.update_request_status @build_request_id = ' + convert(nvarchar(10), @save_gears_id)
					Select @cmd = 'echo ' + @miscprint + '>>' + @update_file_path + '\' + @GEARSupdate_file_name
					EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output

					Select @miscprint = '   end'
					Select @cmd = 'echo ' + @miscprint + '>>' + @update_file_path + '\' + @GEARSupdate_file_name
					EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output

					Select @miscprint = 'go'
					Select @cmd = 'echo ' + @miscprint + '>>' + @update_file_path + '\' + @GEARSupdate_file_name
					EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output

					Select @cmd = 'echo.>>' + @update_file_path + '\' + @GEARSupdate_file_name
					EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output
				   end


				-- Send the Gears updates to the main central server via file transit
				exec dbaadmin.dbo.dbasp_File_Transit @source_name = @GEARSupdate_file_name
					,@source_path = @update_file_path
					,@target_env = @save_central_domain
					,@target_server = @save_central_server
					,@target_share = @target_share

			   end
		   end


		Delete from #sqlname where gears_id = @save_gears_id and SQLname = @save_SQLname
		If (select count(*) from #sqlname) > 0
		   begin
			goto End_start_01
		   end
	   end
   end


-- when End status has been "in-work" for awhile (5 minutes = 300 seconds) 
If exists (select 1 from dbo.control_HL where End_Status = 'in-work' and datediff(ss, End_start, getdate()) > 300)
   begin
	delete from #sqlname
	Insert into #sqlname select gears_id, SQLname from dbo.control_HL where End_Status = 'in-work' and datediff(ss, End_start, getdate()) > 300
	--select * from #sqlname

	-- Loop through #sqlname 
	If (select count(*) from #sqlname) > 0
	   begin
		End_start_02:

		Select @save_gears_id = (select top 1 gears_id from #sqlname order by gears_id)
		Select @save_SQLname = (select top 1 SQLname from #sqlname where gears_id = @save_gears_id order by SQLname)
		Select @save_SQLport = (select top 1 port from dbacentral.dbo.dba_serverinfo where sqlname = @save_SQLname)

		If exists (select 1 from dbo.job_pong_log where gears_id = @save_gears_id and SQLname = @save_SQLname and Process = 'end' and status = 'running' and datediff(ss, ModDate, getdate()) < 300)
		   begin
			--  wait for 5 minutes before we pong again
			goto skip_end_pong
		   end

		--  Ping this server using the auto_pong process to determine the status of the DEPL_RD end job
		Select @miscprint = 'End (99) status in-work for extended time for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.  Sending ping to check on job.'
		Print  @miscprint
		raiserror('', -1,-1) with nowait

		Select @save_rq_stamp = convert(sysname, getdate(), 121) + convert(nvarchar(40), newid())
		Select @db_query1 = 'DEPL_RD - 99 - Deployment End'
		Select @db_query2 = ''
		select @query = 'exec DEPLinfo.dbo.dpsp_auto_pong_to_control @rq_servername = ''' + @@servername 
			    + ''', @rq_stamp = ''' + @save_rq_stamp 
			    + ''', @rq_type = ''job'', @rq_detail01 = ''' + @db_query1 + ''', @rq_detail02 = ''' + @db_query2 + ''''
		Select @miscprint = 'Requesting end job info from server ' + @save_SQLname + '.'
		Print @miscprint
		raiserror('', -1,-1) with nowait
		Select @cmd = 'sqlcmd -S' + @save_SQLname + ',' + @save_SQLport + ' -E -Q"' + @query + '"'
		print @cmd
		raiserror('', -1,-1) with nowait

		Select @try_count = 0
		try_end_pong_01:
		EXEC @returncode = master.sys.xp_cmdshell @cmd--, no_output

--		If @returncode <> 0
--		   begin
--			Waitfor delay '00:00:05'
--			If @try_count < 5
--			   begin
--				Select @try_count = @try_count + 1
--				print '@Try = ' + convert(nvarchar(10), @try_count)
--				raiserror('', -1,-1) with nowait
--				goto try_end_pong_01
--			   end
--			Else
--			   begin
--				print '@Try count maxed out.  Skip this process'
--				raiserror('', -1,-1) with nowait
--				goto skip_end_pong
--			   end
--		   end

		If @returncode <> 0
		   begin
			print 'Skip this process'
			raiserror('', -1,-1) with nowait
			goto skip_end_pong

		   end


		--  capture pong results
		select @pong_count = 0
		end_pong_result:
		Waitfor delay '00:00:05'
		If exists (select 1 from DEPLcontrol.dbo.pong_return where pong_stamp = @save_rq_stamp)
		   begin
			Select @save_more_info = (select pong_detail01 from dbo.pong_return where pong_stamp = @save_rq_stamp)

			If @save_more_info like '%running%'
			   begin
				insert into dbo.job_pong_log values (@save_gears_id, @save_SQLname, 'end', 'running', getdate())

				Select @miscprint = 'End (99) status in-work - post job ping for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.  SQL job is still running.'
				Print  @miscprint
				raiserror('', -1,-1) with nowait
			   end
			Else If @save_more_info like '%JOB Failed%'
			   begin
				Select @save_subject = 'ERROR: DEPL_RD Central Job Check Error for SQL instance ' + @save_SQLname
				Select @save_message = 'DEPL_RD Central Job Check Error detected for server ' + @save_SQLname + '.  The end job has failed.'

				--  If this job has been reported in the past 1 hours, skip this section
				If exists (select 1 from dbaadmin.dbo.No_Check where NoCheck_type = 'DEPL_RD_job' and detail01 = @save_SQLname and datediff(hh, createdate, getdate()) < 1) 
				   begin
					Print 'Skip sendmail for failed job on server ' + @save_SQLname
				   end
				Else
				   begin
					Delete from dbaadmin.dbo.No_Check where NoCheck_type = 'DEPL_RD_job' and detail01 = @save_SQLname
					insert into dbaadmin.dbo.No_Check values ('DEPL_RD_job', @save_SQLname, '', '', '', 'depl_control', getdate(), getdate())

					EXEC dbaadmin.dbo.dbasp_sendmail 
						--@recipients = 'jim.wilson@gettyimages.com',  
						@recipients = 'tssqldba@gettyimages.com',  
						@subject = @save_subject,
						@message = @save_message
				   end


				insert into job_pong_log values (@save_gears_id, @save_SQLname, 'end', 'failed', getdate())

				Select @miscprint = 'End (99) status in-work - post job ping for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.  SQL job Failed.  Email sent.'
				Print  @miscprint
				raiserror('', -1,-1) with nowait
			   end
			Else If @save_more_info like '%Last Job Completed%' or @save_more_info like '%never run%'
			   begin
				--  One last check before we send the email
				Waitfor delay '00:00:05'
				If not exists (select 1 from dbo.request_detail where gears_id = @save_gears_id and SQLname = @save_SQLname and status like 'in-work%')
				   begin
					goto skip_end_pong
				   end

				--  for some reason the depl_rd job is not running and had not reported back.  Run the job diag process.
				Select @miscprint = 'Running the job diag process for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.  DEPL_RD job not running.'
				Print  @miscprint
				raiserror('', -1,-1) with nowait

				Select @save_ProjectName = (select top 1 ProjectName from dbo.request where gears_id = @save_gears_id)
				Select @save_ProjectNum = (select top 1 ProjectNum from dbo.request where gears_id = @save_gears_id)

				select @query = 'exec DEPLinfo.dbo.dpsp_diag_jobs @Gears_id = ' + convert(nvarchar(10), @save_gears_id)
				select @query = @query + ', @ProjectName = ''' + @save_ProjectName + ''''
				select @query = @query + ', @ProjectNum = ''' + @save_ProjectNum + ''''
				select @query = @query + ', @central_server = ''' +  @@servername + ''''
				select @query = @query + ', @Process = ''end'''
				Print @query
				raiserror('', -1,-1) with nowait
				Select @cmd = 'sqlcmd -S' + @save_SQLname + ',' + @save_SQLport + ' -dmaster -E -Q"' + @query + '"'
				print @cmd
				raiserror('', -1,-1) with nowait

				EXEC @returncode = master.sys.xp_cmdshell @cmd--, no_output
			   end

		   end
		Else If @pong_count < 5
		   begin
			Select @pong_count = @pong_count + 1
			goto end_pong_result
		   end


		skip_end_pong:

		Delete from #sqlname where gears_id = @save_gears_id and SQLname = @save_SQLname
		If (select count(*) from #sqlname) > 0
		   begin
			goto End_start_02
		   end
	   end
   end



-- when End status is null 
If exists (select 1 from dbo.control_HL where HandShake_Status = 'completed' and Setup_Status like 'completed%' and restore_status like 'completed%' and deploy_status like 'completed%' and End_Status is null)
   begin
	delete from #sqlname
	Insert into #sqlname select gears_id, SQLname from dbo.control_HL where HandShake_Status = 'completed' and Setup_Status like 'completed%' and restore_status like 'completed%' and deploy_status like 'completed%' and End_Status is null
	--select * from #sqlname

	-- Loop through #sqlname 
	If (select count(*) from #sqlname) > 0
	   begin
		End_start_03:

		Select @save_gears_id = (select top 1 gears_id from #sqlname order by gears_id)
		Select @save_SQLname = (select top 1 SQLname from #sqlname where gears_id = @save_gears_id order by SQLname)
		Select @save_SQLport = (select top 1 port from dbacentral.dbo.dba_serverinfo where sqlname = @save_SQLname)
		Select @save_ProjectName = (select top 1 ProjectName from dbo.request where gears_id = @save_gears_id)
		Select @save_ProjectNum = (select top 1 ProjectNum from dbo.request where gears_id = @save_gears_id)

		--  one last check to make sure we dont have anything active on this sql instance
		If exists(select 1 from dbo.Request r, dbo.request_detail rd
			    where r.gears_id = rd.gears_id
			    and r.gears_id <> @save_gears_id
			    and r.status = 'in_work'
			    and rd.status in ('pending', 'in-work')
			    and rd.SQLname = @save_SQLname)
		   begin
			--  We should never be here.  This is bad!
			Select @save_subject = 'ERROR: DEPL_RD Central Control Process Error from ' + @@servername
			Select @save_message = 'DEPL_RD Central Control Process had more than one "active" deployments for the same SQL instance (' + @save_SQLname + ').  Gears number ' + convert(nvarchar(10), @save_gears_id) + '.'

			EXEC dbaadmin.dbo.dbasp_sendmail 
				--@recipients = 'jim.wilson@gettyimages.com',  
				@recipients = 'tssqldba@gettyimages.com',  
				@subject = @save_subject,
				@message = @save_message

			--EXEC dbaadmin.dbo.dbasp_sendmail @recipients = 'jdtorpedo58@gmail.com', @subject = @save_subject, @message = @save_message


			Select @miscprint = 'Note: Gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.  Email sent to TSSQLDBA'
			Print  @miscprint
			raiserror('', -1,-1) with nowait

			goto end_skip_03
		   end

		--  run End process for this SQLname
		--  insert the initial End row into the control_local table on the target server
		Select @miscprint = 'End status end process for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.'
		Print  @miscprint
		raiserror('', -1,-1) with nowait

		select @query = 'If not exists (select 1 from DEPLinfo.dbo.control_local where Gears_id = ' + convert(nvarchar(10), @save_gears_id) + ' and Process = ''end'') begin '
		select @query = @query + 'insert into DEPLinfo.dbo.control_local (Gears_id, ProjectName, ProjectNum, central_server, status, Process, CreateDate)'
		select @query = @query + ' values (' + convert(nvarchar(10), @save_gears_id) + ', ''' + @save_ProjectName + ''''
		select @query = @query + ', ''' + @save_ProjectNum + ''', ''' +  @@servername + ''', ''pending'', ''end'', getdate()) end'
		Print @query
		raiserror('', -1,-1) with nowait
		Select @cmd = 'sqlcmd -S' + @save_SQLname + ',' + @save_SQLport + ' -dmaster -E -Q"' + @query + '"'
		print @cmd
		raiserror('', -1,-1) with nowait

		Select @try_count = 0
		try_end_03a:
		EXEC @returncode = master.sys.xp_cmdshell @cmd--, no_output

--		If @returncode <> 0
--		   begin
--			Waitfor delay '00:00:05'
--			If @try_count < 5
--			   begin
--				Select @try_count = @try_count + 1
--				print '@Try = ' + convert(nvarchar(10), @try_count)
--				raiserror('', -1,-1) with nowait
--				goto try_end_03a
--			   end
--			Else
--			   begin
--				print '@Try count maxed out.  Skip this process'
--				raiserror('', -1,-1) with nowait
--				goto end_skip_03
--			   end
--		   end


		If @returncode <> 0
		   begin
			print 'Skip this process'
			raiserror('', -1,-1) with nowait
			goto end_skip_03
		   end


		--  Set the row in the control_HL table to in-work
		update dbo.control_HL set End_Status = 'in-work', End_start = getdate()
			where gears_id = @save_gears_id and SQLname = @save_SQLname 

		Select @miscprint = 'Table dbo.control_HL End_start set to in-work for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.'
		Print  @miscprint
		raiserror('', -1,-1) with nowait


		--  Set the end row in the request_detail table to in-work
		update dbo.request_detail set Status = 'in-work', ModDate = getdate()
			where gears_id = @save_gears_id and SQLname = @save_SQLname and Process = 'end' 

		Select @miscprint = 'Table dbo.request_detail status set to in-work for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.'
		Print  @miscprint
		raiserror('', -1,-1) with nowait


		--  Now, start the DEPL_RD - 99 - Deployment End job on the target server
		Select @miscprint = 'Starting SQL job "DEPL_RD - 99 - Deployment End" for gears_id ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname + '.'
		Print  @miscprint
		raiserror('', -1,-1) with nowait

		select @query = 'exec msdb.dbo.sp_start_job @job_name = ''DEPL_RD - 99 - Deployment End'''
		Print @query
		raiserror('', -1,-1) with nowait
		Select @cmd = 'sqlcmd -S' + @save_SQLname + ',' + @save_SQLport + ' -dmaster -E -Q"' + @query + '"'
		print @cmd
		raiserror('', -1,-1) with nowait

		Select @try_count = 0
		try_end_03b:
		EXEC @returncode = master.sys.xp_cmdshell @cmd--, no_output

--		If @returncode <> 0
--		   begin
--			Waitfor delay '00:00:05'
--			If @try_count < 5
--			   begin
--				Select @try_count = @try_count + 1
--				print '@Try = ' + convert(nvarchar(10), @try_count)
--				raiserror('', -1,-1) with nowait
--				goto try_end_03b
--			   end
--			Else
--			   begin
--				print '@Try count maxed out.  Skip this process'
--				raiserror('', -1,-1) with nowait
--				goto end_skip_03
--			   end
--		   end


		If @returncode <> 0
		   begin
			print 'Skip this process'
			raiserror('', -1,-1) with nowait
			goto end_skip_03
		   end
		   


		end_skip_03:

		Delete from #sqlname where SQLname = @save_SQLname
		If (select count(*) from #sqlname) > 0
		   begin
			goto End_start_03
		   end
	   end
   end







-------------------------------------------------------------------------------------------------------------------
--  Extra Check process  ------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------

--  One last check for requests still in work when all control_HL related rows are completed and all request_detail rows are completed. 
--  Note:  In normal processing, this code should never need to be run
start_extra_check:

If exists (select 1 from dbo.request r
		where r.status like 'in-work%' 
		and not exists(select 1 from dbo.request_detail rd where r.gears_id = rd.gears_id and rd.status not like 'complet%' and rd.status not like 'cancel%')
		and not exists(select 1 from dbo.control_HL chl where r.gears_id = chl.gears_id and (chl.HandShake_Status not like '%complet%' 
												or chl.Setup_Status not like '%complet%'
												or chl.restore_status not like '%complet%' 
												or chl.deploy_status not like '%complet%'
												or chl.End_Status not like '%complet%')
												))
   begin
	Select @save_gears_id = (select top 1 r.gears_id from dbo.request r
		where r.status like 'in-work%' 
		and not exists(select 1 from dbo.request_detail rd where r.gears_id = rd.gears_id and rd.status not like 'complet%' and rd.status not like 'cancel%')
		and not exists(select 1 from dbo.control_HL chl where r.gears_id = chl.gears_id and (chl.HandShake_Status not like '%complet%' 
												or chl.Setup_Status not like '%complet%'
												or chl.restore_status not like '%complet%' 
												or chl.deploy_status not like '%complet%'
												or chl.End_Status not like '%complet%')
												))

	update dbo.request set Status = 'completed', ModDate = getdate() where gears_id = @save_gears_id

	Select @miscprint = 'DEPLcontrol.dbo.Request marked completed (in extra section) for gears_id ' + convert(nvarchar(20), @save_gears_id) + '.'
	Print  @miscprint
	raiserror('', -1,-1) with nowait


	--  check for more rows to process
	If exists (select 1 from dbo.request r
			where r.status like 'in-work%' 
			and not exists(select 1 from dbo.request_detail rd where r.gears_id = rd.gears_id and rd.status not like 'complet%' and rd.status not like 'cancel%')
			and not exists(select 1 from dbo.control_HL chl where r.gears_id = chl.gears_id and (chl.HandShake_Status not like '%complet%' 
													or chl.Setup_Status not like '%complet%'
													or chl.restore_status not like '%complet%' 
													or chl.deploy_status not like '%complet%'
													or chl.End_Status not like '%complet%')
													))
	   begin
		goto start_extra_check
	   end

   end





-----------------  Finalizations  ------------------

label99:

drop table #fileexists
drop table #DirectoryTempTable
drop table #DirectoryTempTable2
drop table #SQLname
drop table #applname
drop table #applname2
drop table #dbname
drop table #temp_reqdet
drop table #insert_hl





GO
EXEC sys.sp_addextendedproperty @name=N'BuildApplication', @value=N'' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'dpsp_Control'
GO
EXEC sys.sp_addextendedproperty @name=N'BuildBranch', @value=N'' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'dpsp_Control'
GO
EXEC sys.sp_addextendedproperty @name=N'BuildNumber', @value=N'' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'dpsp_Control'
GO
EXEC sys.sp_addextendedproperty @name=N'DeplFileName', @value=N'' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'dpsp_Control'
GO
EXEC sys.sp_addextendedproperty @name=N'Version', @value=N'1.0.0' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'dpsp_Control'
GO
