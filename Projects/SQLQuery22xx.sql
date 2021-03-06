--USE [msdb]
--GO

--IF NOT EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'TempDB Log Full  90%')
--EXEC msdb.dbo.sp_add_alert @name=N'TempDB Log Full  90%', 
--		@message_id=0, 
--		@severity=0, 
--		@enabled=1, 
--		@delay_between_responses=0, 
--		@include_event_description_in=0, 
--		@category_name=N'[Uncategorized]', 
--		@performance_condition=N'SQLServer:Databases|Percent Log Used|tempdb|>|90', 
--		@job_id=N'00000000-0000-0000-0000-000000000000'
--GO

--SELECT * 
--FROM sys.sysprocesses  
--WHERE lastwaittype like 'PAGE%LATCH_%' AND waitresource like '2:%'

--SELECT session_id, wait_duration_ms, resource_description
--FROM sys.dm_os_waiting_tasks
--WHERE wait_type like 'PAGE%LATCH_%' AND resource_description like '2:%'

USE DBAPerf
GO

CREATE TABLE tempdb_space_usage (
  -- This represents the time when the particular row was 
  -- inserted
  dt datetime DEFAULT CURRENT_TIMESTAMP, 
  -- session id of the sessions that were active at the time
  session_id    int DEFAULT null, 
  -- this represents the source DMV of information. It can be 
  -- track instance, session or task based allocation information.
  scope sysname,    
  -- instance level unallocated extent pages in tempdb
  Instance_unallocated_extent_pages bigint,
  -- tempdb pages allocated to verstion store
  version_store_pages    bigint,
  -- tempdb pages allocated to user objects in the instance
  Instance_userobj_alloc_pages bigint,            
  -- tempdb pages allocated to internal objects in the instance
  Instance_internalobj_alloc_pages bigint,
  -- tempdb pages allocated in mixed extents in the instance
  Instance_mixed_extent_alloc_pages bigint,
  -- tempdb pages allocated to user obejcts within this sesssion or task.
  Sess_task_userobj_alloc_pages bigint,            
  -- tempdb user object pages deallocated within this sesssion 
  -- or task.
  Sess_task_userobj_deallocated_pages bigint,
  -- tempdb pages allocated to internal objects within this sesssion 
  -- or task
  Sess_task_internalobj_alloc_pages    bigint,
  -- tempdb internal object pages deallocated within this sesssion or 
  -- task
  Sess_task_internalobj_deallocated_pages bigint,            
  -- query text for the active query for the task    
  query_text    nvarchar(max)    
)
GO
-- Create a clustered index on time column when the data was collected
CREATE CLUSTERED INDEX cidx ON tempdb_space_usage (dt)
GO


CREATE PROC dbasp_sampleTempDbSpaceUsage AS
  -- Instance level tempdb File space usage for all files within tempdb
  INSERT tempdb_space_usage (
    scope,
    Instance_unallocated_extent_pages,
    version_store_pages,
    Instance_userobj_alloc_pages,
    Instance_internalobj_alloc_pages,
    Instance_mixed_extent_alloc_pages)
  SELECT 
    'instance',
    SUM(unallocated_extent_page_count),
    SUM(version_store_reserved_page_count),
    SUM(user_object_reserved_page_count),
    SUM(internal_object_reserved_page_count),
    SUM(mixed_extent_page_count)
  FROM sys.dm_db_file_space_usage
    
    -- 2. tempdb space usage per session 
    --
  INSERT tempdb_space_usage (
    scope,
    session_id,
    Sess_task_userobj_alloc_pages,
    Sess_task_userobj_deallocated_pages,
    Sess_task_internalobj_alloc_pages,
    Sess_task_internalobj_deallocated_pages)
  SELECT
    'session', 
    session_id,
    user_objects_alloc_page_count,
    user_objects_dealloc_page_count,
    internal_objects_alloc_page_count,
    internal_objects_dealloc_page_count
  FROM sys.dm_db_session_space_usage
    WHERE session_id > 50
    -- 3. tempdb space usage per active task
    --
  INSERT tempdb_space_usage (
    scope,
    session_id,
    Sess_task_userobj_alloc_pages,
    Sess_task_userobj_deallocated_pages,
    Sess_task_internalobj_alloc_pages,
    Sess_task_internalobj_deallocated_pages,
    query_text)
  SELECT 
    'task' c1,
    R1.session_id c2,
    R1.user_objects_alloc_page_count c3,
    R1.user_objects_dealloc_page_count c4,
    R1.internal_objects_alloc_page_count c5,
    R1.internal_objects_dealloc_page_count c6,
    R3.text c7
  FROM sys.dm_db_task_space_usage AS R1
    LEFT OUTER JOIN
    sys.dm_exec_requests AS R2
    ON R1.session_id = R2.session_id 
    OUTER APPLY sys.dm_exec_sql_text(R2.sql_handle) AS R3
  WHERE R1.session_id > 50
  
GO



USE [msdb]
GO


EXEC msdb.dbo.sp_update_jobstep @job_name=N'UTIL - DBA Check Periodic'
		,@step_id=1
		,@on_success_action=3
		,@on_fail_action=3
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'UTIL - DBA Check Periodic'
		,@step_name=N'SampleTempDBSpaceUsage'
		,@step_id=2
		,@cmdexec_success_code=0
		,@on_success_action=1
		,@on_fail_action=2
		,@retry_attempts=0 
		,@retry_interval=0 
		,@os_run_priority=0
		,@subsystem=N'TSQL'
		,@command=N'exec dbaPerf.dbo.dbasp_sampleTempDBSpaceUsage'
		,@database_name=N'master'
		,@output_file_name=N'D:\SQL\MSSQL.1\MSSQL\log\SQLjob_logs\util_dba_check_periodic.txt'
		,@flags=2
GO


SELECT
  CONVERT (float, (MAX(version_store_pages +
      Instance_userobj_alloc_pages +
      Instance_internalobj_alloc_pages +
      Instance_mixed_extent_alloc_pages)))/ 128.0
    AS max_tempdb_allocation_MB
  ,CONVERT (float, (AVG(version_store_pages +
      Instance_userobj_alloc_pages +
      Instance_internalobj_alloc_pages +
      Instance_mixed_extent_alloc_pages)))/ 128.0
    AS avg_tempdb_allocation_MB
  ,MAX(version_store_pages) AS max_version_store_pages_allocated,
  MAX(version_store_pages/128.0) AS max_version_store_allocated_space_MB
  ,AVG(version_store_pages) AS max_version_store_pages_allocated,
  AVG(version_store_pages)/ 128.0 AS max_version_store_allocated_space_MB
FROM tempdb_space_usage 
WHERE scope = 'instance'




SELECT top 5 MAX ((Sess_task_internalobj_alloc_pages) - (Sess_task_internalobj_deallocated_pages))
  AS Max_Sess_task_allocated_pages_delta,     query_text
FROM tempdb_space_usage 
WHERE scope = 'task' and session_id > 50
GROUP BY query_text
ORDER BY Max_Sess_task_allocated_pages_delta  DESC

SELECT top 5 AVG ((Sess_task_internalobj_alloc_pages) - (Sess_task_internalobj_deallocated_pages))
  AS Avg_Sess_task_allocated_pages_delta, query_text
FROM tempdb_space_usage 
WHERE scope = 'task' and session_id > 50
GROUP BY query_text
ORDER BY Avg_Sess_task_allocated_pages_delta  DESC


GO


CREATE TABLE #logSpaceStats 
	( 
	databaseName	sysname, 
	logSize			Float,
	logUsed			Float,
	staus			int
	) 

declare @cmd nvarchar(max)

set @cmd = 'dbcc sqlperf(logspace) with no_infomsgs'

insert into #logSpaceStats exec sp_executesql @cmd

select		LSS.DatabaseName			[DATABASE NAME]
			,LSS.logSize				[LOG SPACE ALOCATED]
			,LSS.logUsed				[LOG SPACE USED]
			,SDB.log_reuse_wait_desc	[LOG REUSE WAIT]
FROM		#logSpaceStats	LSS
JOIN		sys.databases	SDB 
		ON	LSS.databasename = SDB.name 
where		LSS.logUsed > 50
GO
DROP TABLE #logSpaceStats
GO



SELECT db.[name] AS [Database Name] ,
 db.recovery_model_desc AS [Recovery Model] ,
 db.log_reuse_wait_desc AS [Log Reuse Wait Description] ,
 ls.cntr_value AS [Log Size (KB)] ,
 lu.cntr_value AS [Log Used (KB)] ,
 CAST(CAST(lu.cntr_value AS FLOAT) / CAST(ls.cntr_value AS FLOAT)
 AS DECIMAL(18,2)) * 100 AS [Log Used %] ,
 db.[compatibility_level] AS [DB Compatibility Level] ,
 db.page_verify_option_desc AS [Page Verify Option]
FROM sys.databases AS db
 INNER JOIN sys.dm_os_performance_counters AS lu
 ON db.name = lu.instance_name
 INNER JOIN sys.dm_os_performance_counters AS ls
 ON db.name = ls.instance_name
WHERE lu.counter_name LIKE 'Log File(s) Used Size (KB)%'
 AND ls.counter_name LIKE 'Log File(s) Size (KB)%' ;
 
 