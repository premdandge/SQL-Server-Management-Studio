
SELECT		ClusterName
		,ClusterIP
		,ClusterVer
		,MAX(modDate)
FROM		[dbacentral].[dbo].[DBA_ClustInfo]
WHERE		SQLName = 'G1SQLA\A'
GROUP BY	ClusterName
		,ClusterIP
		,ClusterVer
ORDER BY	1,2,3



SELECT		GroupName
		,ResourceType
		,ResourceName
		,ResourceDetail
		,Dependencies
FROM		[dbacentral].[dbo].[DBA_ClustInfo]
WHERE		SQLName = 'G1SQLA\A'
ORDER BY	1,2,3

SELECT [JobName]
      ,[Description]
      ,[Enabled]
      ,[AvgDurationMin]
      ,[JobSteps]
  FROM [dbacentral].[dbo].[DBA_JobInfo]
  WHERE [SQLName] = 'G1SQLA\A'
  AND [JobName] Like 'APPL%'
  ORDER BY 1

  SELECT [JobName]
      ,[Description]
      ,[Enabled]
      ,[AvgDurationMin]
      ,[JobSteps]
  FROM [dbacentral].[dbo].[DBA_JobInfo]
  WHERE [SQLName] = 'G1SQLA\A'
  AND [JobName] Like 'SPCL%'
  ORDER BY 1
