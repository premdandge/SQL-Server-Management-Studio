USE [users]
GO

SELECT DISTINCT dbo.frmTransactions.TID AS iTicketNbr
		, dbo.frmData.value AS vchSeverity 
		, dbo.frmTransactions.category AS vchSystemName
		, dbo.frmTransactions.subject AS vchSubject
		, dbo.frmTransactions.handler AS vchAssignee
		, dbo.frmTransactions.timeStamp AS dtTimeOpened
		, (SELECT TOP 1 timeStamp 
			FROM dbo.frmNotes with (nolock)
			WHERE (TID = dbo.frmTransactions.TID) 
			ORDER BY timeStamp DESC) AS dtTimeUpdated
		, dbo.frmTransactions.FID 
		, dbo.frmTransactions.stage
		, dbo.frmData.CID                  
FROM		dbo.frmTransactions with (nolock)
JOIN		dbo.frmData with (nolock) 
	ON	dbo.frmTransactions.TID = dbo.frmData.TID 
	AND	dbo.frmTransactions.handler = 'SEA SQL DBA Team'

	
	
  --WHERE (   (dbo.frmTransactions.FID = 840) 
  --      AND (dbo.frmTransactions.stage = 1) 
  --      AND (dbo.frmData.CID = 14249) 
  --      AND (dbo.frmTransactions.category2 NOT IN ('Disk Space', 'Production Triage','Backup Failure')) 
  --      )         
  --       OR (   (dbo.frmTransactions.FID = 840) 
  --          AND (dbo.frmTransactions.stage = 1) 
  --          AND (dbo.frmData.CID = 14249) 
  --          AND (   (dbo.frmTransactions.category IS NULL) 
  --               or (dbo.frmTransactions.category2 IS NULL) 
  --               or (dbo.frmTransactions.category3 IS NULL) 
  --              )
  --          )


