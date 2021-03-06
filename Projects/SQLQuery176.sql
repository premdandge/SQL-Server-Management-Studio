'EXEC msdb.dbo.sp_delete_jobstep @job_name=N''DBA - Test LogParser'', @step_id=1
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N''DBA - Test LogParser'', @step_name=N''SQL ERRORLOG'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=4, 
		@on_success_step_id=2, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''SET NOCOUNT ON

DECLARE @cmd		VarChar(8000)
DECLARE @central_server	sysname
DECLARE @Machine	sysname
DECLARE @Instance	sysname
DECLARE @Last		DateTime
DECLARE @LastDate	VarChar(12)
DECLARE @LastTime	VarChar(8)
DECLARE	@LogBufferMin	INT

SET		@LogBufferMin = -20

SELECT		@Last	= DATEADD(mi,@LogBufferMin,MAX(CAST(left(RIGHT(''''00000000'''' + convert(varchar,sjh.run_date),8),4) 
			+ ''''-'''' + SUBSTRING(RIGHT(''''00000000'''' + convert(varchar,sjh.run_date),8),5,2) 
			+ ''''-'''' + right(RIGHT(''''00000000'''' + convert(varchar,sjh.run_date),8),2) 
			+ '''' '''' + left(RIGHT(''''000000'''' + convert(varchar,sjh.run_time),6),2) 
			+ '''':'''' +	SUBSTRING(RIGHT(''''000000'''' + convert(varchar,sjh.run_time),6), 3,2) 
			+ '''':'''' + right(RIGHT(''''000000'''' + convert(varchar,sjh.run_time),6), 2) AS DateTime)))
FROM		msdb..sysjobhistory sjh
Inner Join	msdb..sysjobs sj
	ON	sj.job_id = sjh.job_id
WHERE		step_id = 0
	AND	sj.name = ''''DBA - Test LogParser'''' 		
	AND	sjh.run_status = 1	

SET		@Last = COALESCE(@Last,CAST(''''2000-01-01 00:00:00'''' AS DateTime))	 

SELECT		@Machine	= REPLACE(@@servername,''''\''''+@@SERVICENAME,'''''''')
		,@Instance	= REPLACE(@@SERVICENAME,''''MSSQLSERVER'''','''''''')
		,@LastDate	= LEFT(CONVERT(VarChar(20),@Last,120),10)
		,@LastTime	= RIGHT(CONVERT(VarChar(20),@Last,120),8)
		,@central_server = env_detail 
from		dbaadmin.dbo.Local_ServerEnviro 
where		env_type = ''''CentralServer''''

Select	@cmd = ''''%windir%\system32\LogParser "file:\\''''
		+ @central_server + ''''\'''' + @central_server 
		+ ''''_filescan\Aggregates\Queries\''''
		+ ''''SQLErrorLog2.sql?startdate='''' + @LastDate + ''''+starttime=''''
		+ @LastTime +''''+machine=''''
		+ @Machine + ''''+instance=''''
		+ @Instance + ''''+machineinstance=''''
		+ UPPER(REPLACE(@@servername,''''\'''',''''$'''')) + ''''+OutputFile=\\'''' 
		+ @central_server + ''''\'''' + @central_server 
		+ ''''_filescan\Aggregates\SQLErrorLOG_''''
		+ UPPER(REPLACE(@@servername,''''\'''',''''$''''))
		+ ''''.w3c" -i:TEXTLINE -o:W3C -fileMode:0 -encodeDelim''''
		
exec master..xp_cmdshell @cmd'', 
		@database_name=N''master'', 
		@output_file_name=N''\\NYCMVSQLDEV01\NYCMVSQLDEV01_log\SQLjob_logs\DBA - Test LogParser.txt'', 
		@flags=6
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N''DBA - Test LogParser'', @step_name=N''SQLAGENT'', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''SET NOCOUNT ON

DECLARE @cmd		VarChar(8000)
DECLARE @central_server	sysname
DECLARE @Machine	sysname
DECLARE @Instance	sysname
DECLARE @Last		DateTime
DECLARE @LastDate	VarChar(12)
DECLARE @LastTime	VarChar(8)
DECLARE	@LogBufferMin	INT

SET		@LogBufferMin = -20

SELECT		@Last	= DATEADD(mi,@LogBufferMin,MAX(CAST(left(RIGHT(''''00000000'''' + convert(varchar,sjh.run_date),8),4) 
			+ ''''-'''' + SUBSTRING(RIGHT(''''00000000'''' + convert(varchar,sjh.run_date),8),5,2) 
			+ ''''-'''' + right(RIGHT(''''00000000'''' + convert(varchar,sjh.run_date),8),2) 
			+ '''' '''' + left(RIGHT(''''000000'''' + convert(varchar,sjh.run_time),6),2) 
			+ '''':'''' +	SUBSTRING(RIGHT(''''000000'''' + convert(varchar,sjh.run_time),6), 3,2) 
			+ '''':'''' + right(RIGHT(''''000000'''' + convert(varchar,sjh.run_time),6), 2) AS DateTime)))
FROM		msdb..sysjobhistory sjh
Inner Join	msdb..sysjobs sj
	ON	sj.job_id = sjh.job_id
WHERE		step_id = 0
	AND	sj.name = ''''DBA - Test LogParser'''' 		
	AND	sjh.run_status = 1	

SET		@Last = COALESCE(@Last,CAST(''''2000-01-01 00:00:00'''' AS DateTime))	 

SELECT		@Machine	= REPLACE(@@servername,''''\''''+@@SERVICENAME,'''''''')
		,@Instance	= REPLACE(@@SERVICENAME,''''MSSQLSERVER'''','''''''')
		,@LastDate	= LEFT(CONVERT(VarChar(20),@Last,120),10)
		,@LastTime	= RIGHT(CONVERT(VarChar(20),@Last,120),8)
		,@central_server = env_detail 
from		dbaadmin.dbo.Local_ServerEnviro 
where		env_type = ''''CentralServer''''

IF @Instance = '''''''' SET @Instance = ''''-''''

Select	@cmd = ''''%windir%\system32\LogParser "file:\\''''
		+ @central_server + ''''\'''' + @central_server 
		+ ''''_filescan\Aggregates\Queries\''''
		+ ''''SQLAGENT.sql?startdate='''' + @LastDate + ''''+starttime=''''
		+ @LastTime +''''+machine=''''
		+ @Machine + ''''+instance=''''
		+ @Instance + ''''+machineinstance=''''
		+ UPPER(REPLACE(@@servername,''''\'''',''''$'''')) + ''''+OutputFile=\\'''' 
		+ @central_server + ''''\'''' + @central_server 
		+ ''''_filescan\Aggregates\SQLAGENT_''''
		+ UPPER(REPLACE(@@servername,''''\'''',''''$''''))
		+ ''''.w3c" -i:TSV -o:W3C -fileMode:0 -iSeparator:space''''
		+ '''' -iHeaderFile:"\\''''
		+ @central_server + ''''\'''' + @central_server 
		+ ''''_filescan\Aggregates\Queries\SQLAGENT.tsv"''''
		
exec master..xp_cmdshell @cmd'', 
		@database_name=N''master'', 
		@output_file_name=N''\\NYCMVSQLDEV01\NYCMVSQLDEV01_log\SQLjob_logs\DBA - Test LogParser.txt'', 
		@flags=6
GO'
