ALTER VIEW dbo.DBA_DashBoard_ActiveEnvironment
AS
SELECT	T1.[Environment] 
	,T2.[Servers]
	,T2.[SQL Instances]
	,T1.[Distinct Databases]
	,T1.[Databases]
	,T1.[Total_Size]
	,[ordertbl].[ord] [OrderHelper]
FROM	(
	SELECT [ENVname] [Environment]
		,COUNT(*) [Databases]
		,count(distinct DBName) [Distinct Databases]
		,RIGHT('                       ' + dbaadmin.dbo.dbaudf_FormatNumber
					(
					SUM(CAST(data_size_MB AS Float) + CAST(log_size_MB AS Float))
					/ CASE	WHEN SUM(CAST(data_size_MB AS Float) + CAST(log_size_MB AS Float)) >= 1000000 THEN 1000000
						WHEN SUM(CAST(data_size_MB AS Float) + CAST(log_size_MB AS Float)) >= 1000 THEN 1000
						ELSE 1 END
					) 
					+ CASE	WHEN SUM(CAST(data_size_MB AS Float) + CAST(log_size_MB AS Float)) >= 1000000 THEN 'TB'
						WHEN SUM(CAST(data_size_MB AS Float) + CAST(log_size_MB AS Float)) >= 1000 THEN 'GB'
						ELSE 'MB' END 
					,20) [Total_Size]
	  FROM [dbo].[DBA_DBInfo] DI
	  JOIN dbo.DBA_ServerInfo SI 
	  ON DI.SQLName = SI.SQLName
	WHERE si.Active = 'Y'
	  GROUP BY [ENVname]
	) T1
JOIN	(	
	SELECT	SQLEnv [Environment]
		,count(*) [SQL Instances]
		,count(distinct ServerName) [Servers]
		
	FROM  dbo.DBA_ServerInfo 
	WHERE Active = 'Y'
	GROUP BY SQLEnv
	) T2
ON T1.[Environment] = T2.[Environment]	
JOIN	(
		SELECT 'alpha' [Environment],'1' [ord]
		UNION ALL
		SELECT 'dev','2'
		UNION ALL
		SELECT 'test','3'
		UNION ALL
		SELECT 'load','4'
		UNION ALL
		SELECT 'stage','5'
		UNION ALL
		SELECT 'staging','6'
		UNION ALL
		SELECT 'production','7'
		) [ordertbl]
ON	T1.[Environment] = [ordertbl].[Environment]
 
UNION ALL 
 
SELECT	T1.[Environment] 
	,T2.[Servers]
	,T2.[SQL Instances]
	,T1.[Distinct Databases]
	,T1.[Databases]
	,T1.[Total_Size]
	,100 [OrderHelper]
FROM	(
	SELECT 'Total' [Environment]
		,COUNT(*) [Databases]
		,count(distinct DBName) [Distinct Databases]
		,RIGHT('                        ' + dbaadmin.dbo.dbaudf_FormatNumber
					(
					SUM(CAST(data_size_MB AS Float) + CAST(log_size_MB AS Float))
					/ CASE	WHEN SUM(CAST(data_size_MB AS Float) + CAST(log_size_MB AS Float)) >= 1000000 THEN 1000000
						WHEN SUM(CAST(data_size_MB AS Float) + CAST(log_size_MB AS Float)) >= 1000 THEN 1000
						ELSE 1 END
					) 
					+ CASE	WHEN SUM(CAST(data_size_MB AS Float) + CAST(log_size_MB AS Float)) >= 1000000 THEN 'TB'
						WHEN SUM(CAST(data_size_MB AS Float) + CAST(log_size_MB AS Float)) >= 1000 THEN 'GB'
						ELSE 'MB' END
					,20) [Total_Size]
	  FROM [dbo].[DBA_DBInfo] DI
	  JOIN dbo.DBA_ServerInfo AS SI 
	  ON DI.SQLName = SI.SQLName
	WHERE si.Active = 'Y'
	) T1
JOIN	(	
	SELECT	'Total' [Environment]
		,count(*) [SQL Instances]
		,count(distinct ServerName) [Servers]
	FROM  dbo.DBA_ServerInfo 
	WHERE Active = 'Y'
	) T2
ON T1.[Environment] = T2.[Environment]	 
GO
