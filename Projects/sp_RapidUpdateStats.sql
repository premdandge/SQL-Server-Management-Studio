USE WCDS

set nocount on;
declare		@RowModCounterThreshold			bigint
		,@RowModPercentageThreshold		decimal(3,2)
		,@StatsSamplingPercentage		tinyint
		,@Msg					nvarchar(max)
		,@Cmd					nvarchar(max)
		,@QualifiedTableName			nvarchar(256)
		,@DoUpdateStats				bit
		,@Description				nvarchar(max)
		,@CurrentRowModCounter			bigint
	
/* 
User options:
@RowModCounterThreshold -- if a table gets more than this many rows inserted/updated/deleted, update its statistics
@RowModPercentageThreshold -- if a table gets more than this percentage of rows inserted/updated/deleted, update its statistics
@StatsSamplingPercentage:
	--set to 0 to update stats in RESAMPLE mode. 
	--set to null to update statistics in their default configuration
	--set to a value between 1 and 100 to update statistics by scanning that percentage of the table's rows
*/
set @RowModCounterThreshold		= 1000 --change if 1K rows have changed
set @RowModPercentageThreshold		= 0.01 --change to a 5% threshold
set @StatsSamplingPercentage		= 0 --use resample mode


/* First, create the temporary tables we'll be using to query the system DMVs
Querying them directly in the cursor will not scale in systems with large numbers of tables & indexes
*/
if object_id('tempdb..#TableList') is null
begin
	create table #TableList
	(SchemaName sysname not null
	,TableName sysname not null
	,ObjectID bigint not null
	,EstimatedTableRowcount bigint not null
	,primary key clustered (SchemaName,TableName))
end
truncate table #TableLIst

if object_id('tempdb..#IndexList') is null
begin
	create table #IndexList
	(SchemaName sysname not null
	,TableName sysname not null
	,IndexName sysname not null
	,IndexRowModCounter bigint not null
	,IndexPercentageOfTable decimal(5,4) not null
	,primary key clustered (SchemaName,TableName,IndexName))
end
truncate table #IndexList

if object_id('tempdb..#StatsList') is null
begin
	create table #StatsList
	(TableObjectID bigint not null
	,QualifiedTableName nvarchar(256) not null 
	,DoUpdateStats bit not null
	,Description nvarchar(500) --This should be above the maximum description size
	)
	create clustered index NonUniquePK on #StatsList (TableObjectID)
end
truncate table #StatsList

-- Get the list of tables & indexed views and their estimated rowcounts
insert into	#TableList
				(
				SchemaName
				,TableName
				,ObjectID
				,EstimatedTableRowcount
				)
select		s.name			as SchemaName
			,t.name		as TableName
			,t.object_id	as ObjectID
			,sum(p.rows)	as EstimatedTableRowcount
from		sys.objects t
inner join	sys.schemas s
	on		s.schema_id=t.schema_id
inner join	sys.partitions p
	on		t.object_id=p.object_id
where		p.index_id in (0,1)			-- look at the base table only
	and		t.type in ('U','V')		-- only look at tables and views
group by	s.name
			,t.name
			,t.object_id

/*
Get the list of indexes for each table or indexed view, the rowmodcounter for each index,
and the percentage of the table's rows the index covers (to account for filtered indexes)
 */
 
insert into	#IndexList
				(
				SchemaName
				,TableName
				,IndexName
				,IndexPercentageOfTable
				,IndexRowModCounter
				)
select		s.name														as SchemaName
			,t.name														as TableName
			,si.name													as IndexName
			,cast(SUM(p.rows)*1.0 /(SUM(p.rows)+1)*1.0 as decimal(5,4))	as IndexPercentageOfTable
			,max(si.rowmodctr)											as IndexRowModCounter
from		sysindexes si
join		sys.objects t
	on		si.id		= t.object_id
join		sys.schemas s
	on		t.schema_id	= s.schema_id
join		sys.partitions p
	on		p.object_id	= t.object_id
	and		p.index_id	= si.indid
where		si.name is not null
group by	s.name
			, t.name
			, si.name

/* 
This big query has all of the logic.
It takes index information, table information, and compares
it to the parameters passed in above to determine whether
each index is valid for having its stats updated.

This is a little tricky because indexes are checked
to see whether they are out of date. However, statistics are updated
at the table level. 
*/
insert into	#StatsList
				(
				TableObjectID
				,QualifiedTableName
				,DoUpdateStats
				,Description
				)
select		src.TableObjectID
			,src.QualifiedTableName
			,DoUpdateStats =	case when src.IsRowModCounterAboveThreshold=1 or src.IsPercentageChangedAboveThreshold=1 then 1 else 0 end
			,Description = 'Index ['+src.IndexName+N']: ' 
				+	case 
					when src.IsRowModCounterAboveThreshold=1 
					then 'Rowmodcounter (' + convert(nvarchar(50),src.IndexRowModCounter) +') is greater than the threshold (' +convert(nvarchar,@RowModCounterThreshold)+N') '
					else N'' 
					end
				+	case 
					when src.IndexRowModCounter / (src.EstimatedTableRowcount * src.IndexPercentageOfTable) > @RowModPercentageThreshold
					then N'Percentage changed (' +convert(nvarchar(50),convert(float,src.AdjustedPercentageChanged*100.0)) +N'%) is above threshold (' +convert(nvarchar(50),convert(float,@RowModPercentageThreshold*100.0)) +N'%) '
					else N'' 
					end
				+	case 
					when src.IsRowModCounterAboveThreshold=0 and src.IsPercentageChangedAboveThreshold=0
					then 'Neither rowmodcounter or percentage changed is above threshold for index '+src.IndexName
					else N'' 
					end
				+N' '
from		(	
			select		TableObjectID=t.ObjectID
						,QualifiedTableName					= N'['+t.SchemaName+N'].['+t.TableName+N']'
						,IsRowModCounterAboveThreshold		= case 
																when i.IndexRowModCounter > @RowModCounterThreshold
																then 1 
																else 0 
																end
						,IsPercentageChangedAboveThreshold	= case
																when i.IndexRowModCounter / (t.EstimatedTableRowcount * i.IndexPercentageOfTable) > @RowModPercentageThreshold
																then 1 
																else 0 
																end
						,AdjustedPercentageChanged			= i.IndexRowModCounter / (t.EstimatedTableRowcount * i.IndexPercentageOfTable)
						,i.IndexRowModCounter
						,t.EstimatedTableRowcount
						,i.IndexName
						,i.IndexPercentageOfTable
			from		#TableList t
			inner join	#IndexList i
				on		t.SchemaName				= i.SchemaName
				and		t.TableName					= i.TableName
			where		t.EstimatedTableRowcount	> 0
				and	i.IndexPercentageOfTable	> 0
			) as src

/* Use the cursor to get information at a table level
This includes aggregating the descriptions up from the various indexes
to the table
*/
DECLARE		Csr		CURSOR
LOCAL READ_ONLY 
FOR 
SELECT		s.QualifiedTableName
			,MAX(case when s.DoUpdateStats=1 then 1 else 0 end)		as DoUpdateStats
			,	(
				select +N', '+s2.Description
				from #StatsList s2
				where s2.TableObjectID=s.TableObjectID
				for xml path ('')
				)													as DescriptionList
FROM		#StatsList s
GROUP BY	s.QualifiedTableName
			, s.TableObjectID
ORDER BY	s.QualifiedTableName
			, s.TableObjectID

open Csr
FETCH NEXT FROM Csr INTO @QualifiedTableName,@DoUpdateStats,@Description
WHILE (@@fetch_status <> -1)
BEGIN
	IF (@@fetch_status <> -2)
	BEGIN
		-- print the message regardless of whether we update stats
		set @Msg=
			case when @DoUpdateStats=1
				then N'--Updating stats on '
				else N'--Do not update stats on ' 
				end
			+@QualifiedTableName+' because '+@Description
		
		print @Msg
		-- if the table is valid to have its stats updated, update the statistics
		if @DoUpdateStats=1
		begin
			set @cmd='update statistics '+@QualifiedTableName
				+case 
					when @StatsSamplingPercentage=0 
						then ' with resample'
					when @StatsSamplingPercentage is not null
						then ' with sample '+convert(nvarchar,@StatsSamplingPercentage)+' percent'
					else N'' end
				
				print (@cmd) --print the command to execute
				exec (@Cmd) --execute the command
		end
	END
	FETCH NEXT FROM Csr INTO @QualifiedTableName,@DoUpdateStats,@Description
END

CLOSE Csr
DEALLOCATE Csr
