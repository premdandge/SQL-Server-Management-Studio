USE [DEPLcontrol]
GO
/****** Object:  StoredProcedure [dbo].[dpsp_email_errors]    Script Date: 10/4/2013 11:02:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [dbo].[dpsp_email_errors] (@GetBuildDiff_path sysname = null)

/*********************************************************
 **  Stored Procedure dpsp_email_errors                  
 **  Written by Jim Wilson, Getty Images                
 **  October 07, 2009                                      
 **  
 **  This sproc will create and send emails related to SQL deployment
 **  errors.  This process will compare TFS check-in information
 **  related to the current build number and the last-good build number
 **  to determine the email recipients.
 **
 **  Input Parm(s);
 **  @GetBuildDiff_path - is the path to GetBuildDiff.exe
 **
 ***************************************************************/
  as
set nocount on

--	======================================================================================
--	Revision History
--	Date		Author     		Desc
--	==========	====================	=============================================
--	10/07/2009	Jim Wilson		New process.
--	10/15/2009	Jim Wilson		Fix issue with delete from #TFS_results
--	11/09/2009	Jim Wilson		added gears_id < @save_gears_id to last good build query
--	11/23/2009	Jim Wilson		added top 1 to query for @save_changeset
--	12/17/2009	Jim Wilson		added @CC AppDevManagers@gettyimages.com
--	03/04/2010	Jim Wilson		changed for @CC Let'sFixIt@gettyimages.com
--	======================================================================================


/***
Declare @GetBuildDiff_path sysname

Select @GetBuildDiff_path = 'C:\TFSbuildinfo'
--***/

-----------------  declares  ------------------

DECLARE
	 @miscprint			nvarchar(2000)
	,@cmd				nvarchar(4000)
	,@charpos			int
	,@update_flag			char(1)
	,@save_start_d			nvarchar(50)
	,@save_start_t			nvarchar(50)
	,@save_start_date		datetime
	,@save_ee_id			int
	,@save_gears_id			int
	,@save_SQLname			sysname
	,@save_BuildLabel		sysname 
	,@save_BuildLabel_mask		sysname
	,@save_lastgood_BuildLabel	sysname
	,@save_projectname		sysname
	,@save_projectver		sysname
	,@save_project_mask		sysname
	,@save_ptx_id			int
	,@save_TFSservername		sysname
	,@save_TFSteamproject		sysname
	,@save_TFSdatabasepath		nvarchar(500)
	,@ps_flag			char(1)
	,@changeset_flag		char(1)
	,@save_ti_id			int
	,@save_text01			nvarchar(500)
	,@save_changeset		sysname
	,@save_DEVname			sysname

DECLARE
	 @save_subject			sysname
	,@save_dplogx_id		int
	,@save_dbname			sysname
	,@save_foldername		sysname
	,@save_SQLscript		nvarchar(500)
	,@save_dbname_mask		sysname
	,@save_foldername_mask		sysname
	,@save_SQLscript_mask		nvarchar(500)
	,@recipient			sysname
	,@cc_recipients			sysname
	,@message			nvarchar(4000)
	,@save_SQLservername		sysname
	,@save_project			sysname
	,@save_environment		sysname



/*********************************************************************
 *                Initialization
 ********************************************************************/



--  Create temp tables
create table #TFS_Info(ti_id [int] IDENTITY (1, 1) NOT NULL
			,text01 nvarchar(500) null
			)

create table #TFS_results (changeset sysname NOT NULL
			,DEVname sysname NOT NULL
			,SQLscript nvarchar(500) null
			)


create table #TFS_DEPLexp (dplogx_id int NOT NULL
			,dbname sysname NOT NULL
			,foldername sysname NOT NULL
			,SQLscript nvarchar(500) null
			)





--  Check to see if we have rows to process
If (select count(*) from dbo.email_errors where status = 'pending') = 0
   begin
	Print 'No Email Error requests to process'
	goto label99
   end 




/****************************************************************
 *                MainLine
 ***************************************************************/

Start01:

Select @ps_flag = 'n'


--  Get the next email request
Select @save_ee_id = (select top 1 ee_id from dbo.email_errors where status = 'pending' order by ee_id)
Select @save_gears_id = (select gears_id from dbo.email_errors where ee_id = @save_ee_id)
Select @save_SQLname = (select SQLname from dbo.email_errors where ee_id = @save_ee_id)


--  Make sure we have errors for this request in the dbo.DEPL_exceptions table
If not exists (select 1 from dbo.DEPL_exceptions where gears_id = @save_gears_id and servername = @save_SQLname and status = 
'failed')
   begin
	Print ''
	Print 'No errors were found for Gears_ID ' + convert(nvarchar(20), @save_gears_id) + ' and SQLname ' + @save_SQLname 
+ '.  No email was sent.'
	Update dbo.email_errors set status = 'no_email' where ee_id = @save_ee_id
	goto skip01
   end
Else
   begin
	Select @save_BuildLabel = (select top 1 BuildLabel from dbo.DEPL_exceptions where gears_id = @save_gears_id order by 
dplogx_id)

	--  Remove the project version at the start of the build label if it is there
	If (select isnumeric(left(@save_BuildLabel, 1))) = 1
	   begin
		Select @charpos = charindex('_', @save_BuildLabel)
		IF @charpos <> 0
		   begin
			Select @save_BuildLabel = substring(@save_BuildLabel, @charpos+1, 200)
		   end
	   end


	Select @save_BuildLabel_mask = '%' + @save_BuildLabel + '%'

	If @save_BuildLabel like '%/_ps/_%' escape '/'
	   begin
		Select @ps_flag = 'y'
	   end

	insert into #TFS_DEPLexp select dplogx_id, dbname, foldername, scriptname from dbo.DEPL_exceptions 
										where gears_id = @save_gears_id 
										and servername = @save_SQLname 
										and status = 'failed'
   end




--  We have error related to this request.  Get the last good build number for this project and SQLname
Select @save_projectname = (select top 1 projectname from dbo.DEPL_exceptions where gears_id = @save_gears_id and servername 
= @save_SQLname and status = 'failed' order by dplogx_id)
Select @save_projectver = (select top 1 projectver from dbo.DEPL_exceptions where gears_id = @save_gears_id and servername = 
@save_SQLname and status = 'failed' order by dplogx_id)
Select @save_project_mask = '%' + @save_projectname + '_' + @save_projectver + '%'


If exists (select 1 from dbo.Build_Central
		where sqlname = @save_SQLname
		and gears_id not in (select gears_id from dbo.Build_Central where sqlname = @save_SQLname and BuildNotes like 
'%ERRORS%' and BuildNotes like @save_project_mask) 
		and buildnotes like @save_project_mask)
   begin
	Select @save_lastgood_BuildLabel = (Select top 1 BuildLabel from dbo.Build_Central
								where sqlname = @save_SQLname
								and gears_id not in (select gears_id from dbo.Build_Central 
												where sqlname = @save_SQLname 
												and BuildNotes like '%
ERRORS%' 
												and BuildNotes like 
@save_project_mask) 
								and buildnotes like @save_project_mask
								and gears_id < @save_gears_id
								order by bc_id desc)


	--  Remove the project version at the start of the build label if it is there
	If (select isnumeric(left(@save_lastgood_BuildLabel, 1))) = 1
	   begin
		Select @charpos = charindex('_', @save_lastgood_BuildLabel)
		IF @charpos <> 0
		   begin
			Select @save_lastgood_BuildLabel = substring(@save_lastgood_BuildLabel, @charpos+1, 200)
		   end
	   end


	-- Go get the TFS info related to the build numbers
	If @ps_flag = 'y'
	   begin
		Select @save_ptx_id = (select ptx_id from dbo.Project_TFS_xref 
						where active = 'y' 
						and Projectname = @save_projectname
						and Projectver = @save_projectver
						and Projectcodeline = 'ps')
	   end
	Else
	   begin
		Select @save_ptx_id = (select ptx_id from dbo.Project_TFS_xref 
						where active = 'y' 
						and Projectname = @save_projectname
						and Projectver = @save_projectver
						and Projectcodeline = 'main')
	   end

	Select @save_TFSservername = (select TFSservername from dbo.Project_TFS_xref where ptx_id = @save_ptx_id)
	Select @save_TFSteamproject = (select TFSteamproject from dbo.Project_TFS_xref where ptx_id = @save_ptx_id)
	Select @save_TFSdatabasepath = (select TFSdatabasepath from dbo.Project_TFS_xref where ptx_id = @save_ptx_id)

	Select @cmd = @GetBuildDiff_path + '\GetBuildDiff.exe /server' + @save_TFSservername 
					+ ' /teamProject ' + @save_TFSteamproject 
					+ ' /databasePath ' + @save_TFSdatabasepath   
					+ ' /cd ' + @save_BuildLabel  

	If @save_lastgood_BuildLabel is not null and @save_lastgood_BuildLabel <> ''
	   begin
		Select @cmd = @cmd + ' /lgd ' + @save_lastgood_BuildLabel
	   end

	Print @cmd 
	insert into #TFS_Info (text01) exec master.sys.xp_cmdshell @cmd
	--select * from #TFS_Info


	If (select count(*) from #TFS_Info where text01 is not null) = 0
	   begin
		Print ''
		Print 'No results from TFS for build ' + @save_BuildLabel + '. No email was sent.'
		Update dbo.email_errors set status = 'no_TFSinfo' where ee_id = @save_ee_id
		goto skip01
	   end


	--  Process the data into the second temp table
	Select @save_changeset = ''
	Select @save_DEVname = ''

	Select @save_ti_id = (select top 1 ti_id from #TFS_Info where text01 is null order by ti_id)
	Delete from #TFS_Info where ti_id <= @save_ti_id
	--select * from #TFS_Info

	start_results_01:

	Select @save_ti_id = (select top 1 ti_id from #TFS_Info order by ti_id)
	Select @save_text01 = (select text01 from #TFS_Info where ti_id = @save_ti_id)

	--  check for null row
    	If @save_text01 is null
	   begin
		Select @save_changeset = ''
		Select @save_DEVname = ''

		delete from #TFS_Info where ti_id = @save_ti_id

		goto skip_results
	   end

	--  check for SQL script row (insert data into the second temp table here)
    	If @save_text01 like '$/%' and @save_changeset <> '' and @save_DEVname <> ''
	   begin
		Insert into #TFS_results values (@save_changeset, @save_DEVname, @save_text01)

		delete from #TFS_Info where ti_id = @save_ti_id

		goto skip_results
	   end
	--  check for DEV names (email addresses)
	Else If @save_text01 like '%@%'
	   begin
		Select @save_DEVname = @save_text01

		delete from #TFS_Info where ti_id = @save_ti_id

		goto skip_results
	   end
	--  get the change set number here
	Else
	   begin
		Select @save_changeset = @save_text01

		delete from #TFS_Info where ti_id = @save_ti_id

		goto skip_results
	   end


	skip_results:
	If (select count(*) from #TFS_Info where text01 is not null) > 0
	   begin
		goto start_results_01
	   end
   end


--  One last check to make sure we have data to work with
If (select count(*) from #TFS_results) = 0 or (select count(*) from #TFS_DEPLexp) = 0
   begin
	Print ''
	Print 'No results from TFS andor DEPL_exceptions for build ' + @save_BuildLabel + '. No email was sent.'
	Update dbo.email_errors set status = 'no_TFSinfo' where ee_id = @save_ee_id
	goto skip01
   end

--select * from #TFS_results



--  Start formatting the email message and recipients
Select @save_subject = 'DEPLOYMENT FAILURE (SQL): Server ' + @save_SQLname + ' for BUILD ' + @save_BuildLabel
Select @recipient = ''
Select @message = 'Deployment Failures for SQL instance: ' + @save_SQLname + char(13)+char(10)
Select @message = @message + char(13)+char(10)
Select @message = @message + 'BUILD: ' + + @save_BuildLabel + char(13)+char(10)
Select @message = @message + 'Gears Ticket: ' + convert(nvarchar(20), @save_gears_id) + char(13)+char(10)

Select @save_SQLservername = @save_SQLname
Select @charpos = charindex('\', @save_SQLservername)
IF @charpos <> 0
   begin
	Select @save_SQLservername = substring(@save_SQLservername, 1, (CHARINDEX('\', @save_SQLservername)-1))
   end

Select @message = @message + 'Deployment Logs: \\' + @save_SQLservername + '\' + @save_SQLservername + 
'_builds\deployment_logs' + char(13)+char(10)
Select @message = @message + char(13)+char(10)
Select @message = @message + char(13)+char(10)


start_email:
Select @save_dplogx_id = (select top 1 dplogx_id from #TFS_DEPLexp order by dplogx_id)
Select @save_dbname = (select dbname from #TFS_DEPLexp where dplogx_id = @save_dplogx_id)
Select @save_foldername = (select foldername from #TFS_DEPLexp where dplogx_id = @save_dplogx_id)
Select @save_foldername = replace(@save_foldername, '\', '')
Select @save_SQLscript = (select SQLscript from #TFS_DEPLexp where dplogx_id = @save_dplogx_id)

Select @save_dbname_mask = '%' + @save_dbname + '%'
Select @save_foldername_mask = '%' + @save_foldername + '%'
Select @save_SQLscript_mask = '%' + @save_SQLscript + '%'

Select @message = @message + 'SCRIPT: ' + @save_dbname + '/' + @save_foldername + '/' + @save_SQLscript + char(13)+char(10)
Select @message = @message + 'changeset                 DEVname' + char(13)+char(10)


start_email_sub02:
Select @save_changeset = (select top 1 changeset from #TFS_results where SQLscript like @save_dbname_mask and SQLscript like 
@save_foldername_mask and SQLscript like @save_SQLscript_mask order by changeset)
Select @save_DEVname = (select DEVname from #TFS_results where changeset = @save_changeset and SQLscript like 
@save_dbname_mask and SQLscript like @save_foldername_mask and SQLscript like @save_SQLscript_mask)

If (@save_changeset = '' or @save_changeset is null) or (@save_DEVname = '' or @save_DEVname is null)
   begin
	Select @message = @message + 'Data not available'
   end
Else
   begin
	Select @message = @message + convert(char(20), @save_changeset) + '      ' + convert(char(60), @save_DEVname) + char
(13)+char(10)
   end

If @recipient not like '%' + @save_DEVname + '%'
   begin
	Select @recipient = @recipient + @save_DEVname + ';'
   end

Delete from #TFS_results where changeset = @save_changeset and SQLscript like @save_dbname_mask and SQLscript like 
@save_foldername_mask and SQLscript like @save_SQLscript_mask

If exists (select 1 from #TFS_results where changeset = @save_changeset and SQLscript like @save_dbname_mask and SQLscript 
like @save_foldername_mask and SQLscript like @save_SQLscript_mask)
   begin
	goto start_email_sub02
   end

Select @message = @message + char(13)+char(10)



--  Check for more failed scripts to report
Delete from #TFS_DEPLexp where dplogx_id = @save_dplogx_id
If (select count(*) from #TFS_DEPLexp) > 0
   begin
	goto start_email
  end



If @recipient like '%;'
   begin
	Select @recipient = substring(@recipient, 1, len(@recipient)-1)
   end


Select @save_project = (select p.project_name from Gears.dbo.PROJECTS p, Gears.dbo.BUILD_REQUESTS br
						where p.project_id = br.project_id
						and br.build_request_id = @save_gears_id)

Select @save_environment = (select e.environment_name from Gears.dbo.ENVIRONMENT e, Gears.dbo.BUILD_REQUESTS br
						where e.environment_id = br.environment_id
						and br.build_request_id = @save_gears_id)



If exists (select 1 from DEPLinfo.dbo.sendmail_dist_list where projectid = @save_project and env_name = @save_environment and 
success_flag = 'n')
   begin
	Select @cc_recipients = (select recipients from DEPLinfo.dbo.sendmail_dist_list where projectid = @save_project and 
env_name = @save_environment and success_flag = 'n')
   end
Else
   begin
	Select @cc_recipients = (select recipients from DEPLinfo.dbo.sendmail_dist_list where projectid = 'OTHER' and 
env_name = 'ALL' and success_flag = 'n')
   end

Select @cc_recipients = @cc_recipients + ';tssqldba@gettyimages.com'

If @cc_recipients not like '%FixIt%'
   begin
	Select @cc_recipients = @cc_recipients + ';Let''''sFixIt@gettyimages.com'
   end


print 'Sending email subject: ' + @save_subject
print ''

print 'Sending email message: ' + @message
print ''


EXEC dbaadmin.dbo.dbasp_sendmail 
	--@recipients = 'jim.wilson@gettyimages.com',  
	@recipients = @recipient,
	@copy_recipients = @cc_recipients,
	@subject = @save_subject,
	@message = @message



Update dbo.email_errors set status = 'email_sent' where ee_id = @save_ee_id


skip01:

If (select count(*) from dbo.email_errors where status = 'pending') > 0
   begin
	goto Start01
   end 




-----------------  Finalizations  ------------------

label99:

drop table #TFS_Info
drop table #TFS_results
drop table #TFS_DEPLexp











GO
