USE [DEPLinfo]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[dpsp_auto_run_post_build] 

/*********************************************************
 **  Stored Procedure dpsp_auto_run_post_build                  
 **  Written by Jim Wilson, Getty Images                
 **  March 9, 2005                                      
 **  
 **  This sproc is set up to process SQL scripts after all builds
 **  have been completed on the SQL instance as part of the automated 
 **  SQL deployment process.
 **
 ***************************************************************/
  as
SET NOCOUNT ON

--	======================================================================================
--	Revision History
--	Date		Author     		Desc
--	==========	====================	=============================================
--	03/09/2005	Jim Wilson		New process
--	02/22/2008	Jim Wilson		Added section to skip email (create text file).
--	02/19/2009	Jim Wilson		Updated for DEPLinfo.
--	10/09/2009	Jim Wilson		Added code for new environments.
--	11/24/2009	Jim Wilson		Added update to Post_Build_Processing in Alpha env.
--	06/10/2010	Jim Wilson		Added top 1 to select for email recipients.
--	======================================================================================



-----------------  declares  ------------------
DECLARE
	 @miscprint				nvarchar(4000)
	,@outDateStmp			char(14)
	,@out2time				nvarchar(19)
	,@charpos				int
	,@Result				int
	,@print_flag			char(1)
	,@save_env_name			sysname
	,@save_env_num			sysname
	,@BuildCodeServer		sysname
	,@save_servername		sysname
	,@save_servername2		sysname
	,@save_servername3		sysname
	,@save_outpath			nvarchar(500)
	,@save_outpath_print	nvarchar(500)
	,@mailpath				nvarchar(500)
	,@mailfullpath			nvarchar(500)
	,@Hold_hhmmss			nvarchar(8)
	,@cmd					varchar(4000)
	,@sqlcmd				varchar(4000)
	,@save_PBP_ID			int
	,@save_DBname			sysname
	,@save_pbpFilename		sysname
	,@save_pbpFilepath		nvarchar(500)
	,@save_subject			sysname
	,@message 				varchar(8000)
	,@attachments 			nvarchar(4000)
	,@save_recipients 		nvarchar(500)
	,@save_Copy_recipients 	nvarchar(500)
	,@ProjectID 			sysname
	,@save_gears_id			sysname
	,@OutputString			varchar
	,@CRLF					VarChar(10)
	,@Debug					BIT
	,@NestLevel				INT
	,@Mail1					VarChar(max)
	,@Mail2					VarChar(max)

----------------  initial values  -------------------
SELECT	@CRLF				= CHAR(10) + CHAR(13)
		,@Debug				= 0
		,@NestLevel			= 0
		,@message			= ''
		,@attachments		= ''
		,@print_flag		= 'n'
		,@save_servername	= REPLACE(@@SERVERNAME,'\' + @@SERVICENAME,'')
		,@save_servername2	= REPLACE(@@SERVERNAME,'\','$')
		,@save_servername3	= @save_servername + CASE @@SERVICENAME WHEN 'MSSQLSERVER' THEN '' ELSE '(' + @@SERVICENAME +')' END
		
		--  Set the ouput file path and name
		,@Hold_hhmmss		= convert(varchar(8), getdate(), 8)
		,@outDateStmp		= convert(char(8), getdate(), 112) + substring(@Hold_hhmmss, 1, 2) + substring(@Hold_hhmmss, 4, 2) + substring(@Hold_hhmmss, 7, 2) 
		,@save_outpath		= '\\' + @save_servername + '\' + @save_servername2 + '_dbasql\dba_reports\Post_Build_Scripts_' + @outDateStmp + '.txt'
		,@mailpath			= '\\' + @save_servername + '\' + @save_servername + '_dba_mail'

		--  Start to format the email
		,@mailfullpath		= @mailpath + '\' + @save_servername3 + '_' + @outDateStmp + '.sml' 
		,@message			= @message + 'The following Post Build SQL scripts (DB\ScriptName) were run as part of this deployment.' + @CRLF + @CRLF
		,@save_subject		= @@servername + ' Post Build Script Process Results - SQLdeployment'
				
		,@save_env_name		= CASE env_type WHEN 'ENVname' THEN env_name ELSE @save_env_name END
		,@save_env_num		= CASE env_type WHEN 'ENVnum' THEN env_name ELSE @save_env_num END
		,@BuildCodeServer	= CASE env_type WHEN 'BuildCodeServer' THEN env_name ELSE @BuildCodeServer END
from	DEPLinfo.dbo.enviro_info

SELECT	TOP 1
		@save_gears_id		= [gears_id] 
		,@ProjectID			= [Projectname]
FROM	dbo.control_local 
WHERE	[status]			like 'in-work%' 
	and	[Process]			= 'end'


BEGIN	-- TEST INPUTS AND VALUES

	-- GET AND TEST THE @PROJECTID FROM THE CONTROL_LOCAL TABLE

		IF @save_gears_id IS NULL
		   BEGIN
			Select @miscprint = 'Control row for this restore job step could not be found (Server ' + @@SERVERNAME + ').'
			raiserror(@miscprint,16,-1) with log
			GOTO label99
		   END

		-- VERIFY THE MAILPUT PATH EXISTANCE
		IF [dbaadmin].[dbo].[dbaudf_GetFileProperty] (@mailpath,'Folder','Path') IS NULL
		   begin
			select @miscprint = 'DBA WARNING: Unable to write SQL mail parameter file to mailpath ''' + @mailpath + ''''
			raiserror(@miscprint,1,-1) with log
			goto label99
		   end

		--  CHECK FOR RECORDS TO PROCESS
		If (select count(*) from DEPLinfo.dbo.Post_Build_Processing where dtrun is null) = 0
		   begin
			select @miscprint = 'No Post Build Scripts to process'
			EXEC dbaadmin.dbo.dbasp_print @miscprint,@NestLevel,1,1
			goto label99
		   end

		--  CHECK TO SEE IF WE RUN POST BUILD SCRIPTS IN THIS ENVIRONMENT
		If exists (select 1 from dbo.enviro_info where env_type = 'ENVname' and env_name in ('alpha'))
		   begin
			update dbo.Post_Build_Processing set dtrun = getdate() where dtrun is null 
			select @miscprint = 'Post Build Scripts are not run in this environment'
			EXEC dbaadmin.dbo.dbasp_print @miscprint,@NestLevel,1,1
			goto label99
		   end
END

BEGIN	-- RUNNING SCRIPT(S)

		--  INITALIZE THE OUTPUT FILE (WRITE HEADDER TEXT)
		SET		@OutputString = 'Starting the Post Build Script Process on server ' + @@servername + @CRLF + @CRLF
		
		EXEC	dbaadmin.dbo.dbasp_print @OutputString,@NestLevel,1,@Debug
		SELECT	@miscprint	= 'Writing Output to ' + @save_outpath
				,@NestLevel = @NestLevel + 1
		EXEC	dbaadmin.dbo.dbasp_print @miscprint,@NestLevel,1,@Debug
		
		EXEC	[dbo].[dbasp_FileAccess_Write] @OutputString, @save_outpath, NULL, 0 -- OVERWRITE

		--  PROCESS SCRIPTS
		DECLARE PostFile CURSOR KEYSET
		FOR
		Select		PBP_ID
					,DBname
					,pbpFilename
					,pbpFilepath + '\' + pbpFilename
		FROM		dbo.Post_Build_Processing 
		where		dtrun is null 
		order by	PBP_ID

		
		EXEC	dbaadmin.dbo.dbasp_print 'Starting to Process Files',@NestLevel,1,@Debug
		SELECT	@NestLevel = @NestLevel + 1
		OPEN PostFile
		FETCH NEXT FROM PostFile INTO @save_PBP_ID,@save_DBname,@save_pbpFilename,@save_pbpFilepath
		WHILE (@@fetch_status <> -1)
		BEGIN
			IF (@@fetch_status <> -2)
			BEGIN
				-- LOG IT
				SELECT	@miscprint	= CONVERT(VarChar(8),GetDate(),8) + ' Starting File ' + @save_pbpFilepath
				EXEC	dbaadmin.dbo.dbasp_print @miscprint,@NestLevel,1,@Debug
			
				-- RUN IT (WRITE QUERY RESULTS TEXT)				
				EXEC dbaadmin.dbo.dbasp_RunTSQL
						@Name				= @save_pbpFilepath
						,@TSQL				= NULL	
						,@DBName			= @save_DBname
						,@Server			= @@Servername
						,@OutputPath		= @save_outpath
						,@StartNestLevel	= @NestLevel
						
				-- LOG IT
				SELECT	@miscprint	= CONVERT(VarChar(8),GetDate(),8) + ' Finished File ' + @save_pbpFilepath
				EXEC	dbaadmin.dbo.dbasp_print @miscprint,@NestLevel,1,@Debug

				-- ADD IT TO EMAIL MESSAGE
				Select @message = @message + @save_DBname + '\' + @save_pbpFilename + @CRLF
				Update DEPLinfo.dbo.Post_Build_Processing set dtrun = getdate() where PBP_ID = @save_PBP_ID
			END
			FETCH NEXT FROM PostFile INTO @save_PBP_ID,@save_DBname,@save_pbpFilename,@save_pbpFilepath
		END
		CLOSE PostFile
		DEALLOCATE PostFile	

		-- FINALIZE THE OUTPUT FILE (WRITE FOOTER TEXT)
		SELECT	@OutputString = @CRLF + @CRLF + 'Completed the Post Build Script Process ' + @CRLF + GETDATE() + @CRLF
				,@NestLevel = @NestLevel - 1

		EXEC	dbaadmin.dbo.dbasp_print @OutputString,@NestLevel,1,@Debug

		EXEC	[dbo].[dbasp_FileAccess_Write] @OutputString, @save_outpath, NULL, 1 -- Append 

END

BEGIN	-- EMAIL NOTIFICATION

		-- LOG IT
		SELECT	@miscprint	= CONVERT(VarChar(8),GetDate(),8) + ' Starting Email Notification Processing.'
		EXEC	dbaadmin.dbo.dbasp_print @miscprint,@NestLevel,1,@Debug

		SELECT		top 1
					@save_outpath_print		= CASE @save_env_name
												WHEN 'production'	THEN substring(@save_outpath, 3, len(@save_outpath)-2)
												WHEN 'staging'		THEN substring(@save_outpath, 3, len(@save_outpath)-2)
												WHEN 'stage'		THEN substring(@save_outpath, 3, len(@save_outpath)-2)
												ELSE @save_outpath END
					,@attachments			= CASE @save_outpath_print
												WHEN @save_outpath THEN NULL
												ELSE @save_outpath END
					,@message				= @message + @CRLF + @save_outpath_print + @CRLF 
					,@save_recipients		= COALESCE(t1.recipients,t2.recipients)
					,@save_copy_recipients	= COALESCE(t1.ccrecipients,t2.ccrecipients)
					,@NestLevel				= @NestLevel + 1
		from		DEPLinfo.dbo.sendmail_dist_list t1 WITH(NOLOCK)
		CROSS JOIN	DEPLinfo.dbo.sendmail_dist_list t2 WITH(NOLOCK)
		where		t1.ProjectID			= @ProjectID
			and		t1.env_name				= @save_env_name 
			and		t1.success_flag			= 'Y'
			and		t2.ProjectID			= 'OTHER'
			and		t2.success_flag			= 'Y'

		SELECT		@Mail1					= '@Message = ' + QUOTENAME(rtrim(@message),'''') + @CRLF
											+ '@Subject = ' + QUOTENAME(rtrim(@save_subject),'''') + @CRLF
											+ COALESCE('@recipients = ' + QUOTENAME(rtrim(@save_recipients),'''') + @CRLF,'')
											+ COALESCE('@copy_recipients = ' + QUOTENAME(rtrim(@save_copy_recipients),'''') + @CRLF,'')
											+ COALESCE('@attachments = ' + QUOTENAME(rtrim(@attachments),'''') + @CRLF,'')
					,@Mail2					= QUOTENAME(rtrim(@message),'''') 

		--  IF NOT STAGE OR PROD AND BUILDCODE SERVER IS NOT SEAFRESQLDBA01, SEND EMAIL.
		If @save_env_name IN ('production', 'staging', 'stage') AND @BuildCodeServer != 'seafresqldba01'
		BEGIN
			-- LOG IT
			SELECT	@miscprint	= CONVERT(VarChar(8),GetDate(),8) + ' SEND Email.'
			EXEC	dbaadmin.dbo.dbasp_print @miscprint,@NestLevel,1,@Debug
			SET		@NestLevel = @NestLevel + 1
			EXEC	dbaadmin.dbo.dbasp_print @Mail1,@NestLevel,1,@Debug
			SET		@NestLevel = @NestLevel - 1		

			EXEC [dbo].[dbasp_FileAccess_Write] @Mail1, @mailfullpath, NULL, 0 -- Overwrite
			
		END

	If @save_env_name in ('alpha', 'beta', 'candidate', 'prodsupport', 'dev', 'test', 'load') AND @BuildCodeServer = 'seafresqldba01'
		BEGIN
			-- LOG IT
			SELECT	@miscprint	= CONVERT(VarChar(8),GetDate(),8) + ' DONT SEND Email.'
			EXEC	dbaadmin.dbo.dbasp_print @miscprint,@NestLevel,1,@Debug
			SET		@NestLevel = @NestLevel + 1
			EXEC	dbaadmin.dbo.dbasp_print @Mail2,@NestLevel,1,@Debug
			SET		@NestLevel = @NestLevel + 1


			SELECT	@out2time	= convert(nvarchar(19), getdate(), 112)+'_'+REPLACE(convert(nvarchar(19), getdate(), 108), ':', '')
			
			SET		@CMD		= '\\' + @save_servername + '\' + @save_servername + '_builds\deployment_logs\' + @save_servername3 + '_PostBuildScriptResults_' + @out2time + '.txt'

			SELECT	@miscprint	= CONVERT(VarChar(8),GetDate(),8) + ' Write to file ' + @CMD
			EXEC	dbaadmin.dbo.dbasp_print @miscprint,@NestLevel,1,@Debug

			EXEC [dbo].[dbasp_FileAccess_Write] @Mail2, @CMD, NULL, 0 -- Overwrite

			SET		@CMD		= '\\seafresqldba01\build_logs\' + @save_env_num + '\' + @save_servername3 + '_PostBuildScriptResults_' + @out2time + '.txt'

			SELECT	@miscprint	= CONVERT(VarChar(8),GetDate(),8) + ' Write to file ' + @CMD
			EXEC	dbaadmin.dbo.dbasp_print @miscprint,@NestLevel,1,@Debug

			EXEC [dbo].[dbasp_FileAccess_Write] @Mail2, @CMD, NULL, 0 -- Overwrite
			
			SET		@NestLevel = @NestLevel - 1
		END
END
/**********************   End Proc  **************************/
label99:

SET		@NestLevel = 0
SELECT	@miscprint	= CONVERT(VarChar(8),GetDate(),8) + ' Done.' 
EXEC	dbaadmin.dbo.dbasp_print @miscprint,@NestLevel,1,@Debug

GO


 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
