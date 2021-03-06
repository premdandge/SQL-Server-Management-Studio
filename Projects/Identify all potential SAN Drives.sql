
SELECT	di.SQLName
		,CASE si.SystemModel WHEN 'VMware, Inc. VMware Virtual Platform' THEN 'Y' ELSE 'N' END AS [VM]
		,di.DriveName 

From [dbacentral].[dbo].[DBA_DiskInfo] di
JOIN [dbacentral].[dbo].[DBA_ServerInfo] si
	ON	di.SQLName = si.SQLName
	
WHERE	isnull(si.Active,'y') = 'y' 
	AND	isnull(di.active,'y') = 'y'
	AND	(
		isnull([SAN],'y') = 'y'
	OR	si.SystemModel = 'VMware, Inc. VMware Virtual Platform'		
		)
	AND (
		di.DriveName != 'C'
	OR	si.SystemModel = 'VMware, Inc. VMware Virtual Platform'
		)  
  
  