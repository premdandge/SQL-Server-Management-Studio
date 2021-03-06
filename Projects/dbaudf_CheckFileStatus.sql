USE [dbaadmin]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER function [dbo].[dbaudf_CheckFileStatus] (@filename nvarchar(1000))
returns INT

/**************************************************************
 **  User Defined Function dbaudf_CheckFileStatus                  
 **  Written by Jim Wilson, Getty Images                
 **  November 28, 2005                                      
 **  
 **  This dbaudf is set up to check the file status.
 **  In Use 		= 1
 **  Ready 			= 0
 ***************************************************************/
as

	--======================================================================================
	--	Revision History
	--	Date		Author     		Desc
	--	==========	====================	=============================================
	--	11/28/2005	Jim Wilson		New process
	--	06/02/2006	Jim Wilson		Updated for SQL 2005.
	--	06/13/2012	Steve Ledridge	Modified return code to be int and return any error 
	--								after finding sp_OAGetErrorInfo nor reliable
	--	======================================================================================

/***
declare  @filename varchar(1000)

set @filename = '\\SEADCSQLWVA\SEADCSQLWVA_builds\deployment_logs\SQLDEPL_SEADCSQLWVA_AssetKeyword_F_20060602_1627.log'
set @filename = 'D:\sqldumps\etst.bak'

SET	@filename = 'D:\MSSQL10_50.MSSQLSERVER\MSSQL\Log\SQLjob_logs\xappl_TFS_rsp_check.txt'
--***/

BEGIN
DECLARE @FS				int
DECLARE @OLEResult		int
DECLARE @FileID			int
DECLARE @source			NVARCHAR(255)
DECLARE @description	NVARCHAR(255)
DECLARE @flag			INT

set @source ='Exist'
set @description='Exist'

EXECUTE @OLEResult = master.sys.sp_OACreate 'Scripting.FileSystemObject', @FS OUT
IF @OLEResult <> 0  
   begin
	EXEC master.sys.sp_OAGetErrorInfo NULL, @source OUTPUT, @description OUTPUT 
	goto displayerror
   end

--Open a file
execute @OLEResult = master.sys.sp_OAMethod @FS, 'OpenTextFile', @FileID OUT,@filename , 1
IF @OLEResult <> 0  
   begin
   --PRINT 'Error'
   --PRINT @OLEResult
	SELECT	@flag = isnull(nullif(@OLEResult,-2146828218),1) -- CHANGE INUSE CODE TO 1
			,@description =	CASE @OLEResult
							WHEN -1				THEN 'FileSystemObject could not be created' 
							WHEN -2146828235	THEN 'File Not Found'
 							WHEN -2146828218	THEN 'Permission Denied (in use)'
							ELSE @description
							END
	--PRINT @description						
	EXEC master.sys.sp_OAGetErrorInfo NULL, @source OUTPUT, @description OUTPUT 
   end
ELSE
	BEGIN
		execute @OLEResult = master.sys.sp_OAMethod @FileID, 'Close'
		EXECUTE @OLEResult = master.sys.sp_OADestroy @FileID
	END

EXECUTE @OLEResult = master.sys.sp_OADestroy @FS

DisplayError:
return @flag
END

GO
