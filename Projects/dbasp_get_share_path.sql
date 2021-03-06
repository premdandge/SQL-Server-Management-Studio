USE [dbaadmin]
GO
/****** Object:  StoredProcedure [dbo].[dbasp_get_share_path]    Script Date: 05/07/2010 16:01:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[dbasp_get_share_path] (@share_name varchar(255),@phy_path varchar(2000) OUTPUT)

/*********************************************************
 **  Stored Procedure dbasp_get_share_path                  
 **  Written by Francis Stanisci & Jim Wilson, Getty Images                
 **  10/28/2002                                      
 **  
 **  This procedure gets the drive path for a defined share.
 ***************************************************************/
  as

set nocount on


--     Created: 10-28-2002
--
--      Author: Francis Stanisci, Jim Wilson
--
--     Purpose: Retreive the physical path for a given share.
--
--        Note: This is only meant to work with servers that use the following share naming
--              convention \\<server_name>\<server_name>_<share_name>
--
--    Required: Share name, per convention above, i.e. only the share name as it would appear above
--
--	======================================================================================
--	Revision History
--	Date		Author     		Desc
--	==========	====================	=============================================
--	10/28/2002	Francis Stanisci	New process 
--	02/15/2005	Jim Wilson		Modified fro sql2005. 
--	08/02/2007	Jim Wilson		Added some diag lines. 
--     	04/16/2010	Steve Ledridge          Added logic to Return Directory if it is passed in as
--                                              a Share Name.
--	05/07/2010	Steve Ledridge		Improved Logic to 
--	======================================================================================

/*
declare @share_name varchar(255)
declare @phy_path varchar(100)

select @share_name = 'pcsqldev01$a_nxt'
select @phy_path = ''
--*/

DECLARE	@cmd			varchar(255)

IF [dbaadmin].[dbo].[dbaudf_GetFileProperty]
	(
	@share_name
	,'Folder'
	,'Path'
	) IS NOT NULL
BEGIN	-- passed in value is a valid path of either Drive or URL
	IF CHARINDEX(':',@share_name) > 0 -- IF CONTAINS A ":" THEN IT MUST BE A DIRECTORY PATH
	BEGIN
		SET @phy_path = @share_name
		RETURN 0			-- PATH IN = PATH OUT = Quick Exit
	END
END
ELSE
BEGIN
	IF CHARINDEX(':',@share_name) > 0 -- IF CONTAINS A ":" THEN IT MUST BE A DIRECTORY PATH
	BEGIN
		SET @phy_path = NULL
		RETURN -1			-- Input is a drive path but not valid - nothing to do.
	END

	SELECT @share_name = dbaadmin.dbo.dbaudf_getShareUNC(@share_name) -- SHARE MUST NOT BE COMPLETE
	--PRINT @share_name /* for debugging */
	IF [dbaadmin].[dbo].[dbaudf_GetFileProperty]
	(
	@share_name
	,'Folder'
	,'Path'
	) IS NULL
	BEGIN
		SET @phy_path = NULL
		RETURN -1		-- Added Server formating to UNC path but still not valid - nothing to do.
	END
END

BEGIN
	Create table #ShareTempTable(path nvarchar(500) null)
	Select @cmd = 'RMTSHARE ' + @share_name

	Insert into #ShareTempTable 
	exec master.sys.xp_cmdshell @cmd

	--select * from #ShareTempTable


	Select @phy_path = substring(path,charindex('h',path)+1,len(path)-charindex('h',path))
	from #ShareTempTable
	where path like 'path%'

	select @phy_path = ltrim(rtrim(@phy_path))
	--print @phy_path

	drop table #ShareTempTable

END

--PRINT @phy_path

/* Sample

	declare @outpath varchar(255)

	--Good Drive Path
	exec dbo.dbasp_get_share_path 'c:\windows\system32', @outpath output
	select @outpath as [Good Drive Path]

	--Bad Drive Path
	exec dbo.dbasp_get_share_path 'c:\windows\system33', @outpath output
	select @outpath AS [Bad Drive Path]

	--Good Short Share Name (no Instance)
	exec dbo.dbasp_get_share_path 'builds', @outpath output
	select @outpath AS [Good Short Share Name no Instance]

	--Bad Short Share Name (no Instance)
	exec dbo.dbasp_get_share_path 'builders', @outpath output
	select @outpath AS [Bad Short Share Name no Instance]

	--Good Long Share Name (no Instance)
	exec dbo.dbasp_get_share_path 'SEAFRESQLDBA01_builds', @outpath output
	select @outpath AS [Good Long Share Name no Instance]

	--Bad Long Share Name (no Instance)
	exec dbo.dbasp_get_share_path 'SEAFRESQLDBA01_builders', @outpath output
	select @outpath AS [Bad Long Share Name no Instance)]

	--Good Share Path (no Instance)
	exec dbo.dbasp_get_share_path '\\SEAFRESQLDBA01\SEAFRESQLDBA01_builds', @outpath output
	select @outpath AS [Good Share Path no Instance)]

	--Bad Share Path (no Instance)
	exec dbo.dbasp_get_share_path '\\SEAFRESQLDBA01\SEAFRESQLDBA01_builders', @outpath output
	select @outpath AS [Bad Share Path no Instance)]


	--Good Short Share Name (with Instance)
	exec dbo.dbasp_get_share_path 'dbasql', @outpath output
	select @outpath AS [Good Short Share Name with Instance]

	--Bad Short Share Name (with Instance)
	exec dbo.dbasp_get_share_path 'dbasqls', @outpath output
	select @outpath AS [Bad Short Share Name with Instance]

	--Good Long Share Name (with Instance)
	exec dbo.dbasp_get_share_path 'SEAFRESQLDBA01_dbasql', @outpath output
	select @outpath AS [Good Long Share Name with Instance]

	--Bad Long Share Name (with Instance)
	exec dbo.dbasp_get_share_path 'SEAFRESQLDBA01_dbasqls', @outpath output
	select @outpath AS [Bad Long Share Name with Instance]

	--Good Share Path (with Instance)
	exec dbo.dbasp_get_share_path '\\SEAFRESQLDBA01\SEAFRESQLDBA01_dbasql', @outpath output
	select @outpath AS [Good Share Path with Instance]

	--Bad Share Path (with Instance)
	exec dbo.dbasp_get_share_path '\\SEAFRESQLDBA01\SEAFRESQLDBA01_dbasqls', @outpath output
	select @outpath AS [Bad Share Path with Instance]
*/
GO
	