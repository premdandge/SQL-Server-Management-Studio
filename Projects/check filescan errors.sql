      
SELECT		[dbacentral].dbo.dbaudf_ReturnPairValue([FixData],',','=','job') JobName
		,[dbacentral].dbo.dbaudf_ReturnPairValue([FixData],',','=','step') StepName
		,count(*) ErrorCount
		,dbaadmin.dbo.dbaudf_ConcatenateUnique([Machine]) MachineNames
   
FROM		[dbacentral].[dbo].[FileScan_History] T1
--LEFT JOIN	[dbaadmin].[dbo].[dba_serverinfo] T2
--	ON	T1.Machine = T2.SERVERNAME
  
WHERE		[EventDateTime] >= CAST(CONVERT(VARCHAR(12),GetDate()-1,101)AS DATETIME)
	AND	[KnownCondition] = 'AgentJob-StepFailed'
	AND	[dbacentral].dbo.dbaudf_ReturnPairValue([FixData],',','=','step') != '(Job outcome)'
	--AND	[dbacentral].dbo.dbaudf_ReturnPairValue([FixData],',','=','step') IS NOT NULL
	  
GROUP BY 	[dbacentral].dbo.dbaudf_ReturnPairValue([FixData],',','=','job') 
		,[dbacentral].dbo.dbaudf_ReturnPairValue([FixData],',','=','step') 
		
WITH ROLLUP
ORDER BY	3 desc --1,2 desc







SELECT		[Machine]
		,[EventDateTime]
		,[dbacentral].dbo.dbaudf_ReturnPairValue([FixData],',','=','job') 
		,[dbacentral].dbo.dbaudf_ReturnPairValue([FixData],',','=','step')
		,[FixData]
FROM		[dbacentral].[dbo].[FileScan_History] T1
WHERE		[EventDateTime] >= CAST(CONVERT(VARCHAR(12),GetDate()-1,101)AS DATETIME)
	AND	[KnownCondition] = 'AgentJob-StepFailed'
	AND	[dbacentral].dbo.dbaudf_ReturnPairValue([FixData],',','=','job') = 'syspolicy_purge_history'
	AND	[dbacentral].dbo.dbaudf_ReturnPairValue([FixData],',','=','step') != '(Job outcome)'
	AND	[dbacentral].dbo.dbaudf_ReturnPairValue([FixData],',','=','step') != 'DMV Blocks Capture'