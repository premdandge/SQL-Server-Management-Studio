/****** Script for SelectTopNRows command from SSMS  ******/
SELECT DISTINCT
	':Connect ' + [Server] + CHAR(13) +CHAR(10)
	+ ' :r "Z:\SQLCMD Scripts\SetAllDBSimpleAndSA.sql"' + CHAR(13) +CHAR(10) +'GO' + CHAR(13) +CHAR(10) + CHAR(13) +CHAR(10)

  FROM [dbacentral].[dbo].[FileScan_Daily_Detail_ErrorsByCondition]
  WHERE KnownCondition = 'Backup-NoFullExists' 
  AND ENV != 'PROD'