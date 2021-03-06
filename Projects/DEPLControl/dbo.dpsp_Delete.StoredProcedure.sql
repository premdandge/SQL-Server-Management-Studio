USE [DEPLcontrol]
GO
/****** Object:  StoredProcedure [dbo].[dpsp_Delete]    Script Date: 10/4/2013 11:02:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[dpsp_Delete] (@gears_id int = null)

/*********************************************************
 **  Stored Procedure dpsp_Delete                  
 **  Written by Jim Wilson, Getty Images                
 **  December 02, 2008                                      
 **  
 **  This sproc will delete a specific Gears request from
 **  the DEPLcontrol database.
 **
 **  Input Parm(s);
 **  @gears_id - is the Gears ID for a specific request
 **
 ***************************************************************/
  as
set nocount on

--	======================================================================================
--	Revision History
--	Date		Author     		Desc
--	==========	====================	=============================================
--	12/02/2008	Jim Wilson		New process.
--	01/29/2009	Jim Wilson		Added code for control_HL table.
--	======================================================================================


/***
Declare @gears_id int

Select @gears_id = 31178
--***/

-----------------  declares  ------------------

DECLARE
	 @miscprint			nvarchar(2000)
	,@charpos			int
	,@update_flag			char(1)
	,@save_start_d			nvarchar(50)
	,@save_start_t			nvarchar(50)
	,@save_start_date		datetime
	,@error_count			int

/*********************************************************************
 *                Initialization
 ********************************************************************/
Select @error_count = 0
Select @update_flag = 'n'




----------------------  Print the headers  ----------------------

Print  '/*******************************************************************'
Select @miscprint = '   SQL Automated Deployment Requests - Server: ' + @@servername
Print  @miscprint
Print  ' '
Select @miscprint = '-- Gears Request Delete Process '
Print  @miscprint
Print  '*******************************************************************/'
Print  ' '


--  Verify input parms

If @gears_id is null
   begin
	Select @miscprint = 'DELETE: No Gears ID specified.' 
	Print  @miscprint
	Print ''

	goto label99
   end
Else
   begin
	If not exists (select 1 from dbo.request where gears_id = @gears_id)
	   begin
		Select @miscprint = 'DBA WARNING: Invalid input parm for gears_id (' + convert(nvarchar(20), @gears_id) + ').  No rows for this gears_id in the Request table.' 
		Print  @miscprint
		Print ''
		Select @error_count = @error_count + 1

		goto label99
	   end
   end

	

/****************************************************************
 *                MainLine
 ***************************************************************/

--  Frist delete the detail records for the Gears ID
Select @miscprint = 'DELETE: delete from dbo.Request_detail where Gears_id = ' + convert(nvarchar(20), @gears_id)
Print  @miscprint
Print ''

delete from dbo.Request_detail where Gears_id = @gears_id


--  Now delete the main request record for this Gears ID
Select @miscprint = 'DELETE: delete from dbo.Request where Gears_id = ' + convert(nvarchar(20), @gears_id) 
Print  @miscprint
Print ''

delete from dbo.Request where Gears_id = @gears_id

If exists (select 1 from dbo.control_HL where gears_id = @gears_id)
   begin
	--  Now delete the related rows from the control_HL table for this Gears ID
	Select @miscprint = 'DELETE: delete from dbo.control_HL where Gears_id = ' + convert(nvarchar(20), @gears_id) 
	Print  @miscprint
	Print ''

	delete from dbo.control_HL where Gears_id = @gears_id
   end




-----------------  Finalizations  ------------------

label99:

--  Print out sample exection of this sproc for specific gears_id
exec dbo.dpsp_Status @report_only = 'y'

Print  ' '
Print  ' '
Select @miscprint = '--Here is a sample execute command for this sproc:'
Print  @miscprint
Print  ' '
Select @miscprint = 'exec DEPLcontrol.dbo.dpsp_Delete @gears_id = 12345'
Print  @miscprint
Print  ' '




GO
