USE [dbaadmin]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF object_id('dbasp_CreateMissingSingleColumnStats') IS NOT NULL
	DROP PROCEDURE [dbo].[dbasp_CreateMissingSingleColumnStats]
GO
CREATE PROCEDURE [dbo].[dbasp_CreateMissingSingleColumnStats]
		(
		@DatabaseName	SYSNAME = NULL
		)
AS
BEGIN
	SET	TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET	NOCOUNT		ON
	SET	ANSI_WARNINGS	ON
		
	DECLARE	@Cmd		NVARCHAR(MAX)
		,@Msg		NVARCHAR(MAX)
		,@TableName	SYSNAME
		,@ColumnName	SYSNAME

	DECLARE	@MissingStats	TABLE
				(
				[DatabaseName]	SYSNAME
				,[tablename]	SYSNAME
				,[ColumnName]	SYSNAME
				)
		
	;WITH		StatsList
			AS
			(
			SELECT		s.database_name
					,s.object_id
					,s.stats_id
					,sc.column_id
			FROM		dbaadmin.dbo.vw_AllDB_stats		s WITH(NOLOCK)
			JOIN		dbaadmin.dbo.vw_AllDB_stats_columns	sc WITH(NOLOCK)
				ON	s.database_name		= sc.database_name
				AND	s.object_id		= sc.object_id
				AND	s.stats_id		= sc.stats_id
			WHERE		sc.stats_column_id	= 1	--only look at stats where the statistic is on the first column
				AND	s.database_name = COALESCE(@DatabaseName,s.database_name)
			)
	INSERT INTO	@MissingStats				
	SELECT		o.database_name
			,'['+sch.name+'].['+o.name+']' AS tablename
			,c.name AS ColumnName
	FROM		dbaadmin.dbo.vw_AllDB_objects o WITH(NOLOCK)
	JOIN		dbaadmin.dbo.vw_AllDB_schemas sch WITH(NOLOCK)
		ON	sch.database_name = o.database_name
		AND	o.database_name = COALESCE(@DatabaseName,o.database_name)
		AND	sch.schema_id = o.schema_id
		AND	(
			  o.type = 'U' 
		  OR	  (o.type = 'V' AND o.object_id IN (SELECT OBJECT_ID FROM dbaadmin.dbo.vw_AllDB_indexes WHERE database_name = o.database_name))
			)

	JOIN		dbaadmin.dbo.vw_AllDB_columns c WITH(NOLOCK)
		ON	c.database_name		= o.database_name
		AND	c.object_id		= o.object_id
		AND	c.user_type_id NOT IN (241)		-- ignore XML columns
		AND	c.is_computed = 0
	LEFT JOIN	StatsList s
		ON	c.database_name = s.database_name
		AND	c.object_id = s.object_id
		AND	c.column_id = s.column_id
	WHERE		s.stats_id IS NULL			--only find columns where there are no stats
		



	DECLARE statsCursor CURSOR LOCAL READ_ONLY
	FOR
	SELECT		DatabaseName
			,tablename
			,ColumnName
	FROM		@MissingStats		

	OPEN StatsCursor
	FETCH NEXT FROM StatsCursor INTO @DatabaseName,@TableName,@ColumnName
	WHILE (@@FETCH_STATUS <> -1)
	BEGIN
		IF (@@FETCH_STATUS <> -2)
		BEGIN

			SELECT	@Cmd	= 'USE [' + @DatabaseName + ']; '
					+ 'create statistics [CustomStat_'+REPLACE(@ColumnName,' ','_')+'] on '+@TableName + '(['+@ColumnName+'])'
				,@Msg	= '-- creating stats on '+@TableName+'(['+@ColumnName+'])'

			PRINT @Msg
			PRINT @Cmd
			EXEC (@Cmd)

		END
		FETCH NEXT FROM StatsCursor INTO @DatabaseName,@TableName,@ColumnName
	END
	CLOSE StatsCursor
	DEALLOCATE StatsCursor
END
