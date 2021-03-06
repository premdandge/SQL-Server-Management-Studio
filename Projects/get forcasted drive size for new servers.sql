SELECT [SQLName]
      ,[CheckDate]
      ,[DriveLetter]
      ,[DriveType]
      ,[FileType]
      ,[Dive_MB]
      ,[Free_MB]
      ,[Used_MB]
      ,[Caped_MB]
      ,[DB_Used_MB]
      ,[DB_Shrinkable_MB]
      ,[Adj_Dive_MB]
      ,[adj_DB_Used_MB]
      ,[Pct_Used]
      ,[Adj_Pct_Used]
      ,[WeeksTillTarget]
      ,[WeeksTillFull]
      ,[OneYearForcastGrowthMB]
      ,[OneYearForcastSizeMB]
  FROM [DBAperf_reports].[dbo].[DMV_DiskSpaceUsage]
  
  WHERE SQLNAME LIKE 'FRE%ASPSQL01%'
  
  
GO  
WITH		[SelectedServers]
AS		(
		SELECT		'FREBASPSQL01' AS [ServerName]
		UNION ALL
		SELECT		'FREBSHWSQL01'
		UNION ALL
		SELECT		'FREBSHLSQL01'
		UNION ALL
		SELECT		'FREBPCXSQL01'
		UNION ALL
		SELECT		'FREBGMSSQLA01'
		UNION ALL
		SELECT		'FREBGMSSQLB01'
		)  
SELECT		T2.[ServerName]
		,[SQLName]
		,(SUM([DB_Used_MB])*100/80)/1000.00		AS DB_Used_GB
		,(SUM([OneYearForcastGrowthMB])*100/80)/1000.00	AS Forecasted_Growth_GB
		,((SUM([DB_Used_MB])*100/80)/1000.00)
		+((SUM([OneYearForcastGrowthMB])*100/80)/1000.00)	AS Forecasted_Min_GB
		
		
FROM		[DBAperf_reports].[dbo].[DMV_DiskSpaceUsage] T1
JOIN		[SelectedServers] T2
	ON	T1.[SQLName] LIKE STUFF(T2.[ServerName],4,1,'%')+'%'

GROUP BY	T2.[ServerName]
		,[SQLName]
ORDER BY	T2.[ServerName]
		,[SQLName]



