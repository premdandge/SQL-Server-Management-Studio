/****** Script for SelectTopNRows command from SSMS  ******/
SELECT top 1000 [DeliveryLogID]
      ,[IndividualID]
      ,[Status]
      ,[RequestName]
      ,[RequestDate]
      ,[ClientName]
      ,[ClientIP]
      ,[AssetSizeBytes]
      ,[DownloadDurationMS]
      ,[ContextType]
      ,[ContextID]
  FROM [DeliveryLog].[dbo].[DeliveryLog]
  --WHERE ClientIP like '10.192.65%'
  --WHERE ClientIP IN ('10.240.48.10','10.240.48.15')
   order by 5 desc




-- TODAY
SELECT		Status
		,[1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12]
		,[13],[14],[15],[16],[17],[18],[19],[20],[21],[22],[23],[24]
FROM		(
		SELECT		[Status]
				,DATEPART(hour,[RequestDate]) [Hour]
				,COUNT(*) [Cnt]
		FROM		[DeliveryLog].[dbo].[DeliveryLog]
		WHERE		[RequestDate] >= CAST(CONVERT(VarChar(12),getdate(),101) AS DateTime)
			AND	[RequestDate] < getdate() 
		GROUP BY	DATEPART(hour,[RequestDate]),[Status]
		) src
pivot		(
		sum(Cnt) FOR [Hour] IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16],[17],[18],[19],[20],[21],[22],[23],[24])
		) pvt
WHERE		Status IS NOT NULL;

--YESTERDAY
SELECT		Status
		,[1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12]
		,[13],[14],[15],[16],[17],[18],[19],[20],[21],[22],[23],[24]
FROM		(
		SELECT		[Status]
				,DATEPART(hour,[RequestDate]) [Hour]
				,COUNT(*) [Cnt]
		FROM		[DeliveryLog].[dbo].[DeliveryLog]
		WHERE		[RequestDate] >= CAST(CONVERT(VarChar(12),getdate()-1,101) AS DateTime)
			AND	[RequestDate] < CAST(CONVERT(VarChar(12),getdate(),101) AS DateTime)
		GROUP BY	DATEPART(hour,[RequestDate]),[Status]
		) src
pivot		(
		sum(Cnt) FOR [Hour] IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16],[17],[18],[19],[20],[21],[22],[23],[24])
		) pvt
WHERE		Status IS NOT NULL;





