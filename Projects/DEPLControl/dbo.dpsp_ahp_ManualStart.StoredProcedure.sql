USE [DEPLcontrol]
GO
/****** Object:  StoredProcedure [dbo].[dpsp_ahp_ManualStart]    Script Date: 10/4/2013 11:02:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[dpsp_ahp_ManualStart] (@request_id int = null
					,@TargetSQLname sysname = null)

/*********************************************************
 **  Stored Procedure dpsp_ahp_ManualStart                  
 **  Written by Jim Wilson, Getty Images                
 **  April 09, 2009                                      
 **  
 **  This sproc will assist in manually starting deployment
 **  processes in stage and production.  
 **
 **  Input Parm(s);
 **  @request_id - is the request ID for a specific AHP request
 **
 **  @TargetSQLname - is the SQLname (with instance) you want to start.
 **
 ***************************************************************/
  as
set nocount on

--	======================================================================================
--	Revision History
--	Date		Author     		Desc
--	==========	====================	=============================================
--	04/09/2009	Jim Wilson		New process.
--	04/29/2009	Jim Wilson		Added ckeck for Request_status = 'manual' to update process.
--	12/14/2009	Jim Wilson		Added Scriptall function.
--	03/03/2011	Jim Wilson		Converted for AHP.
--	======================================================================================


/***
Declare @request_id int
Declare @TargetSQLname sysname

Select @request_id = 32566
Select @TargetSQLname = 'ScriptAll'
--***/

-----------------  declares  ------------------

DECLARE
	 @miscprint			nvarchar(2000)
	,@cmd				nvarChar(4000)
	,@update_flag			char(1)
	,@scriptall_flag		char(1)
	,@error_count			int

/*********************************************************************
 *                Initialization
 ********************************************************************/
Select @error_count = 0
Select @update_flag = 'n'
Select @scriptall_flag = 'n'




----------------------  Print the headers  ----------------------

Print  '/*******************************************************************'
Select @miscprint = '   SQL Automated Deployment Requests - Server: ' + @@servername
Print  @miscprint
Print  ' '
Select @miscprint = '-- Manual Start Process '
Print  @miscprint
Print  '*******************************************************************/'
Print  ' '


--  Verify input parms

If @request_id is null
   begin
	Select @miscprint = 'Error: No Request ID specified.' 
	Print  @miscprint
	Print ''

	exec dbo.dpsp_ahp_Status @report_only = 'y'

	goto label99
   end

If @TargetSQLname is null
   begin
	Select @miscprint = 'Error: No @TargetSQLname specified.' 
	Print  @miscprint
	Print ''

	exec dbo.dpsp_ahp_Status @request_id = @request_id, @report_only = 'y'

	goto label99
   end
   
If @TargetSQLname = 'ScriptAll'
   begin
	Select @scriptall_flag = 'y'
   end 
  

If not exists (select 1 from dbo.AHP_Import_Requests where request_id = @request_id and TargetSQLname = @TargetSQLname) and @scriptall_flag <> 'y' 
   begin
	Select @miscprint = 'Error: @TargetSQLname specified for this request (' + @TargetSQLname + ') does not exist in this request_id (' + convert(nvarchar(10), @request_id) + ').' 
	Print  @miscprint
	Print ''

	exec dbo.dpsp_ahp_Status @request_id = @request_id, @report_only = 'y'

	goto label99
   end

If not exists (select 1 from dbo.AHP_Import_Requests where request_id = @request_id and TargetSQLname = @TargetSQLname and Request_status like '%manual%') and @scriptall_flag <> 'y' 
   begin
	Select @miscprint = 'Error: Request_Status for this request_id/TargetSQLname is not set to ''local_insert_manual'' or ''prod_insert_manual''.  No action taken.' 
	Print  @miscprint
	Print ''

	exec dbo.dpsp_ahp_Status @request_id = @request_id, @report_only = 'y'

	goto label99
   end


	

/****************************************************************
 *                MainLine
 ***************************************************************/

--  "Script all" process
If @scriptall_flag = 'y'
   begin

	Select	@miscprint = '--  Info: @TargetSQLname specified keyword "ScriptAll".' 
	Print	@miscprint
	Print	''
	SET	@cmd = ''
	select	@cmd	= @cmd 
					+ '--exec DEPLcontrol.dbo.dpsp_ahp_StartDeployment @request_id = '
					+ CAST(@request_id AS VarChar(20))
					+ ', @TargetSQLname = '''
					+ d.TargetSQLname
					+ ''', @ManualOverride = ''y'';'
					+ CHAR(13) + CHAR(10)
					+ 'GO'
					+ CHAR(13) + CHAR(10)+ CHAR(13) + CHAR(10)
	FROM	(
			SELECT	DISTINCT
					TargetSQLname 				
			From	dbo.AHP_Import_Requests d
			WHERE	request_id = @request_id
				and	Request_status like '%manual%'
			) d
	PRINT (@CMD)
	Select @cmd = '--exec DEPLcontrol.dbo.dpsp_ahp_Status @request_id = ' + CAST(@request_id AS VarChar(20)) +', @report_only = ''y'''
	PRINT (@CMD)
	Print 'GO'

	Set @update_flag = 'y'	

	goto label99
   end  







exec DEPLcontrol.dbo.dpsp_ahp_StartDeployment @request_id = @request_id, @TargetSQLname = @TargetSQLname, @ManualOverride = 'y'


exec DEPLcontrol.dbo.dpsp_ahp_Status @request_id = @request_id, @report_only = 'y'





-----------------  Finalizations  ------------------

label99:

If @update_flag = 'n'
   begin
	Print  ' '
	Print  ' '
	Select @miscprint = '-- Here is a sample execute command for this sproc:'
	Print  @miscprint
	Print  ' '
	Select @miscprint = '-- To Start a single Instance:'
	Print  @miscprint
	Print  ' '
	Select @miscprint = 'exec DEPLcontrol.dbo.dpsp_ahp_ManualStart @request_id = 12345, @TargetSQLname = ''servername\a'''
	Print  @miscprint
	Print  'go'
	Print  ' '
	Print  ' '
	Select @miscprint = '-- To script the code for all Instances:'
	Print  @miscprint
	Print  ' '
	Select @miscprint = 'exec DEPLcontrol.dbo.dpsp_ahp_ManualStart @request_id = 12345, @TargetSQLname = ''ScriptAll'''
	Print  @miscprint
	Print  'go'
	Print  ' '		
   end


GO
