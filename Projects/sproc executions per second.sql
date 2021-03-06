--USE [dbaadmin]
--GO

--DROP TYPE dbo.ResultsValueData
--GO

--CREATE TYPE dbo.ResultsValueData AS TABLE 
--(
--	[Value]	VarChar(900) NOT NULL, 
--	[Data]	VarChar(max) NULL, 
--    PRIMARY KEY ([Value])
--)
--GO




--if object_id('[dbo].[dbaudf_ListShares]') IS NOT NULL
--	DROP FUNCTION [dbo].[dbaudf_ListShares] 
--GO

	
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO
--USE [dbaadmin]
--GO


--CREATE FUNCTION [dbo].[dbaudf_ListShares](@RegistryValues ResultsValueData READONLY)
--RETURNS @ShareList Table
--		(
--		[ShareName]	sysname
--		,[Path]		VarChar(7000)
--		)
--------	USE THIS CODE TO POPULATE THE TABLE VARIABLE FOR THE FUNCTION  ------
----		
----		DECLARE @RegistryValues ResultsValueData
----		INSERT INTO @RegistryValues	
----		EXEC master.dbo.xp_regenumvalues N'HKEY_LOCAL_MACHINE', N'SYSTEM\CurrentControlSet\services\LanmanServer\Shares'		
----
----		SELECT * FROM [dbo].[dbaudf_ListShares](@RegistryValues)
----		
--AS
--BEGIN

--	;WITH		SD
--				AS
--				(			
--				SELECT		dbo.dbaudf_ReturnPart(REPLACE([Value],' - ','|'),1)	[Name]
--							,dbo.dbaudf_ReturnPart(REPLACE([Data],'=','|'),1)	[Attrib]
--							,dbo.dbaudf_ReturnPart(REPLACE([Data],'=','|'),2)	[Value]
--				From		@RegistryValues
--				)
--	INSERT INTO @ShareList
--	SELECT		SD1.[Value]		[ShareName]
--				,SD2.[Value]	[Path]

--	FROM		SD SD1
--	JOIN		SD SD2
--			ON	SD2.[Name] = SD1.[Name]
--			AND	SD1.[Attrib] = 'ShareName'
--			AND	SD2.[Attrib] = 'Path'

--	RETURN
--END

--GO




--DECLARE @RegistryValues ResultsValueData
 
--INSERT INTO @RegistryValues	
--EXEC master.dbo.xp_regenumvalues N'HKEY_LOCAL_MACHINE', N'SYSTEM\CurrentControlSet\services\LanmanServer\Shares'
 
 
--SELECT * FROM [dbo].[dbaudf_ListShares](@RegistryValues)
 
 
--select * From sys.dm_exec_query_stats


--SELECT		*
--FROM		 master.sys.dm_exec_query_stats sp
--outer apply sys.dm_exec_sql_text (sp.plan_handle) as sql_text
 
DROP TABLE #dm_exec_procedure_stats
GO 
SELECT		st.dbid					database_id
			,st.objectid			object_id
			,max(execution_count)	execution_count
INTO		#dm_exec_procedure_stats
FROM		 master.sys.dm_exec_query_stats sp
outer apply sys.dm_exec_sql_text (sp.plan_handle) st 
GROUP BY	st.dbid		
			,st.objectid


WAITFOR DELAY '00:00:10'

 
SELECT		DB_NAME(T1.database_id)								DBName
			,OBJECT_NAME(T1.object_id,T1.database_id)			ProcName

			,(T1.execution_count - T2.execution_count) / 10.0	ExecutionsPerSecond
FROM		(
			SELECT		st.dbid					database_id
						,st.objectid			object_id
						,max(execution_count)	execution_count
			FROM		 master.sys.dm_exec_query_stats sp
			outer apply sys.dm_exec_sql_text (sp.plan_handle) st 
			GROUP BY	st.dbid		
						,st.objectid
			) T1
FULL JOIN	#dm_exec_procedure_stats T2
		ON	T1.database_id	= T2.database_id
		AND	T1.object_id	= T2.object_id

ORDER BY	3 desc



 
 
