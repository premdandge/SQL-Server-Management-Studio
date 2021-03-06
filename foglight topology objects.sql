/****** Script for SelectTopNRows command from SSMS  ******/
SELECT [to_id]
      ,[to_type]
      ,[to_unique_id]
      ,[to_object_name]
      ,[to_object_name_hash]
      ,[to_last_updated]
      ,[to_activity_day_number]
      ,[to_activity_current_day]
      ,[to_activity_prev_day_0]
      ,[to_activity_prev_day_1]
      ,[to_activity_daily]
      ,[to_activity_weekly]
  FROM [foglight].[dbo].[topology_object]
  where to_type = 521





  SELECT	[to_type]
		,[tt_name]
		,count(*)

  FROM [foglight].[dbo].[topology_object] T1
  LEFT JOIN [foglight].[dbo].[topology_type] T2
  ON T1.[to_type] = T2.[tt_id]

  GROUP BY	[to_type]
		,[tt_name]