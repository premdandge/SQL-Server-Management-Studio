USE users
GO

DROP VIEW	DBA_DashBoard_OpenNOCTickets
GO
CREATE VIEW	DBA_DashBoard_OpenNOCTickets
AS
Select		DISTINCT
		top 100 PERCENT
                t.TID [Ticket],
                'http://intranet.seattle.gettyimages.com/forms/TransactionView.asp?commID=376&comm=Change%20Control&TID={0}&service=Change%20Control%20Request' [Ticket Mask], 
                u.name [Sender],
                u.ID [Sender ID],
                'http://intranet.seattle.gettyimages.com/search/user_record.asp?id={0}' [Sender ID Mask],
                CASE t.priority
			WHEN 1 THEN 'Low'
			WHEN 2 THEN 'Medium'
			WHEN 3 THEN 'High'
			WHEN 4 THEN 'Critical'
			ELSE 'Project' END [Priority], 
                t.subject [Subject], 
		t.workflowTitle [Current Workflow Stage],
                t.category [Category 1], 
                t.category2 [Category 2], 
                t.category3 [Category 3], 
                'NOC Ticket' [Service], 
                [severity].value [Severity],
                [name].value [Name],  
                t.timeStamp [Date Received], 
                t.timeStamp2 [Date Resolved], 
                t.timeStamp3 [Date Updated], 
                t.handler [Handler],
                'Open' [Status]
from		dbo.frmTransactions t
Join		dbo.tbl_users u 
	on	u.ID = t.userID
	and	t.FID = 840		--NOC Ticket
	and	t.status = '0'		--0=Open,1=Closed
	and	t.handler = 'SEA SQL DBA Team'	
Join		dbo.frmData [severity]
	on	[severity].TID = t.TID
	AND	[severity].CID ='14249'	--Severity
Join		dbo.frmData [name]
	on	[name].TID = t.TID
	AND	[name].CID ='5099'	--Name
Order By t.timeStamp desc
GO


DROP VIEW	DBA_DashBoard_ClosedNOCTickets
GO
CREATE VIEW	DBA_DashBoard_ClosedNOCTickets
AS
Select		DISTINCT
		top 100 PERCENT
                t.TID [Ticket],
                'http://intranet.seattle.gettyimages.com/forms/TransactionView.asp?commID=376&comm=Change%20Control&TID={0}&service=Change%20Control%20Request' [Ticket Mask], 
                u.name [Sender],
                u.ID [Sender ID],
                'http://intranet.seattle.gettyimages.com/search/user_record.asp?id={0}' [Sender ID Mask],
                CASE t.priority
			WHEN 1 THEN 'Low'
			WHEN 2 THEN 'Medium'
			WHEN 3 THEN 'High'
			WHEN 4 THEN 'Critical'
			ELSE 'Project' END [Priority], 
                t.subject [Subject], 
		t.workflowTitle [Current Workflow Stage],
                t.category [Category 1], 
                t.category2 [Category 2], 
                t.category3 [Category 3], 
                'NOC Ticket' [Service], 
                [severity].value [Severity],
                [name].value [Name],  
                t.timeStamp [Date Received], 
                t.timeStamp2 [Date Resolved], 
                t.timeStamp3 [Date Updated], 
                t.handler [Handler],
                'Open' [Status]
from		dbo.frmTransactions t
Join		dbo.tbl_users u 
	on	u.ID = t.userID
	and	t.FID = 840		--NOC Ticket
	and	t.status = '1'		--0=Open,1=Closed
	and	t.handler = 'SEA SQL DBA Team'	
Join		dbo.frmData [severity]
	on	[severity].TID = t.TID
	AND	[severity].CID ='14249'	--Severity
Join		dbo.frmData [name]
	on	[name].TID = t.TID
	AND	[name].CID ='5099'	--Name
Order By t.timeStamp desc
GO
