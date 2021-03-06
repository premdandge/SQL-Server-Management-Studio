SELECT		session_id	
			,command	
			,host_name	
			,statement_text
			,User_Obj_UsedSpace-User_Obj_FreeSpace	[UnreleasedUserObjSpace]
			,Int_Obj_UsedSpace-Int_Obj_FreeSpace	[UnreleasedIntObjSpace]
			,User_Obj_UsedSpace	
			,User_Obj_FreeSpace	
			,Int_Obj_UsedSpace	
			,Int_Obj_FreeSpace
FROM		(
			select		ts.session_id
						,ex.command 
						,ses.host_name
						,SUBSTRING(st.text, (ex.statement_start_offset/2)+1, 
							((CASE ex.statement_end_offset
								WHEN -1 THEN DATALENGTH(st.text)
								ELSE ex.statement_end_offset
								END - ex.statement_start_offset)/2) + 1) AS statement_text
						,sum(ts.user_objects_alloc_page_count)*8 as 'User_Obj_UsedSpace'
						,sum(ts.user_objects_dealloc_page_count)*8 as 'User_Obj_FreeSpace'
						,sum(ts.internal_objects_alloc_page_count)*8 as 'Int_Obj_UsedSpace'
						,sum(ts.internal_objects_dealloc_page_count)*8 as 'Int_Obj_FreeSpace'
			from		sys.dm_exec_requests as ex
			join		sys.dm_db_task_space_usage as ts 
					on	ex.session_id = ts.session_id 
			join		sys.dm_exec_sessions as ses 
					on	ex.session_id = ses.session_id
			outer apply	sys.dm_exec_sql_text(ex.sql_handle)as st
			group by	ts.session_id
						,ex.command 
						,st.text    
						,ex.statement_start_offset
						,ex.statement_end_offset
						,ses.host_name
			) TempDBUsage
ORDER BY	5 desc
			,6 desc


-- SELECT		*
-- FROM		sys.dm_exec_requests 
 
 
 
-- SELECT		*
-- FROM		sys.dm_exec_sessions dmes
-- LEFT JOIN		sys.dm_db_session_space_usage dmddssu
--	ON		dmes.session_id = dmddssu.session_id
	
	
--sys.dm_exec_requests 	
--sys.dm_db_task_space_usage 
--sys.dm_db_file_space_usage


SELECT SUM(unallocated_extent_page_count) AS [free pages], 
(SUM(unallocated_extent_page_count)*1.0/128) AS [free space in MB]
FROM sys.dm_db_file_space_usage;

SELECT SUM(internal_object_reserved_page_count) AS [internal object pages used],
(SUM(internal_object_reserved_page_count)*1.0/128) AS [internal object space in MB]
FROM sys.dm_db_file_space_usage;

SELECT SUM(user_object_reserved_page_count) AS [user object pages used],
(SUM(user_object_reserved_page_count)*1.0/128) AS [user object space in MB]
FROM sys.dm_db_file_space_usage;

SELECT SUM(size)*1.0/128 AS [size in MB]
FROM tempdb.sys.database_files

GO



;WITH	all_task_usage
		AS
		(
		SELECT		session_id, 
					SUM(internal_objects_alloc_page_count)		AS task_internal_objects_alloc_page_count,
					SUM(internal_objects_dealloc_page_count)	AS task_internal_objects_dealloc_page_count 
		FROM		sys.dm_db_task_space_usage 
		GROUP BY	session_id
		)
		,all_session_usage 
		AS
		(
		SELECT		R1.session_id,
					R1.internal_objects_alloc_page_count + R2.task_internal_objects_alloc_page_count AS session_internal_objects_alloc_page_count,
					R1.internal_objects_dealloc_page_count + R2.task_internal_objects_dealloc_page_count AS session_internal_objects_dealloc_page_count
		FROM		sys.dm_db_session_space_usage AS R1 
		INNER JOIN	all_task_usage AS R2 
			ON		R1.session_id = R2.session_id
		)
		SELECT		*
					,session_internal_objects_alloc_page_count + session_internal_objects_dealloc_page_count AS total_page_count
		FROM		all_session_usage
		where		session_internal_objects_alloc_page_count + session_internal_objects_dealloc_page_count > 0
		order by	4 desc
GO





exec sp_whoisactive


