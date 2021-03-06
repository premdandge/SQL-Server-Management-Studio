

select		T1.DriveLetter
		,CAST(TotalSize / power(1024.0,3) AS NUMERIC(10,2)) Size 
		,CAST(FreeSpace / power(1024.0,3) AS NUMERIC(10,2)) Free
		,CAST((TotalSize / power(1024.0,3)) - (FreeSpace / power(1024.0,3)) AS NUMERIC(10,2)) Used
		,CAST(((FreeSpace / power(1024.0,3))*100)/(TotalSize / power(1024.0,3)) AS NUMERIC(10,2)) PctFree 
		,CAST((((TotalSize / power(1024.0,3)) - (FreeSpace / power(1024.0,3)))*100)/(TotalSize / power(1024.0,3)) AS NUMERIC(10,2)) PctFull
		,CAST((T2.ForecastUsed_MB / 1024.0) - (T2.CurrentUsed_MB / 1024.0) AS NUMERIC(10,2)) ProjectedGrowth
		,CAST(COALESCE((T2.ForecastUsed_MB / 1024.0),(TotalSize / power(1024.0,3))) AS NUMERIC(10,2)) RequestSize

		,T2.* 
From dbaadmin.dbo.dbaudf_ListDrives() T1
LEFT JOIN	(
		SELECT	*
		FROM	[DBAperf].[dbo].[DMV_DRIVE_FORECAST_DETAIL]
		WHERE	Rundate		= (SELECT max(rundate) from [DBAperf].[dbo].[DMV_DRIVE_FORECAST_DETAIL])
		  AND	DateTimeValue	= (SELECT MAX(DateTimeValue) FROM [DBAperf].[dbo].[DMV_DRIVE_FORECAST_DETAIL] WHERE DateTimeValue <=  getdate()+365 AND Rundate = (SELECT max(rundate) from [DBAperf].[dbo].[DMV_DRIVE_FORECAST_DETAIL]))
		) T2
	ON	T1.DriveLetter = T2.DriveLetter