SELECT UPPER([ShortName]) [ShortName]
      ,CASE REPLACE(REPLACE(COALESCE([HostID],'')+ ' ' + COALESCE([IPAddress],''),'NULL',''),'[SELECT]','')
	WHEN '' THEN NULL
	ELSE REPLACE(REPLACE(COALESCE([HostID],'')+ ' ' + COALESCE([IPAddress],''),'NULL',''),'[SELECT]','') END [HostID_IP]
      ,CASE [FQDN]
	WHEN 'NULL' THEN NULL
	WHEN '[SELECT]' THEN NULL
	WHEN '' THEN NULL
	ELSE [FQDN] END AS [FQDN]	
      ,CASE [DomainName]
	WHEN 'NULL' THEN NULL
	WHEN '[SELECT]' THEN NULL
	WHEN '' THEN NULL
	ELSE [DomainName] END AS [DomainName]	
      ,CASE [EnvironmentName]
	WHEN 'NULL' THEN NULL
	WHEN '[SELECT]' THEN NULL
	WHEN '' THEN NULL
	ELSE [EnvironmentName] END AS [EnvironmentName]	
      ,CASE [SLAName]
	WHEN 'NULL' THEN NULL
	WHEN '[SELECT]' THEN NULL
	WHEN '' THEN NULL
	ELSE [SLAName] END AS [SLAName]	
      ,CASE [StandardBuildName]
	WHEN 'NULL' THEN NULL
	WHEN '[SELECT]' THEN NULL
	WHEN '' THEN NULL
	ELSE [StandardBuildName] END AS [StandardBuildName]	
      ,CASE [Locationname]
	WHEN 'NULL' THEN NULL
	WHEN '[SELECT]' THEN NULL
	WHEN '' THEN NULL
	ELSE [Locationname] END AS [Locationname]	
      ,CASE [RackRow]
	WHEN 'NULL' THEN NULL
	WHEN '[SELECT]' THEN NULL
	WHEN '' THEN NULL
	ELSE [RackRow] END AS [RackRow]	
      ,CASE [AIMSSystemFamilyName]
	WHEN 'NULL' THEN NULL
	WHEN '[SELECT]' THEN NULL
	WHEN '' THEN NULL
	ELSE [AIMSSystemFamilyName] END AS [AIMSSystemFamilyName]	
      ,CASE [CustomerName]
	WHEN 'NULL' THEN NULL
	WHEN '[SELECT]' THEN NULL
	WHEN '' THEN NULL
	ELSE [CustomerName] END AS [CustomerName]	
      ,CASE [QAContactName]
	WHEN 'NULL' THEN NULL
	WHEN '[SELECT]' THEN NULL
	WHEN '' THEN NULL
	ELSE [QAContactName] END AS [QAContactName]	
      ,CASE [OwnerName]
	WHEN 'NULL' THEN NULL
	WHEN '[SELECT]' THEN NULL
	WHEN '' THEN NULL
	ELSE [OwnerName] END AS [OwnerName]	
      ,CASE [LocationContactName]
	WHEN 'NULL' THEN NULL
	WHEN '[SELECT]' THEN NULL
	WHEN '' THEN NULL
	ELSE [LocationContactName] END AS [LocationContactName]	
      ,CASE [ServerTypeName]
	WHEN 'NULL' THEN NULL
	WHEN '[SELECT]' THEN NULL
	WHEN '' THEN NULL
	ELSE [ServerTypeName] END AS [ServerTypeName]	
      ,CASE [RegionName]
	WHEN 'NULL' THEN NULL
	WHEN '[SELECT]' THEN NULL
	WHEN '' THEN NULL
	ELSE [RegionName] END AS [RegionName]	
      ,CASE [DataCenterAlertConditionName]
	WHEN 'NULL' THEN NULL
	WHEN '[SELECT]' THEN NULL
	WHEN '' THEN NULL
	ELSE [DataCenterAlertConditionName] END AS [DataCenterAlertConditionName]	
      ,CASE [MaintenanceWindow]
	WHEN 'NULL' THEN NULL
	WHEN '[SELECT]' THEN NULL
	WHEN '' THEN NULL
	ELSE [MaintenanceWindow] END AS [MaintenanceWindow]	
      ,CASE [NotificationGroupName]
	WHEN 'NULL' THEN NULL
	WHEN '[SELECT]' THEN NULL
	WHEN '' THEN NULL
	ELSE [NotificationGroupName] END AS [NotificationGroupName]	
      ,[Retired]	
      ,CASE [CustomerNotes]
	WHEN 'NULL' THEN NULL
	WHEN '[SELECT]' THEN NULL
	WHEN '' THEN NULL
	ELSE [CustomerNotes] END AS [CustomerNotes]	
      ,CASE [Notes]
	WHEN 'NULL' THEN NULL
	WHEN '[SELECT]' THEN NULL
	WHEN '' THEN NULL
	ELSE [Notes] END AS [Notes]	

  FROM [dbaadmin].[dbo].[EnlightenServers]