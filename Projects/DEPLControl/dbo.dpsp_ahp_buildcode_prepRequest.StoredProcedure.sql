USE [DEPLcontrol]
GO
/****** Object:  StoredProcedure [dbo].[dpsp_ahp_buildcode_prepRequest]    Script Date: 10/4/2013 11:02:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[dpsp_ahp_buildcode_prepRequest] (@BuildLabel sysname = null
						,@ReleaseNum sysname = null
						,@TargetPath nvarchar(500) = null)

/*********************************************************
 **  Stored Procedure dpsp_ahp_buildcode_prepRequest                  
 **  Written by Jim Wilson, Getty Images                
 **  November 05, 2010                                      
 **  
 **  This procedure is used to start the BUild Code prep process
 **  by AHP for the SQL deployment process.
 **
 **  This proc accepts the following input parms:
 **  - @BuildLabel  indicates the requested label (top level folder name).
 **  - @ReleaseNum gives us the release number.
 **  - @TargetPath is the path the build code has been copied to.
 **
 ***************************************************************/
  as
  SET NOCOUNT ON

--	======================================================================================
--	Revision History
--	Date		Author     		Desc
--	==========	====================	=============================================
--	11/05/2010	Jim Wilson		Old Deploymaster process rewritten.
--	======================================================================================


/***
declare @BuildLabel sysname
declare @ReleaseNum sysname
declare @TargetPath nvarchar(500)

select @BuildLabel = 'TranscoderDB_Main_20101105.3753y'
select @ReleaseNum = '14.0'
select @TargetPath = 'e:\builds\VSTS_Source\AHP_Builds'
--***/



-----------------  declares  ------------------
DECLARE 
	 @miscprint			NVARCHAR(4000)
	,@cmd				Nvarchar(4000)
	,@status1 			varchar(10)


----------------  initial values  -------------------



--  Create temp tables
Create table #DirectoryTempTable(cmdoutput nvarchar(255) null)



--  Check input parms
If @BuildLabel is null or @BuildLabel = ''
   begin
	Print '@BuildLabel ' + @BuildLabel
	Print '@ReleaseNum ' + @ReleaseNum
	Print '@TargetPath ' + @TargetPath
	select @miscprint = 'DBA ERROR: Invaild parameter passed to dpsp_ahp_buildcode_prepRequest - @BuildLabel cannot be null'
	raiserror(@miscprint,16,-1) with log
	goto label99
   end

If @ReleaseNum is null or @ReleaseNum = ''
   begin
	Print '@BuildLabel ' + @BuildLabel
	Print '@ReleaseNum ' + @ReleaseNum
	Print '@TargetPath ' + @TargetPath
	select @miscprint = 'DBA ERROR: Invaild parameter passed to dpsp_ahp_buildcode_prepRequest - @ReleaseNum cannot be null'
	raiserror(@miscprint,16,-1) with log
	goto label99
   end

If @TargetPath is null or @TargetPath = ''
   begin
	Print '@BuildLabel ' + @BuildLabel
	Print '@ReleaseNum ' + @ReleaseNum
	Print '@TargetPath ' + @TargetPath
	select @miscprint = 'DBA ERROR: Invaild parameter passed to dpsp_ahp_buildcode_prepRequest - @TargetPath cannot be null'
	raiserror(@miscprint,16,-1) with log
	goto label99
   end



--  Verify the target folder exists
select @cmd = 'dir ' + rtrim(@TargetPath) + '\' + rtrim(@BuildLabel)
Select @cmd = @cmd  + ' /AD /B'
print @cmd

delete from #DirectoryTempTable
insert into #DirectoryTempTable exec master.sys.xp_cmdshell @cmd
delete from #DirectoryTempTable where cmdoutput is null
--select * from #DirectoryTempTable

If exists (select 1 from #DirectoryTempTable where cmdoutput like '%File Not Found%')
   begin
	Print '@BuildLabel ' + @BuildLabel
	Print '@ReleaseNum ' + @ReleaseNum
	Print '@TargetPath ' + @TargetPath
	select @miscprint = 'DBA ERROR: Build Code folder not found.  Processing sproc dpsp_ahp_buildcode_prepRequest.'
	raiserror(@miscprint,16,-1) with log
	goto label99
   end
   
   


/****************************************************************
 *                MainLine
 ***************************************************************/

-- Insert data
insert into dbo.AHPbuildcode_prep values (@BuildLabel, @ReleaseNum, @TargetPath, 'Pending', getdate(), null, null)


--  Start Build Code Prep job
exec dbaadmin.dbo.dbasp_Check_Jobstate 'APPL - AHP Build Code Prep', @status1 output

IF @status1 = 'idle'
   begin
	exec msdb.dbo.sp_start_job @job_name = 'APPL - AHP Build Code Prep'
	Select @miscprint = 'Note: Started SQL job ''APPL - AHP Build Code Prep'' on SQL instance ' + @@servername
	Print @miscprint
   end
Else
   begin
	Select @miscprint = 'Note: SQL job ''APPL - AHP Build Code Prep'' on SQL instance ' + @@servername + ' is already running'
	Print @miscprint
   end



-- Finish -------------------------------------------------------------------------------------

label99:


Print ''
Print 'Process Completed'



Drop table #DirectoryTempTable



GO
