USE [dbaadmin]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON

--ALTER FUNCTION [dbo].[dbaudf_FileAccess_Dir]
--						(
DECLARE						@Path VARCHAR(4000)
SET							@Path = 'C:\'
						--)
						--RETURNS
DECLARE						@Dir TABLE
								(
								[Name]					VarChar(255)
								,[ShortName]			VarChar(255)
								,[Attributes]			INT
								,[DateCreated]			DateTime
								,[DateLastAccessed]		DateTime
								,[DateLastModified]		DateTime
								,[Drive]				VarChar(10)
								,[Files]				INT
								,[Size]					FLOAT
								,[Type]					VarChar(100)
								,[Path]					VarChar(1024)
								,[ShortPath]			VarChar(1024)
								) 

/**************************************************************
 **  User Defined Function dbaudf_CheckFileStatus                  
 **  Written by Steve Ledridge, Getty Images                
 **  April 01, 2005                                      
 **  
 **  This dbaudf is set up to read a file into a table.
 ***************************************************************/
--as

--	======================================================================================
--	Revision History
--	Date		Author     		Desc
--	==========	====================	=============================================
--	04/01/2010	Steve Ledridge		New process
--	01/13/2011	Steve Ledridge		Modified to detect ASCII/UNICODE and READ CORRECTLY
--  04/04/2011	Steve Ledridge		Modified to allow @Path to be path and file name.
--	======================================================================================

BEGIN

	DECLARE  @objFileSystem			int
			,@objRootFolder			int
			,@objFSObjects			int
			,@objFSObject			int
			,@objFSObjectCnt		int
			,@objFSObject_Name		VarChar(255)
			,@Property_Value_Str	VarChar(1024)
			,@Property_Value_Int	INT
			,@Property_Value_Dat	DateTime
			,@Property_Value_Flt	Float
			,@Property				VarChar(255)
			,@Loop					int
			,@hr					int
			--,@String				VARCHAR(8000)
			--,@YesOrNo				INT
			--,@OpenAsUnicode			int
			--,@TextStreamTest		nvarchar(10)
			--,@char_value			int
			,@RetryCount			int
		DECLARE @src varchar(255), @desc varchar(255)


	SET	@RetryCount	= 0
	step1:
	EXECUTE	@hr = sp_OACreate  'Scripting.FileSystemObject' , @objFileSystem OUT
		IF @hr != 0 
		BEGIN
			SET @RetryCount = @RetryCount + 1
			IF @RetryCount > 5 
			BEGIN
				GOTO DoneReading
			END
			goto step1
		END


	SET	@RetryCount	= 0
	step2:
	EXECUTE	@hr = sp_OAMethod @objFileSystem, 'GetFolder', @objRootFolder OUT, @path
		IF @hr != 0 
		BEGIN
			SET @RetryCount = @RetryCount + 1
			IF @RetryCount > 5 
			BEGIN
				GOTO DoneReading
			END
			goto step2
		END


	SET	@RetryCount	= 0
	step3:
	EXECUTE @HR = sp_OAGetProperty @objRootFolder, 'SubFolders', @objFSObjects OUTPUT
		IF @hr != 0 
		BEGIN
			SET @RetryCount = @RetryCount + 1
			IF @RetryCount > 5 
			BEGIN
				GOTO DoneReading
			END
			goto step3
		END
		


	SET	@RetryCount	= 0
	step4:
	execute @hr = sp_OAGetProperty   @objFSObjects  , 'count', @objFSObjectCnt OUT
		IF @hr != 0 
		BEGIN
			SET @RetryCount = @RetryCount + 1
			IF @RetryCount > 5 
			BEGIN
				GOTO DoneReading
			END
			goto step4
		END	
		
	SET		@Loop = 0
	WHILE	@Loop <= @objFSObjectCnt
	BEGIN	
		SET		@Loop		= @Loop + 1	
		SET		@Property	= 'Item'
		EXEC	@hr			= sp_OAGetProperty @objFSObjects, 'Item("windows")', @objFSObject OUTPUT,'Windows'
		IF @hr != 0
		BEGIN
			EXEC sp_OAGetErrorInfo NULL, @src OUT, @desc OUT
			SELECT err = convert( varbinary(4), @hr ), Source = @src, Description = @desc
		END
		
		EXEC	@hr			= sp_OAGetProperty @objFSObject, 'name', @objFSObject_Name OUTPUT		
		IF @hr != 0
		BEGIN
			EXEC sp_OAGetErrorInfo @objFileSystem, @src OUT, @desc OUT
			SELECT err = convert( varbinary(4), @hr ), Source = @src, Description = @desc
		END
		
		INSERT INTO @Dir ([Name]) VALUES(@objFSObject_Name)
			
			--SET @Property = 'item("'+CHAR(@DriveLoop)+'")'
			--exec sp_OAGetProperty @Drives,@Property, @Drive OUT
			--exec sp_OAGetProperty @Drive,'DriveLetter', @Results OUT
			--IF @Results = CHAR(@DriveLoop)

		exec sp_OAGetProperty @objFSObject,'ShortName'			, @Property_Value_Str OUT;	UPDATE @Dir SET [ShortName]			= @Property_Value_Str WHERE [Name] = @objFSObject_Name
		exec sp_OAGetProperty @objFSObject,'Attributes'			, @Property_Value_Int OUT;	UPDATE @Dir SET [Attributes]		= @Property_Value_Int WHERE [Name] = @objFSObject_Name
		exec sp_OAGetProperty @objFSObject,'DateCreated'		, @Property_Value_Dat OUT;	UPDATE @Dir SET [DateCreated]		= @Property_Value_Dat WHERE [Name] = @objFSObject_Name
		exec sp_OAGetProperty @objFSObject,'DateLastAccessed'	, @Property_Value_Dat OUT;	UPDATE @Dir SET [DateLastAccessed]	= @Property_Value_Dat WHERE [Name] = @objFSObject_Name
		exec sp_OAGetProperty @objFSObject,'DateLastModified'	, @Property_Value_Dat OUT;	UPDATE @Dir SET [DateLastModified]	= @Property_Value_Dat WHERE [Name] = @objFSObject_Name
		exec sp_OAGetProperty @objFSObject,'Drive'				, @Property_Value_Str OUT;	UPDATE @Dir SET [Drive]				= @Property_Value_Str WHERE [Name] = @objFSObject_Name
		exec sp_OAGetProperty @objFSObject,'Files'				, @Property_Value_Int OUT;	UPDATE @Dir SET [Files]				= @Property_Value_Int WHERE [Name] = @objFSObject_Name
		exec sp_OAGetProperty @objFSObject,'Size'				, @Property_Value_Flt OUT;	UPDATE @Dir SET [Size]				= @Property_Value_Flt WHERE [Name] = @objFSObject_Name
		exec sp_OAGetProperty @objFSObject,'Type'				, @Property_Value_Str OUT;	UPDATE @Dir SET [Type]				= @Property_Value_Str WHERE [Name] = @objFSObject_Name
		exec sp_OAGetProperty @objFSObject,'Path'				, @Property_Value_Str OUT;	UPDATE @Dir SET [Path]				= @Property_Value_Str WHERE [Name] = @objFSObject_Name
		exec sp_OAGetProperty @objFSObject,'ShortPath'			, @Property_Value_Str OUT;	UPDATE @Dir SET [ShortPath]			= @Property_Value_Str WHERE [Name] = @objFSObject_Name

	END		
	
	DoneReading:

	IF @objRootFolder IS NOT NULL
		execute @hr = sp_OAMethod  @objRootFolder, 'Close'
			IF @hr != 0 
			BEGIN
				SET @RetryCount = @RetryCount + 1
				IF @RetryCount > 5 
				BEGIN
					GOTO Destroy
				END
				goto DoneReading
			END		

	Destroy:
	IF @objRootFolder IS NOT NULL			
		EXECUTE  @hr = sp_OADestroy @objRootFolder
			IF @hr != 0 
			BEGIN
				SET @RetryCount = @RetryCount + 1
				IF @RetryCount > 5 
				BEGIN
					GOTO ExitCode
				END
				goto Destroy
			END	
	ExitCode:

	SELECT * FROM @DIR		
	--RETURN 
END
GO



--SELECT * FROM [dbaadmin].[dbo].[dbaudf_FileAccess_Dir]('c:\windows')




