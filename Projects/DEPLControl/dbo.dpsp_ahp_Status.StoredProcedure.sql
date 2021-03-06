USE [DEPLcontrol]
GO
/****** Object:  StoredProcedure [dbo].[dpsp_ahp_Status]    Script Date: 10/4/2013 11:02:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[dpsp_ahp_Status] (@request_id int = null
				,@report_only char(1) = 'n')

/*********************************************************
 **  Stored Procedure dpsp_ahp_Status                  
 **  Written by Jim Wilson, Getty Images                
 **  November 11, 2010                                      
 **  
 **  This sproc will provide status information for SQL related
 **  deployment requests as part of the SQL Request Driven Process.
 **
 **  Input Par(s);
 **  @request_id - is the request ID for a specific request.  This
 **              will display information for only that request.
 **
 ***************************************************************/
  as
set nocount on

--	======================================================================================
--	Revision History
--	Date		Author     		Desc
--	==========	====================	=============================================
--	11/11/2010	Jim Wilson		New process.
--	12/02/2010	Jim Wilson		New code to display "normal" request type.
--	02/28/2011	Jim Wilson		Check the control_ahp table for in-work requests.
--	======================================================================================


/***
Declare @request_id int
Declare @report_only char(1)

Select @request_id = 12748
Select @report_only = 'n'
--***/

-----------------  declares  ------------------

DECLARE
	 @miscprint			nvarchar(2000)
	,@query				nvarchar(2000)
	,@cmd				nvarchar(4000)
	,@charpos			int
	,@return_status			int
	,@save_request_id		int
	,@save_servername		sysname
	,@save_servername2		sysname
	,@save_projectname		sysname
	,@save_ReleaseNum		sysname
	,@save_Project			sysname
	,@save_Request_start_char	char(16)
	,@save_environment		sysname
	,@save_DBname			sysname
	,@save_APPLname			sysname
	,@save_SQLname			sysname
	,@save_DETAILout_flag		char(1)
	,@save_domain			sysname
	,@save_BuildLabel		sysname
	,@save_CreateDate		datetime
	,@save_Request_start		datetime
	,@save_Request_Type		sysname
	,@save_Request_Status		sysname
	,@save_TargetSQLname		sysname
	,@save_port			sysname
	,@save_servername_port		sysname
	,@save_rq_stamp			sysname
	,@save_more_info		nvarchar(4000)
	,@db_query1			nvarchar(4000)
	,@db_query2			sysname
	,@returncode			int



DECLARE
	 @error_count			int
	,@detail_report			char(1)
	,@save_Status			sysname
	,@save_ModDate			datetime
	,@save_ca_id			int
	,@save_control_status		sysname
	,@save_control_process		sysname
	,@save_currpath			nvarchar(500)
	,@save_reverse			sysname


/*********************************************************************
 *                Initialization
 ********************************************************************/
Select @error_count = 0
Select @detail_report = 'n'
Select @save_DETAILout_flag = 'n'

Select @save_servername		= @@servername
Select @save_servername2	= @@servername

Select @charpos = charindex('\', @save_servername)
IF @charpos <> 0
   begin
	Select @save_servername = substring(@@servername, 1, (CHARINDEX('\', @@servername)-1))

	Select @save_servername2 = stuff(@save_servername2, @charpos, 1, '$')
   end



--  Create temp table
CREATE TABLE #temp_req_id ([request_id] [int] NOT NULL)


CREATE TABLE #temp_req ([Request_Type] [sysname] NULL ,
			[Request_Status] [sysname] NULL ,
			[BuildLabel] [sysname] NOT NULL ,
			[ProjectName] [sysname] NULL ,
			[ReleaseNum] [sysname] NULL ,
			[TargetSQLname] [sysname] NULL ,
			[DBname] [nvarchar] (500) NULL ,
			[BaseName] [sysname] NULL ,
			[Buildnum] [sysname] NULL ,
			[CreateDate] [datetime] NOT NULL ,
			[Request_start] [datetime] NULL,
			[Request_complete] [datetime] NULL,
			[Request_Notes] [nvarchar] (500) NULL
			)
			
			 


CREATE TABLE #temp_reqdet ([Status] [sysname] NULL,
			[DBname] [sysname] NULL,
			[seq_id] [int] NULL,
			[APPLname] [sysname] NULL,
			[SQLname] [sysname] NULL,
			[domain] [sysname] NULL,
			[BASEfolder] [sysname] NULL,
			[Process] [sysname] NULL,
			[ProcessType] [sysname] NULL,
			[ProcessDetail] [sysname] NULL,
			[ModDate] [datetime] NULL,
			[reqdet_id] [int] NULL,
			)

CREATE TABLE #temp_reqdet2 ([DBname] [sysname] NULL,
			[APPLname] [sysname] NULL
			)

CREATE TABLE #temp_reqdet3 (APPLname sysname
			    ,BASEfolder sysname
			    ,SQLname sysname
			    ,domain sysname)


--  Verify input parms
If @request_id is not null
   begin
	Select @detail_report = 'y'
	If not exists (select 1 from dbo.AHP_Import_Requests where request_id = @request_id)
	   begin
		Select @miscprint = 'DBA WARNING: Invalid request ID (input parm).  No rows for this request_id in the AHP_Import_Requests table.' 
		raiserror(@miscprint,-1,-1) with log
		Select @miscprint = '             This request ticket (#' + convert(nvarchar(20), @request_id) + ') has not been imported into the DEPLcontrol database.' 
		raiserror(@miscprint,-1,-1) with log
		Select @error_count = @error_count + 1
		goto label99
	   end
   end


----------------------  Print the headers  ----------------------
If @report_only = 'n'
   begin
	Print  '/*******************************************************************'
	Select @miscprint = '   SQL Automated Deployment Requests - Server: ' + @@servername
	Print  @miscprint
	If @detail_report = 'y'
	   begin
		Print  ' '
		Select @miscprint = '-- Request Detail for request_id: ' + convert(nvarchar(20), @request_id)
		Print  @miscprint
	   end
	Print  ' '
	Select @miscprint = '-- Report Generated on ' + convert(varchar(30),getdate())
	Print  @miscprint
	Print  '*******************************************************************/'
	raiserror('', -1,-1) with nowait
   end
Else
   begin
	Print  '/*******************************************************************'
	Select @miscprint = '-- Report Generated on ' + convert(varchar(30),getdate())
	Print  @miscprint
	Print  '*******************************************************************/'
	raiserror('', -1,-1) with nowait
   end
	

/****************************************************************
 *                MainLine
 ***************************************************************/


----------------------------------------------------------------------------------------------------------------------
--  Request Report Current section  ----------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
If @detail_report = 'n'
   begin
	Delete from #temp_req_id
   	Insert into #temp_req_id select distinct request_id
				from dbo.AHP_Import_Requests
				where request_status not like '%complete%' and request_status not like '%cancel%'

   	Insert into #temp_req_id select distinct request_id
				from dbo.control_ahp
				where status like 'in-work%'

				
	--Select * from #temp_req_id

	--  check for pending or active deployments
	If (select count(*) from #temp_req_id) = 0
	   begin
		Select @miscprint = 'No pending or active deployment requests found at this time.' 
		raiserror(@miscprint, -1,-1) with nowait
		goto label99
	   end
	   

	--  Print the report headers
	Select @miscprint = 'RequestID  Project/Release           Environment  Request Type  Build Label Requested                Status                Created Date/Time  Start Date/Time'
	Print @miscprint
	Select @miscprint = '=========  ========================  ===========  ============  ===================================  ====================  =================  ================'
	raiserror(@miscprint, -1,-1) with nowait
		
	start_reqid:
	
	Select @save_request_id = (select top 1 request_id from #temp_req_id order by request_id)

	Delete from #temp_req
	Insert into #temp_req select Request_Type
				    ,Request_Status
				    ,BuildLabel
				    ,ProjectName
				    ,ReleaseNum
				    ,TargetSQLname
				    ,DBname
				    ,BaseName
				    ,Buildnum
				    ,CreateDate
				    ,Request_start
				    ,Request_complete
				    ,Request_Notes
				from dbo.AHP_Import_Requests
				where request_id = @save_request_id and request_type <> 'handshake'
	--Select * from #temp_req


	Select @save_ProjectName = (select top 1 ProjectName from #temp_req)
	Select @save_ReleaseNum = (select top 1 ReleaseNum from #temp_req)
	Select @save_Project = rtrim(@save_ProjectName) + '_' + rtrim(@save_ReleaseNum)
	Select @save_SQLname = (select top 1 TargetSQLname from #temp_req)
	Select @save_Environment = (select top 1 SQLenv from dbacentral.dbo.dba_serverinfo where sqlname = @save_SQLname)
	If (select count(distinct Request_Type) from #temp_req) > 1
	   begin
		If (select count(*) from #temp_req where Request_Type = 'restore') = (select count(*) from #temp_req where Request_Type = 'deploy')
		   begin
			select @save_Request_Type = 'normal'
		   end
		Else
		   begin
			select @save_Request_Type = 'mixed'
		   end
	   end
	Else
	   begin
		select @save_Request_Type = (select top 1 Request_Type from #temp_req)
	   end
	Select @save_BuildLabel = (select top 1 BuildLabel from #temp_req)
	Select @save_CreateDate = (select top 1 CreateDate from #temp_req)
	Select @save_Request_start = (select top 1 Request_start from #temp_req where Request_start is not null)
	If @save_Request_start is not null
	   begin
		Select @save_Request_start_char = convert(char(16), @save_Request_start, 120)
	   end
	Else
	   begin
		Select @save_Request_start_char = '                '
	   end

	If exists (select 1 from #temp_req where Request_Status like '%in-work%')
	   begin
		Select @save_Status = (select top 1 Request_Status from #temp_req where Request_Status like '%in-work%')
	   end
	Else If exists (select 1 from #temp_req where Request_Status not like '%pending%')
	   begin
		Select @save_Status = (select top 1 Request_Status from #temp_req where Request_Status not like '%pending%')
	   end
	Else
	   begin
		Select @save_Status = (select top 1 Request_Status from #temp_req order by Request_Status)
	   end
	   
	If @save_Status like '%complete%' and exists (select 1 from dbo.control_ahp where request_id = @save_request_id and status not in ('completed', 'cancelled'))
	   begin
		Select @save_ca_id = (select top 1 ca_id from dbo.control_ahp where request_id = @save_request_id and status not in ('completed', 'cancelled') order by status)
		Select @save_control_status = (select status from dbo.control_ahp where ca_id = @save_ca_id)
		Select @save_control_process = (select process from dbo.control_ahp where ca_id = @save_ca_id)
		If @save_control_status like '%in-work%'
		   begin
			Select @save_Status = @save_control_process + ' in-work'
		   end
		Else
		   begin
			Select @save_Status = @save_control_process + ' ' + @save_control_status
		   end
	   end

	Select @miscprint = convert(char(9), @save_request_id) + '  ' 
			    + convert(char(24), @save_Project) + '  '
			    + convert(char(11), @save_Environment) + '  '
			    + convert(char(12), @save_Request_Type) + '  '
			    + convert(char(35), @save_BuildLabel) + '  '
			    + convert(char(20), @save_Status) + '  '
			    + convert(char(16), @save_CreateDate, 120) + '   '
			    + @save_Request_start_char
	raiserror(@miscprint, -1,-1) with nowait



	--  check for more rows to process
	delete from #temp_req_id where request_id = @save_request_id
	If (select count(*) from #temp_req_id) > 0
	   begin
		goto start_reqid
	   end

	   
   	goto label99

   end



----------------------------------------------------------------------------------------------------------------------
--  Request Detail Report section  -----------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
Select @save_DETAILout_flag = 'y'

--  Print the report headers
Select @miscprint = 'RequestID  Project/Release           Environment  Request Type  Build Label Requested                Status                Created Date/Time  Start Date/Time'
Print @miscprint
Select @miscprint = '=========  ========================  ===========  ============  ===================================  ====================  =================  ================'
raiserror(@miscprint, -1,-1) with nowait
		
Select @save_request_id = @request_id

Delete from #temp_req
Insert into #temp_req select Request_Type
			    ,Request_Status
			    ,BuildLabel
			    ,ProjectName
			    ,ReleaseNum
			    ,TargetSQLname
			    ,DBname
			    ,BaseName
			    ,Buildnum
			    ,CreateDate
			    ,Request_start
			    ,Request_complete
			    ,Request_Notes
			from dbo.AHP_Import_Requests
			where request_id = @save_request_id and request_type <> 'handshake'
--Select * from #temp_req


Select @save_ProjectName = (select top 1 ProjectName from #temp_req)
Select @save_ReleaseNum = (select top 1 ReleaseNum from #temp_req)
Select @save_Project = rtrim(@save_ProjectName) + '_' + rtrim(@save_ReleaseNum)
Select @save_SQLname = (select top 1 TargetSQLname from #temp_req)
Select @save_Environment = (select top 1 SQLenv from dbacentral.dbo.dba_serverinfo where sqlname = @save_SQLname)
If (select count(distinct Request_Type) from #temp_req) > 1
   begin
	select @save_Request_Type = 'mixed'
   end
Else
   begin
	select @save_Request_Type = (select top 1 Request_Type from #temp_req)
   end
Select @save_BuildLabel = (select top 1 BuildLabel from #temp_req)
Select @save_CreateDate = (select top 1 CreateDate from #temp_req)
Select @save_Request_start = (select top 1 Request_start from #temp_req where Request_start is not null)
If @save_Request_start is not null
   begin
	Select @save_Request_start_char = convert(char(16), @save_Request_start, 120)
   end
Else
   begin
	Select @save_Request_start_char = '                '
   end

If exists (select 1 from #temp_req where Request_Status like '%in-work%')
   begin
	Select @save_Status = (select top 1 Request_Status from #temp_req where Request_Status like '%in-work%')
   end
Else If exists (select 1 from #temp_req where Request_Status not like '%pending%')
   begin
	Select @save_Status = (select top 1 Request_Status from #temp_req where Request_Status not like '%pending%' order by Request_Status)
   end
Else
   begin
	Select @save_Status = (select top 1 Request_Status from #temp_req order by Request_Status)
   end
	


If @save_Status like '%complete%' and exists (select 1 from dbo.control_ahp where request_id = @save_request_id and status not in ('completed', 'cancelled'))
   begin
	Select @save_ca_id = (select top 1 ca_id from dbo.control_ahp where request_id = @save_request_id and status not in ('completed', 'cancelled') order by status)
	Select @save_control_status = (select status from dbo.control_ahp where ca_id = @save_ca_id)
	Select @save_control_process = (select process from dbo.control_ahp where ca_id = @save_ca_id)
	If @save_control_status like '%in-work%'
	   begin
		Select @save_Status = @save_control_process + ' in-work'
	   end
	Else
	   begin
		Select @save_Status = @save_control_process + ' ' + @save_control_status
	   end
   end


Select @miscprint = convert(char(9), @save_request_id) + '  ' 
		    + convert(char(24), @save_Project) + '  '
		    + convert(char(11), @save_Environment) + '  '
		    + convert(char(12), @save_Request_Type) + '  '
		    + convert(char(35), @save_BuildLabel) + '  '
		    + convert(char(20), @save_Status) + '  '
		    + convert(char(16), @save_CreateDate, 120) + '   '
		    + @save_Request_start_char
print @miscprint



--  Print the detail report headers
Print  ' '
Print  ' '
Select @miscprint = 'TargetSQLname              Appl    DBname                       Request Type  Process Detail                       Status                Domain      Last Mod Date'
Print  @miscprint
Select @miscprint = '=========================  ======  ===========================  ============  ===================================  ====================  ==========  ================'
raiserror(@miscprint, -1,-1) with nowait

loop_TargetSQLname:
Select @save_TargetSQLname = (select top 1 TargetSQLname from #temp_req order by TargetSQLname)

loop_detail:
Select @save_DBname = (select top 1 t.DBname from #temp_req t, dbo.db_sequence s where t.DBname = s.DBname and t.TargetSQLname = @save_TargetSQLname order by s.seq_id)
Select @save_APPLname = (select top 1 BaseName from #temp_req where TargetSQLname = @save_TargetSQLname and DBname = @save_DBname)
If (select count(*) from #temp_req where TargetSQLname = @save_TargetSQLname and DBname = @save_DBname and Request_Type in ('restore', 'deploy')) > 1
   begin
	Select @save_Request_Type = 'normal'
   end
Else
   begin
	Select @save_Request_Type = (select top 1 Request_Type from #temp_req where TargetSQLname = @save_TargetSQLname and DBname = @save_DBname)
   end
Select @save_BuildLabel = (select top 1 ProcessDetail from dbo.control_ahp where request_id = @save_request_id and TargetSQLname = @save_TargetSQLname and DBname = @save_DBname order by moddate desc)
If @save_BuildLabel is null
   begin
	Select @save_BuildLabel = ''
   end
Select @save_Request_Status = (select top 1 Request_Status from #temp_req where TargetSQLname = @save_TargetSQLname and DBname = @save_DBname order by Request_Status)
Select @save_domain = (select top 1 DomainName from dbacentral.dbo.dba_serverinfo where SQLname = @save_TargetSQLname)
If exists (select 1 from dbo.control_ahp where request_id = @save_request_id and TargetSQLname = @save_TargetSQLname and DBname = @save_DBname)
   begin
	Select @save_ModDate = (select top 1 ModDate from dbo.control_ahp where request_id = @save_request_id and TargetSQLname = @save_TargetSQLname and DBname = @save_DBname)
   end
Else If (select top 1 Request_start from #temp_req where TargetSQLname = @save_TargetSQLname and DBname = @save_DBname) is not null
   begin
	Select @save_ModDate = (select top 1 Request_start from #temp_req where TargetSQLname = @save_TargetSQLname and DBname = @save_DBname)
   end
Else
   begin
	Select @save_ModDate = (select top 1 CreateDate from #temp_req where TargetSQLname = @save_TargetSQLname and DBname = @save_DBname)
   end



If @save_Request_Status like '%restore%' and @save_ModDate < getdate()-.0035  --5 min
   begin
	If not exists (Select 1 from dbo.control_ahp where request_id = @save_request_id and TargetSQLname = @save_TargetSQLname and DBname = @save_DBname and status = 'in-work_01_04')
	   begin
		goto skip_restore_pct
	   end	
	
	Select @save_port = (select top 1 port from dbaadmin.dbo.dba_serverinfo where sqlname = @@servername)
	Select @save_servername_port = @@servername
	If @save_port is not null
	   begin
		Select @save_servername_port = @save_servername_port + ',' + @save_port
	   end
	Select @save_rq_stamp = convert(sysname, getdate(), 121) + convert(nvarchar(40), newid())
	Select @db_query1 = 'Select top 1 percent_complete from master.sys.dm_exec_requests where command like ''''%restore%'''' order by start_time'
	Select @db_query2 = ''
	select @query = 'exec DEPLinfo.dbo.dpsp_auto_pong_to_control @rq_servername = ''' + @save_servername_port 
		    + ''', @rq_stamp = ''' + @save_rq_stamp 
		    + ''', @rq_type = ''db_query'', @rq_detail01 = ''' + @db_query1 + ''', @rq_detail02 = ''' + @db_query2 + ''''
	Select @cmd = 'sqlcmd -S' + @save_SQLname + ' -E -Q"' + @query + '"'
	--print @cmd

	EXEC @returncode = master.sys.xp_cmdshell @cmd, no_output

	Waitfor delay '00:00:05'
	If exists (select 1 from DEPLcontrol.dbo.pong_return where pong_stamp = @save_rq_stamp)
	   begin
		Select @save_more_info = (select pong_detail01 from dbo.pong_return where pong_stamp = @save_rq_stamp)
	   end	
	   
	If @save_more_info is not null and @save_more_info <> ''
	   begin
	   	Select @charpos = charindex('.', @save_more_info)
		IF @charpos <> 0
		   begin
			Select @save_more_info = substring(@save_more_info, 1, @charpos-1)
		   end

		If @save_Request_Status like '%[%]%'
		   begin
			Select @save_reverse = REVERSE(@save_Request_Status)
		   	Select @charpos = charindex(' ', @save_reverse)
			IF @charpos <> 0
			   begin
				Select @save_reverse = substring(@save_reverse, @charpos+1, len(@save_reverse)-@charpos)
			   end
			Select @save_Request_Status = REVERSE(@save_reverse) + ' ' + @save_more_info + '%' 
		   end
		Else
		   begin
			Select @save_Request_Status = @save_Request_Status + ' ' + @save_more_info + '%'
		   end

	   	update dbo.control_ahp set ProcessDetail = @save_Request_Status, ModDate = getdate() where request_id = @save_request_id and TargetSQLname = @save_TargetSQLname and DBname = @save_DBname
	   	update dbo.AHP_Import_Requests set Request_Status = @save_Request_Status where request_id = @save_request_id and TargetSQLname = @save_TargetSQLname and DBname = @save_DBname
	   end  
   end
skip_restore_pct:


Select @miscprint = convert(char(25), @save_TargetSQLname) + '  ' 
		    + convert(char(6), @save_APPLname) + '  '
		    + convert(char(27), @save_DBname) + '  '
		    + convert(char(12), @save_Request_Type) + '  '
		    + convert(char(35), @save_BuildLabel) + '  '
		    + convert(char(20), @save_Request_Status) + '  '
		    + convert(char(10), @save_domain) + '  '
		    + convert(char(16), @save_ModDate, 20)
Print @miscprint



--  Check for more rows to process
Delete from #temp_req where TargetSQLname = @save_TargetSQLname and DBname = @save_DBname
If exists (select 1 from #temp_req where TargetSQLname = @save_TargetSQLname)
   begin
	goto loop_detail
   end
Else If (select count(*) from #temp_req) > 0
   begin
	Print  ' '
	goto loop_TargetSQLname
   end


--  Create outpt file for completed requests
If @request_id is not null
   begin
	select @save_currpath = '\\' + @save_servername + '\' + @save_servername + '_builds\VSTS_Source\AHP_Deployments\' + convert(sysname, @request_id) + '_request_completed.txt'
	Select @cmd = 'DIR ' + @save_currpath
	EXEC @return_status = master.sys.xp_cmdshell @cmd, no_output
	If @return_status = 1
	   begin
		Select @cmd = 'copy nul \\' + @save_servername + '\' + @save_servername + '_builds\VSTS_Source\AHP_Deployments\' + convert(sysname, @request_id) + '_request_completed.txt'
		EXEC master.sys.xp_cmdshell @cmd, no_output
	   end
   end
   
   
If @request_id is not null and @save_Status like '%complete%'
   begin
	return 0
   end
Else
   begin
	return 1
   end


-----------------  Finalizations  ------------------

label99:

drop table #temp_req_id
drop table #temp_req
drop table #temp_reqdet
drop table #temp_reqdet2
drop table #temp_reqdet3


If @report_only = 'n' and @request_id is null
   begin
	If @save_request_id is null
	   begin
		Select @save_request_id = 12345
	   end

	Print  ' '
	Print  ' '
	Print  ' '
	Select @miscprint = '--------------------------------------------------'
	Print  @miscprint
	Select @miscprint = '--Here are sample execute commands for this sproc:'
	Print  @miscprint
	Select @miscprint = '--------------------------------------------------'
	Print  @miscprint
	Print  ' '
	Select @miscprint = '--Report Status for a speicif request ID:'
	Print  @miscprint
	Select @miscprint = 'exec DEPLcontrol.dbo.dpsp_ahp_Status @request_id = ' + convert(char(7), @save_request_id) + ' -- The request_id value must exist in the dbo.AHP_Import_Requests table'
	Print  @miscprint
	Print  ' '
   end









GO
