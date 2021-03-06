

SELECT CASE
			WHEN LEFT([hostname],15) = 'SEAPINTWINUUSVC'	THEN 'Unauthorized Use'
			WHEN LEFT([hostname],12) = 'SEAPWIRPVWEB'	THEN 'Wire Image Film Magic'
			WHEN LEFT([hostname],11) = 'SEAPCRM5IWS'	THEN 'CRM IWS'
			WHEN LEFT([hostname],11) = 'SEAPCRM5WEB'	THEN 'CRM WEB'
			WHEN LEFT([hostname],11) = 'SEAPEWSFEED'	THEN 'FEEDS'
			WHEN LEFT([hostname],11) = 'SEAPGIPVWEB'	THEN 'Getty Images Newsmaker'
			WHEN LEFT([hostname],10) = 'SEAPENTSVC'		THEN 'Enterprise Web Services'
			WHEN LEFT([hostname],10) = 'SEAPAPISVC'		THEN 'API Services'
			WHEN LEFT([hostname],10) = 'SEAPCONWEB'		THEN 'Contour By Getty Images'
			WHEN LEFT([hostname],10) = 'SEAPCTBWEB'		THEN 'Contributor Systems'
			WHEN LEFT([hostname],10) = 'SEAPCTBSVC'		THEN 'Contributor Systems Web Services'
			WHEN LEFT([hostname],10) = 'G1IBSEARCH'		THEN 'Corporate'
			WHEN LEFT([hostname],10) = 'SEAPDELWEB'		THEN 'Delivery'
			WHEN LEFT([hostname],10) = 'SEAPDSOAPP'		THEN 'DSO'
			WHEN LEFT([hostname],10) = 'SEAPJUPWEB'		THEN 'Jupiter Images'
			WHEN LEFT([hostname],10) = 'SEAPPARWEB'		THEN 'Partner Portal'
			WHEN LEFT([hostname],10) = 'SEAPXESWEB'		THEN 'Proxy Connect Gibson'
			WHEN LEFT([hostname],10) = 'SEAPSDTWEB'		THEN 'SDT AssetKeywordingService\MappingService\VocabularyService'
			WHEN LEFT([hostname],10) = 'SEAPSTKAPP'		THEN 'Stacks'
			WHEN LEFT([hostname],10) = 'SEAPTKSWEB'		THEN 'ThinkStock'
			WHEN LEFT([hostname],10) = 'SEAPUNAWEB'		THEN 'Unauthorized Use'
			WHEN LEFT([hostname],10) = 'SEAPWINSVC'		THEN 'Windows Service AssetFlattener\AutoSuggest_KeywordIndexBuilder\BundleRefresh\Indexer\IndexRebuilder\KeywordUpdateService\SchedulingService'
			WHEN LEFT([hostname],10) = 'SEAPWIRWEB'		THEN 'Wire Image Film Magic'
			WHEN LEFT([hostname],10) = 'SEAPVITAPP'		THEN 'Vitria'
			WHEN LEFT([hostname],9)  = 'SEAPGIWEB'		THEN 'Getty Images Newsmaker'
			WHEN LEFT([hostname],9)  = 'SEAPCMSWS'		THEN 'Alfresco Bullseye'
			WHEN LEFT([hostname],9)  = 'SEAPACWEB'		THEN 'Auto Suggest'
			WHEN LEFT([hostname],9)  = 'SEADCXWSA'		THEN 'External Web Services'
			WHEN LEFT([hostname],9)  = 'SEADCIWSA'		THEN 'IWSA Asset Keyword\Keyword Lookup\Keyword'
			WHEN LEFT([hostname],9)  = 'SEADCIWSB'		THEN 'IWSB Internal Account\Asset\Cart\DDS\LightBox\Order'
			WHEN LEFT([hostname],9)  = 'SEAPUUWEB'		THEN 'License Compliance'
			WHEN LEFT([hostname],9)  = 'SEADCPCWS'		THEN 'Product Catalog'
			WHEN LEFT([hostname],9)  = 'SEAPUNAWS'		THEN 'Unauthorized Use Web Service'
			WHEN LEFT([hostname],8)  = 'SEADCSCI'		THEN 'SCI'
			WHEN LEFT([hostname],8)  = 'SEADCCWS'		THEN 'CWS Credit\Tax'
			WHEN LEFT([hostname],7)  = 'GINSWEB'		THEN 'Legacy Editorial'
 
			WHEN LEFT([hostname],10) = 'ASHPENTSVC'		THEN 'DR SITE Enterprise Web Services'
			WHEN LEFT([hostname],10) = 'ASHPDELWEB'		THEN 'DR SITE Delivery'
			WHEN LEFT([hostname],9)  = 'ASHPCMSWS'		THEN 'DR SITE Alfresco Bullseye'
			WHEN LEFT([hostname],9)  = 'ASHPGIWEB'		THEN 'DR SITE Getty Images Newsmaker'
			WHEN LEFT([hostname],8)  = 'ASHPIWSA'		THEN 'DR SITE IWSA Asset Keyword\Keyword Lookup\Keyword'
			WHEN LEFT([hostname],8)  = 'ASHPPCWS'		THEN 'DR SITE Product Catalog'
			WHEN LEFT([hostname],7)  = 'ASHPSCI'		THEN 'DR SITE SCI'
			WHEN LEFT([hostname],7)  = 'ASHPCWS'		THEN 'DR SITE CWS Credit\Tax'
			ELSE 'UNKNOWN: '+ [hostname] END [APPNAME]
      ,[ObjectName]
      ,COUNT(*)
  FROM [dbaadmin].[dbo].[Trace_ObjectCalls]
GROUP BY CASE
			WHEN LEFT([hostname],15) = 'SEAPINTWINUUSVC'	THEN 'Unauthorized Use'
			WHEN LEFT([hostname],12) = 'SEAPWIRPVWEB'	THEN 'Wire Image Film Magic'
			WHEN LEFT([hostname],11) = 'SEAPCRM5IWS'	THEN 'CRM IWS'
			WHEN LEFT([hostname],11) = 'SEAPCRM5WEB'	THEN 'CRM WEB'
			WHEN LEFT([hostname],11) = 'SEAPEWSFEED'	THEN 'FEEDS'
			WHEN LEFT([hostname],11) = 'SEAPGIPVWEB'	THEN 'Getty Images Newsmaker'
			WHEN LEFT([hostname],10) = 'SEAPENTSVC'		THEN 'Enterprise Web Services'
			WHEN LEFT([hostname],10) = 'SEAPAPISVC'		THEN 'API Services'
			WHEN LEFT([hostname],10) = 'SEAPCONWEB'		THEN 'Contour By Getty Images'
			WHEN LEFT([hostname],10) = 'SEAPCTBWEB'		THEN 'Contributor Systems'
			WHEN LEFT([hostname],10) = 'SEAPCTBSVC'		THEN 'Contributor Systems Web Services'
			WHEN LEFT([hostname],10) = 'G1IBSEARCH'		THEN 'Corporate'
			WHEN LEFT([hostname],10) = 'SEAPDELWEB'		THEN 'Delivery'
			WHEN LEFT([hostname],10) = 'SEAPDSOAPP'		THEN 'DSO'
			WHEN LEFT([hostname],10) = 'SEAPJUPWEB'		THEN 'Jupiter Images'
			WHEN LEFT([hostname],10) = 'SEAPPARWEB'		THEN 'Partner Portal'
			WHEN LEFT([hostname],10) = 'SEAPXESWEB'		THEN 'Proxy Connect Gibson'
			WHEN LEFT([hostname],10) = 'SEAPSDTWEB'		THEN 'SDT AssetKeywordingService\MappingService\VocabularyService'
			WHEN LEFT([hostname],10) = 'SEAPSTKAPP'		THEN 'Stacks'
			WHEN LEFT([hostname],10) = 'SEAPTKSWEB'		THEN 'ThinkStock'
			WHEN LEFT([hostname],10) = 'SEAPUNAWEB'		THEN 'Unauthorized Use'
			WHEN LEFT([hostname],10) = 'SEAPWINSVC'		THEN 'Windows Service AssetFlattener\AutoSuggest_KeywordIndexBuilder\BundleRefresh\Indexer\IndexRebuilder\KeywordUpdateService\SchedulingService'
			WHEN LEFT([hostname],10) = 'SEAPWIRWEB'		THEN 'Wire Image Film Magic'
			WHEN LEFT([hostname],10) = 'SEAPVITAPP'		THEN 'Vitria'
			WHEN LEFT([hostname],9)  = 'SEAPGIWEB'		THEN 'Getty Images Newsmaker'
			WHEN LEFT([hostname],9)  = 'SEAPCMSWS'		THEN 'Alfresco Bullseye'
			WHEN LEFT([hostname],9)  = 'SEAPACWEB'		THEN 'Auto Suggest'
			WHEN LEFT([hostname],9)  = 'SEADCXWSA'		THEN 'External Web Services'
			WHEN LEFT([hostname],9)  = 'SEADCIWSA'		THEN 'IWSA Asset Keyword\Keyword Lookup\Keyword'
			WHEN LEFT([hostname],9)  = 'SEADCIWSB'		THEN 'IWSB Internal Account\Asset\Cart\DDS\LightBox\Order'
			WHEN LEFT([hostname],9)  = 'SEAPUUWEB'		THEN 'License Compliance'
			WHEN LEFT([hostname],9)  = 'SEADCPCWS'		THEN 'Product Catalog'
			WHEN LEFT([hostname],9)  = 'SEAPUNAWS'		THEN 'Unauthorized Use Web Service'
			WHEN LEFT([hostname],8)  = 'SEADCSCI'		THEN 'SCI'
			WHEN LEFT([hostname],8)  = 'SEADCCWS'		THEN 'CWS Credit\Tax'
			WHEN LEFT([hostname],7)  = 'GINSWEB'		THEN 'Legacy Editorial'
 
			WHEN LEFT([hostname],10) = 'ASHPENTSVC'		THEN 'DR SITE Enterprise Web Services'
			WHEN LEFT([hostname],10) = 'ASHPDELWEB'		THEN 'DR SITE Delivery'
			WHEN LEFT([hostname],9)  = 'ASHPCMSWS'		THEN 'DR SITE Alfresco Bullseye'
			WHEN LEFT([hostname],9)  = 'ASHPGIWEB'		THEN 'DR SITE Getty Images Newsmaker'
			WHEN LEFT([hostname],8)  = 'ASHPIWSA'		THEN 'DR SITE IWSA Asset Keyword\Keyword Lookup\Keyword'
			WHEN LEFT([hostname],8)  = 'ASHPPCWS'		THEN 'DR SITE Product Catalog'
			WHEN LEFT([hostname],7)  = 'ASHPSCI'		THEN 'DR SITE SCI'
			WHEN LEFT([hostname],7)  = 'ASHPCWS'		THEN 'DR SITE CWS Credit\Tax'
			ELSE 'UNKNOWN: '+ [hostname] END
      ,[ObjectName]
ORDER BY 1,2




SELECT  TE.name AS [EventName] ,
        T.DatabaseName ,
        t.DatabaseID ,
        t.NTDomainName ,
        t.ApplicationName ,
        t.LoginName ,
        t.SPID ,
        t.Duration ,
        t.StartTime ,
        t.EndTime


		
		
		TextData	BinaryData	DatabaseID	TransactionID	LineNumber	NTUserName	NTDomainName		ClientProcessID	ApplicationName	LoginName	SPID	Duration	StartTime	EndTime	Reads	Writes	CPU	Permissions	Severity	EventSubClass	ObjectID	Success	IndexID	IntegerData	ServerName	EventClass	ObjectType	NestLevel	State	Error	Mode	Handle	ObjectName		FileName	OwnerName	RoleName	TargetUserName	DBUserName	LoginSid	TargetLoginName	TargetLoginSid	ColumnPermissions	LinkedServerName	ProviderName	MethodName	RowCounts	RequestID	XactSequence	EventSequence	BigintData1	BigintData2	GUID	IntegerData2	ObjectID2	Type	OwnerID	ParentName	IsSystem	Offset	SourceDatabaseID	SqlHandle	SessionLoginName	PlanHandle	GroupID	trace_event_id	category_id	name



SELECT		HostName
		,ApplicationName
		,DatabaseName
		,
		,
		,
		,
		,
		,

FROM		sys.fn_trace_gettable(CONVERT(VARCHAR(150), ( SELECT TOP 1
                                                              f.[value]
                                                      FROM    sys.fn_trace_getinfo(NULL) f
                                                      WHERE   f.property = 2
                                                    )), DEFAULT) T
        JOIN sys.trace_events TE ON T.EventClass = TE.trace_event_id
WHERE   te.name = 'Data File Auto Grow'
        OR te.name = 'Data File Auto Shrink'
ORDER BY t.StartTime ; 





