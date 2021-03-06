USE [WCDS]
GO
/****** Object:  StoredProcedure [dbo].[wedVitriaBatch_DownloadUpdate_new]    Script Date: 12/08/2011 14:16:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

ALTER PROCEDURE [dbo].[wedVitriaBatch_DownloadUpdate_new]
	@oiErrorID		int = 0 OUTPUT, 		-- App-defined error if non-zero. 
	@ovchErrorMessage	varchar(256) = '' OUTPUT 	-- Text description of app-defined error
AS

---------------------------------------------------------------------------
---------------------------------------------------------------------------
--	Procedure: wedVitriaBatch_DownloadUpdate
--	For: Getty Images
--
--      Dependencies:
--		wedVitriaDownloadFailedUpdate (sp)
--		wedVitriaBatchIdGet (sp)
--		wedGetErrorInfo (sp)
--
--	Purpose: Called as SQL Job every 3 minutes.
--		Grabs unprocessed records from Vitria import table Download_imp,
--		feeds them to existing proc for update to NSCDS
--
--	REVISION HISTORY
--	Date		Author		Comment
--	----------	--------------	-----------------------------------
--	01/19/2002	David Hume	Initial creation.
--  05/06/2004  Larry Krueger Modified to not process a downloadid of 0.  Please see comments below.
--  01/05/2005	John Boen	Cleansed @vchUserID to remove any "%xy" character sets, replacing htem with their ascii equiv...
--  08/13/2010  Steve Mayszak Premium access will no longer rely on delivery updates and therefore will not change customers counts or notify vitria when an update occurs
--	Return Values:
--	   0	Success.
--	-999	Some failure; check output parameters.
---------------------------------------------------------------------------
---------------------------------------------------------------------------
BEGIN
	----------------------------------------
	-- SETUP
	----------------------------------------
	-- Environmental settings
	SET NOCOUNT ON

	-- Establish error handler constants
	-- and standard vars
	DECLARE
		@Error_Update_Failed	varchar(50),
		@Error_Unspecified		varchar(50), -- in
		@CurrentError			varchar(50),
		@RowCount				int,
		@Error					int,
		@iReturnStatus			int,
		@iSprocErrorID			int,
		@iErr					int,
		@vchErrMsg				varchar(256)

	SELECT
		@Error_Update_Failed	= 'Update_Failed',
		@Error_Unspecified		= 'Unspecified',
		@CurrentError			= @Error_Unspecified,
		@RowCount				= 0,
		@error					= 0,
		@oiErrorID				= 0,
		@iSprocErrorID			= 0

	-- proc-specific vars
	DECLARE
		@iDownloadImportId		integer,			-- NOT NULL
		@iImportBatchId			integer,
		@dtImported				datetime,			-- NOT NULL
		@iJobId					integer,			-- NOT NULL
		@dtRequestCreated		datetime,			-- NOT NULL
		@dtLastModified			datetime,			-- NOT NULL
		@iStatusId				integer,
		@vchErrorDesc			varchar(2000),
		@iBatchId				integer,
		@iDownloadId			integer,
		@iUserId				integer,
		@iOriginalSystemID		INT,
		@iObjectID				INT,
		@vchTransactionType		nvarchar(20),
		@vchObjectClass			nvarchar (20) 

	----------------------------------------
	-- MAIN
	-- Functionality Begins here	
	----------------------------------------

	-- CREATE QUEUE TABLE IF IT DOES NOT EXIST
	IF OBJECT_ID('dbo.Download_imp_queue') IS NULL
		EXEC('
		CREATE TABLE	dbo.Download_imp_queue
		(
			iDownloadImportId	int	 primary key clustered,
			iDownloadId			sysname,
			iStatusId			int,
			dtImported			datetime,
			iRecorded			bit,
			iBatchID			INT
		)')
		
	-- CLEAN UP ALL PROCESSED RECORDS FROM QUEUE TABLE
	DELETE		dbo.Download_imp_queue
	WHERE		iRecorded = 1
	
	-- CHECK FOR LEFT OVER PROCESSING ON LAST RUN
	IF (SELECT count(*) FROM dbo.Download_imp_queue WITH(NOLOCK)) > 0
		GOTO ProcessQueue

	-- check to see if there are any rows 
	-- that need processing
	SELECT @RowCount=COUNT(*)
	FROM dbo.Download_imp (nolock)
	WHERE iImportBatchId is NULL

	SELECT 	@error = @@Error
	IF (@error<>0)
	BEGIN
		SELECT @CurrentError = @Error_Unspecified
		GOTO ErrorHandler
	END

	-- exit if no rows to process
	IF (@RowCount=0)
	BEGIN
		PRINT 'No download_imp rows to process.'
        RETURN 0
	END

	-- get batch id
	EXEC @iReturnStatus = dbo.wedVitriaBatchIdGet 
		@iBatchID OUTPUT,
		@iErr OUTPUT,
		@vchErrMsg OUTPUT

	SET @error = @@Error
	IF (@iReturnStatus<>0) or (@ierr<>0) or (@error<>0)
	BEGIN
		SELECT @CurrentError = @Error_Unspecified
		GOTO ErrorHandler
	END

	UPDATE TOP (5000) dbo.Download_imp 
		SET		iImportBatchID = @iBatchID
	OUTPUT 		Inserted.iDownloadImportId
				,Inserted.vchOrderId
				,Inserted.iStatusId
				,Inserted.dtImported
				,case isnumeric(Inserted.vchOrderId) WHEN 1 THEN 0 ELSE NULL END
				,@iBatchID
	INTO		dbo.Download_imp_queue
	FROM		dbo.Download_imp WITH (READPAST)
	WHERE		iImportBatchID IS NULL

	ProcessQueue:
	
	-- GET OLD BATCHID IF REPROCESSING
	IF @iBatchID IS NULL
		SELECT		TOP 1
					@iBatchID = iBatchID
		FROM		dbo.Download_imp_queue
		WHERE		iBatchID IS NOT NULL
	
	-- BATCH UPDATE ERRORS
	UPDATE		dbo.Download_imp
		SET		vchErrorDesc	= 'Error: Non-Numeric Order Id Encountered while processing this record'
				,iImportBatchID	= @iBatchID
	WHERE		iDownloadImportId IN	(
										SELECT		iDownloadImportId
										FROM		dbo.Download_imp_queue
										WHERE		iRecorded IS NULL
										)

	-- BATCH MARK ERRORS AS RECORDED
	UPDATE		dbo.Download_imp_queue
		SET		iRecorded	= 1
	WHERE		iRecorded IS NULL

	DECLARE ImportCursor CURSOR
	FOR 
	SELECT		iDownloadImportId
				,iDownloadId
				,iStatusId
	FROM		dbo.Download_imp_queue
	WHERE		iRecorded = 0

	OPEN ImportCursor
	FETCH NEXT FROM ImportCursor INTO @iDownloadImportId,@iDownloadId,@iStatusId
	WHILE (@@fetch_status <> -1)
	BEGIN
		IF (@@fetch_status <> -2)
		BEGIN
			BEGIN TRANSACTION
			
			EXEC dbo.wedVitriaDownloadStatusUpdate
				@iDownloadId		= @iDownloadId,
				@iStatusId			= @iStatusId,
				@oiErrorId			= @oiErrorId		OUTPUT,
				@ovchErrorMessage	= @ovchErrorMessage OUTPUT

			IF @oiErrorId <> 0
			BEGIN
				UPDATE		dbo.Download_imp
					SET		vchErrorDesc = @ovchErrorMessage
				WHERE		iDownloadImportId = @iDownloadImportId
			END

			DECLARE NotifyCursor CURSOR
			FOR 
			SELECT		DownloadDetailID
			FROM		dbo.DownloadDetail WITH(nolock)
			WHERE		DownloadId = @iDownloadId
				AND		DownloadSourceId <> 3103		-- do not notify vitria of premium access changes
				AND		EXISTS(SELECT 1 FROM dbo.Download_imp WITH(nolock) WHERE iDownloadImportId = @iDownloadImportId AND iStatusId >= 0)

			OPEN NotifyCursor
			FETCH NEXT FROM NotifyCursor INTO @iObjectID
			WHILE (@@fetch_status <> -1)
			BEGIN
				IF (@@fetch_status <> -2)
				BEGIN

					EXEC VitriaEventMsg null, @iObjectID, 'Update', 'DownloadDetail'

				END
				FETCH NEXT FROM NotifyCursor INTO @iObjectID
			END
			CLOSE NotifyCursor
			DEALLOCATE NotifyCursor

			UPDATE		dbo.Download_imp_queue
				SET		iRecorded = 1
			WHERE		iDownloadImportId = @iDownloadImportId
			
			COMMIT TRANSACTION
		END
		FETCH NEXT FROM ImportCursor INTO @iDownloadImportId,@iDownloadId,@iStatusId
	END
	CLOSE ImportCursor
	DEALLOCATE ImportCursor

	DELETE		dbo.Download_imp_queue
	WHERE		iRecorded = 1

----------------------------------------
-- ERROR HANDLER / EXIT
----------------------------------------
ErrorHandler:
	-- call error-lookup proc, filling OUTPUT parameters
	EXECUTE @iReturnStatus  = wedGetErrorInfo
			@CurrentError,
			@oiErrorID OUTPUT,
			@ovchErrorMessage OUTPUT
	IF @iReturnStatus <> 0
	BEGIN
		SELECT @oiErrorID = -999
		SELECT @ovchErrorMessage = 'Call to wedGetErrorInfo failed with ' + @CurrentError + '; ' + convert(char(30),getdate())
	END
	RETURN -999

END

