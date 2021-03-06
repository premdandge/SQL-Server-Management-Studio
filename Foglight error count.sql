--/****** Script for SelectTopNRows command from SSMS  ******/
--SELECT TOP 1000 [alarm_id]
--      ,[id]
--      ,[source_id]
--      ,[message]
--      ,[topology_object_id]
--      ,[is_cleared]
--      ,[is_acknowledged]
--      ,[cleared_time]
--      ,[created_time]
--      ,[severity]
--      ,[cleared_by]
--      ,[ack_time]
--      ,[ack_by]
--      ,[source_name]
--      ,[rule_id]
--      ,[user_defined_data]
--      ,[auto_ack]


SELECT	[topology_object_id]
	,SUM(CASE [severity] WHEN 4 THEN 1 ELSE 0 END)
	,SUM(CASE [severity] WHEN 3 THEN 1 ELSE 0 END)
	,SUM(CASE [severity] WHEN 2 THEN 1 ELSE 0 END)
	,SUM(CASE [severity] WHEN 1 THEN 1 ELSE 0 END)
	,SUM(CASE [severity] WHEN 0 THEN 1 ELSE 0 END)
  FROM [foglight].[dbo].[alarm_alarm]
 -- WHERE [topology_object_id]  IN (SELECT [to_unique_id] FROM [foglight].[dbo].[topology_object] where to_type = 521)




  GROUP BY [topology_object_id]
  ORDER BY 2 desc, 3 desc, 4 desc, 5 desc, 6 desc