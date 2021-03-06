USE [DEPLcontrol]
GO
/****** Object:  StoredProcedure [dbo].[dpsp_ImportApproval]    Script Date: 10/4/2013 11:02:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[dpsp_ImportApproval]

/***************************************************************
 **  Stored Procedure dpsp_ImportApproval                 
 **  Written by Jim Wilson, Getty Images                
 **  August 11, 2010                                      
 **  
 **  This sproc is set up to Approve Imported deployment requests.
 ***************************************************************/
  as
set nocount on

--	======================================================================================
--	Revision History
--	Date		Author     		Desc
--	==========	====================	=============================================
--	08/11/2010	Jim Wilson		New process.
--	10/22/2010	Jim Wilson		Modified stage and prod approval where clause.
--	======================================================================================

-----------------  declares  ------------------

DECLARE
	 @miscprint			nvarchar(2000)
	,@cmd				nvarchar(4000)
	,@save_gears_id			int
	,@approve_pw			sysname
	,@approve_stage_pw		sysname
	,@approve_prod_pw		sysname


/*********************************************************************
 *                Initialization
 ********************************************************************/
Select @approve_pw = '%orion%'
Select @approve_stage_pw = '%asterism%'
Select @approve_prod_pw = '%betelgeuse%'


--  Create temp table

CREATE TABLE #temp_reqdet (gears_id int)

	

/****************************************************************
 *                MainLine
 ***************************************************************/

Print 'Start import approval process.'
Print ''


--------------------------------------------------------------------------------------------------------------------
--  Section to Auto Approve       ----------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------

--  Give DBA override OK for non-stage and non-prod request that use the special password
update rd set ProcessType = 'DBA-ok' 
from dbo.Request_detail rd, dbo.request r
where rd.gears_id = r.gears_id 
and r.status = 'pending' 
and r.DBAapproved <> 'y' 
and r.Environment not like '%Stag%' 
and r.Environment not like 'Prod%' 
and r.notes like @approve_pw
and rd.ProcessType like '%Override_Needed%'


--  Capture all the requests that can be auto approved
delete from #temp_reqdet
Insert into #temp_reqdet select gears_id from dbo.request 
					where status = 'pending' 
					and DBAapproved <> 'y' 
					and Environment not like '%Stag%' 
					and Environment not like 'Prod%' 
					and StartTime not like 'z%' 
					and (notes like @approve_pw or notes = '' or notes = null)

delete from #temp_reqdet where gears_id in (select gears_id from dbo.Request_detail where status = 'pending' and ProcessType like '%Override_Needed%')
--select * from #temp_reqdet


-- Loop through #temp_reqdet (Gears ticket numbers)
If (select count(*) from #temp_reqdet) > 0
   begin
	start_reqdet4:

	Select @save_Gears_id = (select top 1 gears_id from #temp_reqdet order by gears_id)

	Select @cmd = 'sqlcmd -S' + @@servername + ' -dDEPLcontrol -Q"exec dbo.dpsp_Approve @gears_id = ' + convert(nvarchar(10), @save_Gears_id) + ', @auto = ''y''" -E'
	print @cmd
	EXEC master.sys.xp_cmdshell @cmd--, no_output

	Delete from #temp_reqdet where gears_id = @save_Gears_id
	If (select count(*) from #temp_reqdet) > 0
	   begin
		goto start_reqdet4
	   end
   end	



--  Auto approve for stage
Insert into #temp_reqdet select gears_id from dbo.request 
					where status = 'pending' 
					and DBAapproved <> 'y' 
					and Environment like '%Stag%' 
					and StartTime not like 'z%' 
					and notes like @approve_stage_pw

delete from #temp_reqdet where gears_id in (select gears_id from dbo.Request_detail where status = 'pending' and ProcessType like '%Override_Needed%')
--select * from #temp_reqdet


-- Loop through #temp_reqdet (Gears ticket numbers)
If (select count(*) from #temp_reqdet) > 0
   begin
	start_reqdet5:

	Select @save_Gears_id = (select top 1 gears_id from #temp_reqdet order by gears_id)

	Select @cmd = 'sqlcmd -S' + @@servername + ' -dDEPLcontrol -Q"exec dbo.dpsp_Approve @gears_id = ' + convert(nvarchar(10), @save_Gears_id) + ', @auto = ''y'', @runtype = ''auto''" -E'
	print @cmd
	EXEC master.sys.xp_cmdshell @cmd--, no_output

	Delete from #temp_reqdet where gears_id = @save_Gears_id
	If (select count(*) from #temp_reqdet) > 0
	   begin
		goto start_reqdet5
	   end
   end	


--  Auto approve for prod
Insert into #temp_reqdet select gears_id from dbo.request 
					where status = 'pending' 
					and DBAapproved <> 'y' 
					and Environment like '%Prod%' 
					and StartTime not like 'z%' 
					and notes like @approve_prod_pw

delete from #temp_reqdet where gears_id in (select gears_id from dbo.Request_detail where status = 'pending' and ProcessType like '%Override_Needed%')
--select * from #temp_reqdet


-- Loop through #temp_reqdet (Gears ticket numbers)
If (select count(*) from #temp_reqdet) > 0
   begin
	start_reqdet6:

	Select @save_Gears_id = (select top 1 gears_id from #temp_reqdet order by gears_id)

	Select @cmd = 'sqlcmd -S' + @@servername + ' -dDEPLcontrol -Q"exec dbo.dpsp_Approve @gears_id = ' + convert(nvarchar(10), @save_Gears_id) + ', @auto = ''y'', @runtype = ''auto''" -E'
	print @cmd
	EXEC master.sys.xp_cmdshell @cmd--, no_output

	Delete from #temp_reqdet where gears_id = @save_Gears_id
	If (select count(*) from #temp_reqdet) > 0
	   begin
		goto start_reqdet6
	   end
   end	




-----------------  Finalizations  ------------------

label99:

Print 'End import approval process.'
Print ''

drop table #temp_reqdet









GO
