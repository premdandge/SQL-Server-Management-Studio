USE [DEPLcontrol]
GO
/****** Object:  View [dbo].[DBA_Dashboard_GearsTicketCounts_Summary_Yesterday]    Script Date: 10/4/2013 11:02:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW	[dbo].[DBA_Dashboard_GearsTicketCounts_Summary_Yesterday]
AS
SELECT		UPPER	(
			CASE
			WHEN InDC = 'N'			THEN 'Not In DEPL Control' 
			WHEN Status = 'COMPLETE'	THEN Status  
			WHEN Approved = 'n'		THEN 'Waiting For Approval' 
			WHEN StartTime >= Getdate()	THEN 'Past Start Time' 
			ELSE Status END
			) AS Status
		, COUNT(*) AS TicketCount
		, COUNT(*) * 5 AS BarWidth
		, '~/Images/Digits/' + SUBSTRING(RIGHT ('000' + CAST(COUNT(*) AS VARCHAR(3)), 3), 1, 1) + '.png' AS Digit1
		, '~/Images/Digits/' + SUBSTRING(RIGHT ('000' + CAST(COUNT(*) AS VARCHAR(3)), 3), 2, 1) + '.png' AS Digit2
		, '~/Images/Digits/' + SUBSTRING(RIGHT ('000' + CAST(COUNT(*) AS VARCHAR(3)), 3), 3, 1) + '.png' AS Digit3 
FROM		DBA_DashBoard_RecentGearsTickets 
WHERE		StartTime >= CAST(CONVERT (VarChar(12), GETDATE()-1, 101) AS DateTime)
	AND	StartTime < CAST(CONVERT (VarChar(12), GETDATE(), 101) AS DateTime)
GROUP BY	UPPER	(
			CASE
			WHEN InDC = 'N'			THEN 'Not In DEPL Control' 
			WHEN Status = 'COMPLETE'	THEN Status  
			WHEN Approved = 'n'		THEN 'Waiting For Approval' 
			WHEN StartTime >= Getdate()	THEN 'Past Start Time' 
			ELSE Status END
			) 

GO
