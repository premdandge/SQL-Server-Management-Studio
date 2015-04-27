select	count(distinct SQLName) 
	,count(distinct DBName)
	,count(*)
	,sum(cast(data_size_MB as FLOAT)+cast(log_size_MB as FLOAT))
	,sum(cast(row_count as BIGINT))
From dbo.DBA_DBInfo 
