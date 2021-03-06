USE [DEPLcontrol]
GO
/****** Object:  StoredProcedure [dbo].[dpsp_Update]    Script Date: 10/4/2013 11:02:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[dpsp_Update] (@gears_id int = null
				,@detail_id int = null
				,@DBname sysname = null
				,@status sysname = null
				,@start_dt sysname = null
				,@ProcessType sysname = null
				,@SQLname sysname = null
				,@domain sysname = null
				,@BASEfolder sysname = null
				,@update_all_forSQLname char(1) = 'n')

/*********************************************************
 **  Stored Procedure dpsp_Update                  
 **  Written by Jim Wilson, Getty Images                
 **  December 01, 2008                                      
 **  
 **  This sproc will update specific Gears request info as needed
 **  prior to SQL deployment processing.
 **
 **  Input Parm(s);
 **  @gears_id - is the Gears ID for a specific request
 **
 **  @detail_id - is the detail ID associated with a component
 **               of the Gears request (from the dpsp_status output)
 **
 **  @DBname - is the DB name related to the detail ID (to cross check the update request)
 **
 ***************************************************************/
  as
set nocount on

--	======================================================================================
--	Revision History
--	Date		Author     		Desc
--	==========	====================	=============================================
--	12/01/2008	Jim Wilson		New process.
--	01/28/2009	Jim Wilson		Added code for domain.
--	03/11/2009	Jim Wilson		New code for update for all SQLnames related to a gears_id.
--	03/19/2009	Jim Wilson		Update gears request for date and time changes.
--	======================================================================================


/***
Declare @gears_id int
Declare @detail_id int
Declare @DBname sysname
Declare @status sysname
Declare @start_dt sysname
Declare @ProcessType sysname
Declare @SQLname sysname
Declare @domain sysname
Declare @BASEfolder sysname
Declare @update_all_forSQLname char(1)

Select @gears_id = 33851
--Select @detail_id = 379
--Select @DBname = 'Bundle'
--Select @status = 'cancelled'
Select @start_dt = '20090401 09:00'
--Select @ProcessType = 'Override_Needed' --'DBA-ok' --'Override_Needed'
--Select @ProcessType = 'JobRestore-n' --'JobRestore-y'
--Select @SQLname = 'ASPSQLTEST01\A'
--Select @domain = 'AMERx'
--Select @BASEfolder = 'BNDL'
Select @update_all_forSQLname = 'n'
--***/

-----------------  declares  ------------------

DECLARE
	 @miscprint			nvarchar(2000)
	,@charpos			int
	,@update_flag			char(1)
	,@save_start_d			nvarchar(50)
	,@save_start_t			nvarchar(50)
	,@save_start_date		datetime

/*********************************************************************
 *                Initialization
 ********************************************************************/
Select @update_flag = 'n'

IF @detail_id is null
   begin
	Select @detail_id = 0
   end



----------------------  Print the headers  ----------------------

Print  '/*******************************************************************'
Select @miscprint = '   SQL Automated Deployment Requests - Server: ' + @@servername
Print  @miscprint
Print  ' '
Select @miscprint = '-- Gears Request Update Process '
Print  @miscprint
Print  '*******************************************************************/'
Print  ' '


--  Verify input parms
If @detail_id <> 0 and @start_dt is not null
   begin
	Select @miscprint = 'DBA WARNING: Invalid input parms.  Cannot process a change to Start Date when a detail_id is specified.' 
	Print  @miscprint
	Print ''
	goto label99
   end

If @gears_id is not null
   begin
	If not exists (select 1 from dbo.request where gears_id = @gears_id)
	   begin
		Select @miscprint = 'DBA WARNING: Invalid input for parm @gears_id (' + convert(nvarchar(20), @gears_id) + ').  No rows for this gears_id in the Request table.' 
		Print  @miscprint
		Print ''
		goto label99
	   end
   end

If @detail_id <> 0
   begin
	If not exists (select 1 from dbo.request_detail where reqdet_id = @detail_id)
	   begin
		Select @miscprint = 'DBA WARNING: Invalid input for parm @detail_id (' + convert(nvarchar(20), @detail_id) + ').  No rows for this @detail_id in the Request_detail table.' 
		Print  @miscprint
		Print ''
		goto label99
	   end
   end

If @update_all_forSQLname = 'y' and @SQLname is null
   begin
	Select @miscprint = 'DBA WARNING: Invalid input parms.  If @update_all_forSQLname = ''y'', @SQLname must be specified.' 
	Print  @miscprint
	Print ''
	goto label99
   end


	


/****************************************************************
 *                MainLine
 ***************************************************************/

----------------------------------------------------------------------------------------------------------------------
--  Section for no input parms  --------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
If @gears_id is null
   begin
	Select @miscprint = 'UPDATE: No Gears ID specified.' 
	Print  @miscprint
	Print ''

	goto label99
   end



----------------------------------------------------------------------------------------------------------------------
--  Section for specific Gears requests  -----------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
--  No changes specified 
If @status is null and @start_dt is null and @detail_id = 0 and @update_all_forSQLname = 'n'
   begin
	Select @miscprint = 'UPDATE: No update requested for Gears ID ' + convert(nvarchar(20), @gears_id) + '.' 
	Print  @miscprint
	Print ''

	goto label99
   end


If @update_all_forSQLname = 'y'
   begin
	goto skip_non_detail
   end


--  Non-detail changes 
If @detail_id = 0 
   begin
	If @status is not null and @status in ('pending', 'cancelled', 'complete', 'completed', 'Gears Completed', 'in-work')
	   begin
		Select @miscprint = 'UPDATE: update dbo.Request set Status = ''' + @status + ''' where Gears_id = ' + convert(nvarchar(20), @gears_id) 
		Print  @miscprint
		Print ''

		update dbo.Request set Status = @status where Gears_id = @gears_id

		Select @miscprint = 'UPDATE: update dbo.Request_detail set Status = ''' + @status + ''' where Gears_id = ' + convert(nvarchar(20), @gears_id)
		Print  @miscprint
		Print ''

		update dbo.Request_detail set Status = @status where Gears_id = @gears_id

		Select @update_flag = 'y'
	   end
	Else
	   begin
		Select @miscprint = 'DBA WARNING: Invalid input parm @status (' + @status + ').  Must be ''pending'', ''cancelled'', ''completed'' or ''in-work''.' 
		Print  @miscprint
		Print ''
	   end


	If @start_dt is not null
	   begin
		Select @charpos = charindex(' ', @start_dt)
		IF @charpos <> 0
		   begin
			Select @save_start_d = substring(@start_dt, 1, @charpos-1)
			Select @save_start_d = rtrim(@save_start_d)
			Select @save_start_date = convert(datetime, @save_start_d)

			Select @save_start_t = substring(@start_dt, @charpos+1, 50)
			Select @save_start_t = rtrim(ltrim(@save_start_t))

			Select @miscprint = 'UPDATE: update dbo.Request set StartDate = ''' + convert(nvarchar(20), @save_start_date, 112) + ''', StartTime = ''' + @save_start_t + ''' where Gears_id = ' + convert(nvarchar(20), @gears_id) 
			Print  @miscprint
			Print ''

			update dbo.Request set StartDate = @save_start_date, StartTime = @save_start_t where Gears_id = @gears_id
			Select @update_flag = 'y'

			If DATABASEPROPERTYEX ('Gears','status') = 'ONLINE'
			   begin
				update gears.dbo.BUILD_REQUESTS set target_date = @save_start_date, target_time = @save_start_t where build_request_id = @gears_id
			   end
		   end
		Else
		   begin
			Select @miscprint = 'DBA WARNING: Invalid input parm (@start_dt).  Must be formatted like ''20090317 09:38''.' 
			Print  @miscprint
			Print ''
		   end
	   end


	goto label99

   end


skip_non_detail:


--  Detail Changes start here

--  Make sure the detail ID is part of the Gears request.
If not exists (select 1 from dbo.Request_detail where Gears_id = @gears_id and reqdet_id = @detail_id) and @update_all_forSQLname = 'n'
   begin
	Select @miscprint = 'DBA WARNING: Invalid input parm for @detail_id (' + convert(nvarchar(20), @detail_id) + ').  This ID is not related to the requested Gears ID (' + convert(nvarchar(20), @gears_id) + ').' 
	Print  @miscprint
	Print ''

	goto label99
   end

If @DBname is null and @status is null and @ProcessType is null and @SQLname is null and @BASEfolder is null and @domain is null and @update_all_forSQLname = 'n'
   begin
	Select @miscprint = 'DBA WARNING: No Detail Updates requested for Gears ID (' + convert(nvarchar(20), @gears_id) + ') / Detail ID (' + convert(nvarchar(20), @detail_id) + ').'
	Print  @miscprint
	Print ''

	goto label99
   end

If @DBname is null and @status is null and @ProcessType is null and @BASEfolder is null and @domain is null and @update_all_forSQLname = 'y'
   begin
	Select @miscprint = 'DBA WARNING: No Detail Updates for SQLname ''' + @SQLname + ''' requested for Gears ID (' + convert(nvarchar(20), @gears_id) + ').'
	Print  @miscprint
	Print ''

	goto label99
   end


--  Detail status change
If @status is not null and @status in ('pending', 'cancelled', 'complete', 'completed', 'Gears Completed', 'in-work') and @update_all_forSQLname = 'n'
   begin
	Select @miscprint = 'UPDATE: update dbo.Request_detail set Status = ''' + @status + ''' where Gears_id = ' + convert(nvarchar(20), @gears_id) + ' and reqdet_id = ' + convert(nvarchar(20), @detail_id)
	Print  @miscprint
	Print ''

	update dbo.Request_detail set Status = @status where Gears_id = @gears_id and reqdet_id = @detail_id
	Select @update_flag = 'y'
   end
Else If @status is not null and @status in ('pending', 'cancelled', 'complete', 'completed', 'Gears Completed', 'in-work') and @update_all_forSQLname = 'y'
   begin
	Select @miscprint = 'UPDATE: update dbo.Request_detail set Status = ''' + @status + ''' where Gears_id = ' + convert(nvarchar(20), @gears_id) + ' and SQLname = ''' + rtrim(@SQLname) + ''''
	Print  @miscprint
	Print ''

	update dbo.Request_detail set Status = @status where Gears_id = @gears_id and SQLname = @SQLname
	Select @update_flag = 'y'
   end
Else If @status is not null
   begin
	Select @miscprint = 'DBA WARNING: Invalid input parm @status (' + @status + ').  Must be ''pending'', ''cancelled'', ''completed'' or ''in-work''.' 
	Print  @miscprint
	Print ''
   end


--  Detail ProcessType change
If @ProcessType is not null and @ProcessType in ('', 'full', 'sprocs_only', 'Override_Needed', 'DBA-ok', 'DBA-cancelled', 'JobRestore-y', 'JobRestore-n') and @update_all_forSQLname = 'n'
   begin
	Select @miscprint = 'UPDATE: update dbo.Request_detail set ProcessType = ''' + @ProcessType + ''' where Gears_id = ' + convert(nvarchar(20), @gears_id) + ' and reqdet_id = ' + convert(nvarchar(20), @detail_id)
	Print  @miscprint
	Print ''

	update dbo.Request_detail set ProcessType = @ProcessType where Gears_id = @gears_id and reqdet_id = @detail_id
	Select @update_flag = 'y'
   end
Else If @ProcessType is not null and @update_all_forSQLname = 'n'
   begin
	Select @miscprint = 'DBA WARNING: Invalid input parm @ProcessType (' + @ProcessType + ').  Must be '' '', ''full'', ''sprocs_only'', ''Override_Needed'', ''DBA-ok'', ''DBA-cancelled'', ''JobRestore-y'' or ''JobRestore-n''.' 
	Print  @miscprint
	Print ''
   end


--  Detail SQLname change
If @SQLname is not null and @update_all_forSQLname = 'n'
   begin
	Select @miscprint = 'UPDATE: update dbo.Request_detail set SQLname = ''' + @SQLname + ''' where Gears_id = ' + convert(nvarchar(20), @gears_id) + ' and reqdet_id = ' + convert(nvarchar(20), @detail_id)
	Print  @miscprint
	Print ''

	update dbo.Request_detail set SQLname = @SQLname where Gears_id = @gears_id and reqdet_id = @detail_id
	Select @update_flag = 'y'
   end


--  Detail domain change
If @domain is not null and @update_all_forSQLname = 'n'
   begin
	Select @miscprint = 'UPDATE: update dbo.Request_detail set domain = ''' + @domain + ''' where Gears_id = ' + convert(nvarchar(20), @gears_id) + ' and reqdet_id = ' + convert(nvarchar(20), @detail_id)
	Print  @miscprint
	Print ''

	update dbo.Request_detail set domain = @domain where Gears_id = @gears_id and reqdet_id = @detail_id
	Select @update_flag = 'y'
   end
Else If @domain is not null and @update_all_forSQLname = 'y'
   begin
	Select @miscprint = 'UPDATE: update dbo.Request_detail set domain = ''' + @domain + ''' where Gears_id = ' + convert(nvarchar(20), @gears_id) + ' and SQLname = ''' + rtrim(@SQLname) + ''''
	Print  @miscprint
	Print ''

	update dbo.Request_detail set domain = @domain where Gears_id = @gears_id and SQLname = @SQLname
	Select @update_flag = 'y'
   end


--  Detail BASEfolder change
If @BASEfolder is not null and @update_all_forSQLname = 'n'
   begin
	Select @miscprint = 'UPDATE: update dbo.Request_detail set BASEfolder = ''' + @BASEfolder + ''' where Gears_id = ' + convert(nvarchar(20), @gears_id) + ' and reqdet_id = ' + convert(nvarchar(20), @detail_id)
	Print  @miscprint
	Print ''

	update dbo.Request_detail set BASEfolder = @BASEfolder where Gears_id = @gears_id and reqdet_id = @detail_id
	Select @update_flag = 'y'
   end
Else If @BASEfolder is not null and @update_all_forSQLname = 'y'
   begin
	Select @miscprint = 'UPDATE: update dbo.Request_detail set BASEfolder = ''' + @BASEfolder + ''' where Gears_id = ' + convert(nvarchar(20), @gears_id) + ' and SQLname = ''' + rtrim(@SQLname) + ''''
	Print  @miscprint
	Print ''

	update dbo.Request_detail set BASEfolder = @BASEfolder where Gears_id = @gears_id and SQLname = @SQLname
	Select @update_flag = 'y'
   end


-----------------  Finalizations  ------------------

label99:
--  Print out sample exection of this sproc for specific gears_id
If @update_flag = 'n'
   begin 
	If @gears_id is null
	   begin
		exec dbo.dpsp_Status @report_only = 'y'
	   end
	Else
	   begin
		exec dbo.dpsp_Status @gears_id = @gears_id, @report_only = 'y'
	   end

	Print  ' '
	Print  ' '
	Select @miscprint = '--Here are sample execute commands for this sproc:'
	Print  @miscprint
	Print  ' '
	Select @miscprint = '--Update Request Start Date/Time:'
	Print  @miscprint
	Select @miscprint = 'exec DEPLcontrol.dbo.dpsp_update @gears_id = 12345'
	Print  @miscprint
	Select @miscprint = '                                ,@start_dt = ''20091229 09:21'''
	Print  @miscprint
	Print  ' '
	Select @miscprint = '--Update Request Status:'
	Print  @miscprint
	Select @miscprint = 'exec DEPLcontrol.dbo.dpsp_update @gears_id = 12345'
	Print  @miscprint
	Select @miscprint = '                                ,@status = ''pending''   --''pending'', ''cancelled'', ''complete'', ''completed'', ''Gears Completed'', ''in-work'''
	Print  @miscprint
	Print  ' '
	Select @miscprint = '--Update ''all'' Request Detail for a specific SQLname and Gears ID:'
	Print  @miscprint
	Select @miscprint = 'exec DEPLcontrol.dbo.dpsp_update @gears_id = 12345'
	Print  @miscprint
	Select @miscprint = '                                ,@SQLname = ''servername\A'''
	Print  @miscprint
	Select @miscprint = '                                ,@status = ''cancelled''   --''pending'', ''cancelled'', ''complete'', ''completed'', ''Gears Completed'', ''in-work'''
	Print  @miscprint
	Select @miscprint = '                                --,@domain = ''stage''     --''amer'', ''stage'', ''production'''
	Print  @miscprint
	Select @miscprint = '                                --,@BASEfolder = ''BNDL'''
	Print  @miscprint
	Print  ' '
	Select @miscprint = '--Update Request Detail for a specific Gears ID:'
	Print  @miscprint
	Select @miscprint = 'exec DEPLcontrol.dbo.dpsp_update @gears_id = 12345'
	Print  @miscprint
	Select @miscprint = '                                ,@detail_id = 701'
	Print  @miscprint
	Select @miscprint = '                                ,@DBname = ''Bundle'''
	Print  @miscprint
	Select @miscprint = '                                --,@status = ''pending''       --''pending'', ''cancelled'', ''complete'', ''completed'', ''Gears Completed'', ''in-work'''
	Print  @miscprint
	Select @miscprint = '                                --,@ProcessType = ''DBA-ok''   --'' '', ''full'', ''sprocs_only'', ''Override_Needed'', ''DBA-ok'', ''DBA-cancelled'', ''JobRestore-y'', ''JobRestore-n'''
	Print  @miscprint
	Select @miscprint = '                                --,@SQLname = ''servername\A'''
	Print  @miscprint
	Select @miscprint = '                                --,@domain = ''stage''         --''amer'', ''stage'', ''production'''
	Print  @miscprint
	Select @miscprint = '                                --,@BASEfolder = ''BNDL'''
	Print  @miscprint
	Print  ' '
	Select @miscprint = 'exec DEPLcontrol.dbo.dpsp_update @gears_id = 12345'
	Print  @miscprint
	Select @miscprint = '                                ,@detail_id = 702'
	Print  @miscprint
	Select @miscprint = '                                ,@ProcessType = ''JobRestore-n'''
	Print  @miscprint
	Print  ' '
   end
Else
   begin
	exec dbo.dpsp_Status @gears_id = @gears_id, @report_only = 'y'
   end





GO
