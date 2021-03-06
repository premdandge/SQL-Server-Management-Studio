USE [WCDS]
GO
/****** Object:  StoredProcedure [dbo].[wedDownloadGet149]    Script Date: 8/1/2013 1:43:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO



ALTER PROCEDURE [dbo].[wedDownloadGet150]
(
	@IndividualId		INT				= 0,
	@CompanyId			INT				= 0,
	@PerspectiveFilter	INT				= 0,
	@SiteId				INT				= 0,
	@StartDate			DATETIME 		= null,
	@EndDate			DATETIME 		= null, 
	@DownloadFilter		INT				= 0,
	@PurchasedFilter	INT				= 0,
	@CrossSitePAandEZA  tinyint			= 0,        --flag is used for Editorial Sub also besides PA and EZA
	@PageNumber			INT 			= 1,
	@ResultsPerPage		INT 			= 30,
	@SortBy				INT 			= 0,
	@SortDirection		INT 			= 0,
	@AssetIdList        Varchar(1000)   = '',
	@TotalRows			INT 			= 0 	output,
	@TotalPages			INT 			= 0 	output,
	@CurrentPage		INT 			= 0		output,
	@oiErrorID			INT 			= 0 	output,
	@ovchErrorMessage	VARCHAR(256) 	= '' 	output
)
AS
BEGIN
DECLARE @Timestamp VarChar(50)
--IF @PerspectiveFilter IS NULL
--	SET @PerspectiveFilter = 0;

/* ---------------------------------------------------------------------------
--	Procedure: wedDownloadGet149
--
--	Revision History
--	Created 	09/28/04	Anne Pau
--				Move FROM GSSearch
--	Modified	10/07/04   Anne Pau
--				Add @DownloadFilter AS input parameter
--  Modified	11/23/2004  Anne Pau
--				Add Download Notes, UserName to recordset
--	Modified	12/2/04   Anne Pau
--				Add @PurchasedFilter input parameter
--	Modified	04/04/05   John Boen
--				"redundant specification" of company ID IN query.  
--				Hopefully will pick up better index.
--	Modifed		09/05/07	Wade Holt
--				cleaned up AND formated code IN general for readability
--				added "SET NOCOUNT ON" to beginning of proc to eliminate extra round-trip
--					to front-END caller. removed this cause not sure WHEN to use it!
--				replace #Summary temporary TABLEwith @Summary SQL TABLEVariable
--				replace #DownloadSummaryWork temporary TABLEwith @DownloadSummaryWork SQL TABLEVariable
--				removed all uses of "SELECT ... INTO ... FROM"
--				added fully qualified owner name to all object references (ie. append "dbo."
--					IN front of all TABLEnames)
--				keep NOCOUNT ON for duration of procedure
--	Modified	11/14/08	Matthew Potter
--				Added additional DownloadFilter value check to support Premium Access
--	Modified	9/22/10		matthew potter
--				Branched from wedDownloadGet (unversioned)
--				Drastically improved query times
--				is provided via another report (just dups for a single asset in a report)
-- Modified		Added optional parameter for filtering based on a comma seperated assetId list 
-- Modified		Added auth check when company perspective is requested 
-- Modified     8/2/2011  Jagdeep Sihota and Lisa Guo
--              To return PA and EZA cross site downloads 
-- Modified     6/29/2011   Jeff Gustafson
--              Added IsEditorial to result set, needed to map fileSizeId for RM image downloads
--
--	Purpose:
--	Retrieves image download history.
--
--	Returns:
--
--	Output variables:
--		@totalRows - Number of rows IN complete history SET
--		@totalPages - Number of pages required to display SET
--		@currentPage - current page returned
--
--		0	:	Success
--		999	:	Can't find user
--		Other	:	Other SQL error
--
--------------------------------------------------------------------------- */
SET @Timestamp = CONVERT(VarChar(50),GetDate(),121);RAISERROR (@Timestamp,-1,-1) WITH NOWAIT;
	-- Turn ON NOCOUNT until final SELECT. ADO doesn't want to see
	-- multiple rowsets returned.
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET ANSI_NULLS ON
	SET ANSI_PADDING ON
	SET ANSI_WARNINGS ON
	SET ARITHABORT ON
	SET QUOTED_IDENTIFIER ON
	SET CONCAT_NULL_YIELDS_NULL ON
	SET XACT_ABORT ON

	DECLARE @PreSortData TABLE
	(
		DownloadDetailId			INT PRIMARY KEY,
		[vchUserName]				[nvarchar](40) NULL,
		[MediaType]					[nvarchar](10) NULL,
		[SortColumn]				sql_variant NULL,
		[IsEditorial]               [bit] NULL
	)

	DECLARE @IndividualDownloads TABLE
	(
		DownloadId					INT PRIMARY KEY
	)

	DECLARE @DownloadsOfInterest TABLE
	(
		DownloadId					INT PRIMARY KEY,
		SiteId						INT
	)

	DECLARE @DownloadDetails TABLE
	(
		[RowNumber]					INT IDENTITY(1,1),
		[DownloadDetailId]			INT PRIMARY KEY,
		[vchUserName]				[nvarchar](40) NULL,
		[MediaType]					[nvarchar](10) NULL,
		[IsEditorial]               [bit] NULL
	)

	DECLARE @DownloadDetails2 TABLE
	(
		[RowNumber]					INT IDENTITY(1,1),
		[PageNumber]				INT,
		[DownloadDetailId]			INT PRIMARY KEY,
		[vchUserName]				[nvarchar](40) NULL,
		[MediaType]					[nvarchar](10) NULL,
		[IsEditorial]               [bit] NULL
	)
		
	DECLARE @DuplicateImages TABLE
	(
		DownloadDetailId			INT PRIMARY KEY,
		ImageID						NVARCHAR(50),
		[Count]						INT
	)

	DECLARE
		@RowCount					INT,
		@iError						INT,
		@iReturnStatus				INT,
		@ErrorId_UnAuthorized		INT,
		@Error_UnAuthorized			VARCHAR(50),
		@Error_Unspecified			VARCHAR(50),
		@CurrentError				VARCHAR(50),
		@TempString					VARCHAR(4000),
		@MAXRowcount				INT,
		@DupsCount					INT,
		@TotalRowsNoDups			INT

	SELECT
		@RowCount					= 0,
		@iError						= 0,
		@ErrorId_UnAuthorized		= 100,
		@Error_Unspecified			= 'Unspecified',
		@Error_UnAuthorized			= 'UnAuthorized',
		@CurrentError				= @Error_Unspecified,
		@MAXRowcount				= 1000,
		@DupsCount					= 0,
		@TotalRowsNoDups			= 0

	DECLARE
		@cstart						DATETIME,
		@cend						DATETIME,
		@minRow						INT,
		@maxRow						INT,
		@startRow					INT,
		@endRow						INT,
		@num						INT

	-- If company perspective, ensure customer is allowed to view company downloads.
	IF @PerspectiveFilter = 1
	BEGIN			
		IF NOT EXISTS
		(
			SELECT 1
			FROM IndividualPreference
			WHERE iIndividualID = @IndividualID AND vchXMLstring LIKE '%key="KAHISTORYACCESS" value="1"%'
		)
		BEGIN
		  SELECT
			@oiErrorID = @ErrorId_UnAuthorized,
			@ovchErrorMessage = @Error_UnAuthorized
			GOTO ErrorHandler
		END
	END

	-- IF the parameter of @StartDate is null, THEN DEFAULT it to an early DATETIME
	IF (@StartDate is null) OR (@StartDate = '')
		SET @StartDate = '1/1/2000'

	-- IF the parameter of @DateEnd is null, THEN DEFAULT it to now
	IF (@EndDate is null) OR (@EndDate = '')
		SET @EndDate = getdate()

	-- Add 1 day to get dates that have a time portion
	SET @EndDate = dateadd(dd,1,@EndDate)	

	
	SELECT		@cstart = CAST(CONVERT(VarChar(20),@startDate,101) AS DateTime) - (DAY(@startDate)-1)

	-- Get min row ID
	SELECT		@minRow = MaxDownloadID
	FROM		dbo.DownloadCreateDate WITH(NOLOCK)
	WHERE		CreatedDate = @cstart
	
	-- set to -1 when dbo.DownloadCreateDate row for the 
	-- year and month of startdate doesn't exist
	set @minRow = ISNULL(@minRow, -1)

	-- Get max row ID
	SELECT @maxRow = MAX (DownloadId)
	FROM dbo.Download (NOLOCK)

	IF (@minRow > @maxRow)
		RETURN -1


	SET @num = 0
	---=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

SET @Timestamp = CONVERT(VarChar(50),GetDate(),121);RAISERROR (@Timestamp,-1,-1) WITH NOWAIT;

	---=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
	-- Get DownloadID rows we are probably interested in for company AND/OR individual
	IF @PerspectiveFilter = 0
	BEGIN
		RAISERROR ('DownloadDetail by IndividualID',-1,-1) WITH NOWAIT;

		INSERT INTO @IndividualDownloads(DownloadID)
		SELECT		DISTINCT DownloadID
		FROM		dbo.DownloadDetail WITH(NOLOCK)
		WHERE		IndividualID = @IndividualId
			AND		DownloadID >= @minRow

		RAISERROR ('%d Records',-1,-1,@@RowCount) WITH NOWAIT;
	END
	ELSE
	BEGIN
		RAISERROR ('DownloadDetail by CompanyID %d %d',-1,-1,@CompanyId,@minRow) WITH NOWAIT;

		INSERT INTO @IndividualDownloads(DownloadID)
		SELECT		DISTINCT DownloadID
		FROM		dbo.DownloadDetail WITH(NOLOCK)
		WHERE		CompanyID = @CompanyId
			AND		DownloadID >= @minRow

		RAISERROR ('%d Records',-1,-1,@@RowCount) WITH NOWAIT;
	END

SET @Timestamp = CONVERT(VarChar(50),GetDate(),121);RAISERROR (@Timestamp,-1,-1) WITH NOWAIT;

IF (SELECT COUNT(*) FROM @IndividualDownloads) > 0
BEGIN
		INSERT		@DownloadsOfInterest (DownloadId,SiteID)
		SELECT		d.DownloadID
					,d.SiteID
		FROM		dbo.Download d WITH(NOLOCK)
		WHERE		d.DownloadID IN (SELECT DownloadID FROM @IndividualDownloads)
			AND		d.CreatedDate	>= @StartDate 
			AND		d.CreatedDate	<= @EndDate
			AND		d.SiteID		=  CASE
										WHEN @SiteID = 0				THEN d.SiteID
										WHEN @CrossSitePAandEZA = 1		THEN d.SiteID
										ELSE @SiteID
										END
	SELECT @Rowcount = @@ROWCOUNT
END
ELSE
	RAISERROR ('NO Records',-1,-1) WITH NOWAIT;


										
	IF @PerspectiveFilter = 0
		PRINT 'only individualId - found ' + STR(@RowCount) + ' rows.'
		
	ELSE
		PRINT 'Only companyId - found ' + STR(@RowCount) + ' rows.'
	
	---=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
    -- Remove downloads from different sites for other types then Editorial Subscription, EZA and PA 
    -- with crossSitePAand EZA Flag is set to 1

SET @Timestamp = CONVERT(VarChar(50),GetDate(),121);RAISERROR (@Timestamp,-1,-1) WITH NOWAIT;

	---=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
	IF (@SiteID <> 0 AND @CrossSitePAandEZA = 1)
	BEGIN
		DELETE		@DownloadsOfInterest 
		FROM		@DownloadsOfInterest  d
		JOIN		dbo.DownloadDetail  dd
			ON		d.DownloadID = dd.DownloadID 
			AND		dd.DownloadID >= @minRow			
			AND		dd.DownloadSourceID NOT IN (3100,3101,3103)
		WHERE		d.SiteID <> @SiteID
		
        SELECT @Rowcount = @@ROWCOUNT
		PRINT 'Numbers of rows after ' + STR(@RowCount) + ' rows.'
	END

	---=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

SET @Timestamp = CONVERT(VarChar(50),GetDate(),121);RAISERROR (@Timestamp,-1,-1) WITH NOWAIT;

	
	-- Get the DownloadDetailID for all the rows we are interested in, sorted in the manner
	-- we need (unbounded)

	-- Prepare for search on asset id list
	SET @AssetIdList = ',' + @AssetIdList + ','

	INSERT INTO @PreSortData(DownloadDetailID,vchUserName,MediaType,IsEditorial,SortColumn)
	SELECT		dd.DownloadDetailId
				,(SELECT vchUserName FROM dbo.Individual WITH(NOLOCK) WHERE iIndividualId = dd.IndividualId) vchUserName
				,(SELECT MediaType FROM dbo.Brand WITH(NOLOCK) WHERE iBrandId = dd.CollectionID) MediaType
				,(SELECT bisEditorialCollectionFlag FROM dbo.Brand WITH(NOLOCK) WHERE iBrandId = dd.CollectionID) IsEditorial
				,CASE @SortBy
				WHEN 0  THEN CAST(dd.DownloadID AS SQL_VARIANT)			
				WHEN 1  THEN CAST(dd.DownloadID AS SQL_VARIANT)			
				WHEN 2  THEN CAST(dd.ImageID AS SQL_VARIANT)			
				WHEN 4  THEN CAST(dd.CollectionName AS SQL_VARIANT)		
				WHEN 6  THEN CAST(dd.PhotographerName AS SQL_VARIANT)	
				WHEN 8  THEN CAST((SELECT vchUserName FROM dbo.Individual WITH(NOLOCK) WHERE iIndividualId = dd.IndividualId)AS SQL_VARIANT)			
				WHEN 10 THEN CAST((SELECT MediaType FROM dbo.Brand WHERE iBrandId = dd.CollectionID)AS SQL_VARIANT)			
				END AS [SortColumn]

	FROM		dbo.DownloadDetail dd WITH(NOLOCK)	
	WHERE		dd.DownloadID >= @minRow
		AND		dd.StatusID NOT IN (951,954)
		
		AND		dd.DownloadSourceID = 
				CASE @DownloadFilter 
					WHEN 0 THEN ISNULL (dd.DownloadSourceID,0)	-- DEFAULT to returns everything
					WHEN 4 THEN ISNULL (dd.DownloadSourceID,0)	-- returns everything 
					WHEN 1 THEN 3100							-- editorial subscription download
					WHEN 2 THEN 3101							-- easy access download
					WHEN 3 THEN 3102							-- RF subscription download (NO LONGER AVAILABLE ON GI.COM SINCE CE SHUTDOWN - 07/2010)
					WHEN 5 THEN 3103							-- Premium Access download
					WHEN 6 THEN 3104							-- Royalty-Free Subscription - (used by Thinkstock)
					WHEN 7 THEN 3105							-- Image Pack download - (used by Thinkstock)
				END
		AND		(
				(@PurchasedFilter = 2 AND dd.OrderID IS NOT NULL)
			OR	(@PurchasedFilter = 3 AND dd.OrderID IS NULL)
			OR	(@PurchasedFilter = 1)
				)
		AND		dd.DownloadID IN	(SELECT DownloadID FROM @DownloadsOfInterest)
					
		AND		(
				@AssetIdList = ',,' 
			OR	CHARINDEX(',' + dd.ImageId + ',', @AssetIdList) > 0
				)	

SET @Timestamp = CONVERT(VarChar(50),GetDate(),121);RAISERROR (@Timestamp,-1,-1) WITH NOWAIT;


	IF @SortDirection=1
		INSERT INTO	@DownloadDetails (DownloadDetailID,vchUserName,MediaType,IsEditorial)
		SELECT		
					[DownloadDetailId]
					,[vchUserName]		
					,[MediaType]
					,[IsEditorial]			
		FROM		@PreSortData
		ORDER BY	[SortColumn] DESC
					,[DownloadDetailId] DESC
	ELSE
		INSERT INTO	@DownloadDetails (DownloadDetailID,vchUserName,MediaType,IsEditorial)
		SELECT		
					[DownloadDetailId]
					,[vchUserName]		
					,[MediaType]
					,[IsEditorial]				
		FROM		@PreSortData
		ORDER BY	[SortColumn]
					,[DownloadDetailId]

SET @Timestamp = CONVERT(VarChar(50),GetDate(),121);RAISERROR (@Timestamp,-1,-1) WITH NOWAIT;


	---=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

	SELECT		@TotalRows = count(*)
	FROM		@PreSortData

	---=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
	INSERT INTO @DuplicateImages
	(
		DownloadDetailId,
		ImageID,
		[Count]
	)
	
	select MAX(t.DownloadDetailId), dd.imageid, CASE
			WHEN Count(dd.ImageID) > 0 THEN Count(dd.ImageID) - 1
			ELSE 0
		END
	from @DownloadDetails t
	Join DownloadDetail dd WITH(nolock) 
			ON		t.DownloadDetailID = dd.DownloadDetailID
	group by imageid, downloadsourceId 		
	
	SET @DupsCount = @@ROWCOUNT
	

SET @Timestamp = CONVERT(VarChar(50),GetDate(),121);RAISERROR (@Timestamp,-1,-1) WITH NOWAIT;

		
	PRINT 'Inserted ' + CAST(@DupsCount AS VARCHAR) + ' rows into @DuplicateImages table.'
	---=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

	-- Remove irrelevant download details from the list
	IF (@DupsCount >0)
	BEGIN		
		DELETE		dd
		FROM		@DownloadDetails dd 
		LEFT JOIN	@DuplicateImages dups 
			ON		dd.DownloadDetailId = dups.DownloadDetailId
		WHERE		dups.DownloadDetailId IS NULL
	END

SET @Timestamp = CONVERT(VarChar(50),GetDate(),121);RAISERROR (@Timestamp,-1,-1) WITH NOWAIT;

	
	PRINT 'Deleted ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows from @DuplicateImages table.'

	INSERT INTO	@DownloadDetails2 (DownloadDetailID,vchUserName,MediaType,IsEditorial)
	SELECT		DownloadDetailID,vchUserName,MediaType,IsEditorial
	FROM		@DownloadDetails
	ORDER BY	RowNumber
	
	SET @TotalRowsNoDups = @@ROWCOUNT

SET @Timestamp = CONVERT(VarChar(50),GetDate(),121);RAISERROR (@Timestamp,-1,-1) WITH NOWAIT;

	
	PRINT 'Inserted ' + CAST(@TotalRowsNoDups AS VARCHAR) + ' rows into @@DownloadDetails2 table.'
	
	UPDATE @DownloadDetails2
	SET PageNumber = (RowNumber/@ResultsPerPage)  + CASE WHEN RowNumber%@ResultsPerPage = 0 THEN 0 ELSE 1 END

SET @Timestamp = CONVERT(VarChar(50),GetDate(),121);RAISERROR (@Timestamp,-1,-1) WITH NOWAIT;

	
	---=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
	IF @ResultsPerPage = 0 BEGIN
		SET @ResultsPerPage	= @TotalRows
		SET @PageNumber		= 1	
	END

	-- Check for condition where all rows are returned on a single 
	-- page. Otherwise, calculate the total pages and set the current page.

	IF @TotalRowsNoDups = @ResultsPerPage BEGIN
		SET @TotalPages		= 1
		SET @CurrentPage	= 1
	END
	ELSE
	BEGIN
		SET @TotalPages		= (@TotalRowsNoDups/@ResultsPerPage)  + CASE WHEN @TotalRowsNoDups%@ResultsPerPage = 0 THEN 0 ELSE 1 END
		SET @CurrentPage	= @PageNumber
	END

SET @Timestamp = CONVERT(VarChar(50),GetDate(),121);RAISERROR (@Timestamp,-1,-1) WITH NOWAIT;


	SELECT
		dd.DownloadDetailID,
		dd.DownloadID,
		dd.ImageID,
		dd.IndividualId,
		dd.CompanyId,
		dd.CompanyTypeID,
		dd.ImageSizeExternalID,
		dd.DownloadSourceID,
		dd.SourceDetailID,
		dd.StatusID,
		dd.OrderID,
		dd.OrderDetailID,
		dd.CollectionID,
		dd.CollectionName,
		tdd.IsEditorial,
		REPLACE(ISNULL (dd.[ImageTitle],''),N'|',N',') as [ImageTitle],
		dd.PhotographerName,
		dd.ImageSource,
		d.CreatedDate as DateCreated,
		CAST (dn.Notes AS NVARCHAR(100)) as [Notes],
		tdd.vchUserName,
		ISNULL (sa.IsNoteRequired, 0) as [IsNoteRequired],
		ISNULL (sa.IsProjectCodeRequired, 0) as [IsProjectCodeRequired],
		CAST (dpc.ProjectCode AS NVARCHAR(70)) as [ProjectCode],
		ISNULL (dups.count, 0) as 'Count',
		tdd.MediaType,
		d.SiteId
	FROM		@DownloadDetails2 tdd
	JOIN		dbo.DownloadDetail dd WITH(NOLOCK) 
		ON		tdd.DownloadDetailID = dd.DownloadDetailID
		AND		dd.DownloadID >= @minRow
	JOIN		dbo.Download d WITH(NOLOCK)
		ON		d.DownloadID = dd.DownloadID
		AND		d.CreatedDate	>= @StartDate 
		AND		d.CreatedDate	<= @EndDate
	LEFT JOIN	dbo.DownloadDetailNote (NOLOCK) dn 
		ON		dd.DownloadDetailID	= dn.DownloadDetailID
	LEFT JOIN	dbo.DownloadDetailProjectCode (NOLOCK) dpc 
		ON		dd.DownloadDetailId = dpc.DownloadDetailId
	LEFT JOIN	dbo.SubscriptionAgreement (NOLOCK) sa 
		ON		dd.SourceDetailId = sa.SubscriptionAgreementId
		AND		dd.DownloadSourceId = 3103
	LEFT JOIN	@DuplicateImages dups 
		ON		dd.DownloadDetailID = dups.DownloadDetailID

	WHERE		tdd.PageNumber = @PageNumber
	ORDER BY	tdd.RowNumber
	

SET @Timestamp = CONVERT(VarChar(50),GetDate(),121);RAISERROR (@Timestamp,-1,-1) WITH NOWAIT;


	RETURN 0

	-------------------------------------------
	-- Error handler
	-------------------------------------------
	ErrorHandler:

	-- RETURN error
	RETURN -999

END

