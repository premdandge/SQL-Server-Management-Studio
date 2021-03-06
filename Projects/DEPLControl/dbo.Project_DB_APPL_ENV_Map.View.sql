USE [DEPLcontrol]
GO
/****** Object:  View [dbo].[Project_DB_APPL_ENV_Map]    Script Date: 10/4/2013 11:02:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW	[dbo].[Project_DB_APPL_ENV_Map]
AS
WITH		COMP
		AS
		(
		SELECT		DISTINCT
				T1.[project_id]
				,T1.[project_name]
				,T1.[project_version]
		FROM		[gears].[dbo].[active_projects] T1
		)
		,DBNames
		AS
		(
		SELECT	DISTINCT
			T2.project_id
			,T3.component_name DBName
		FROM	[gears].dbo.COMPONENTS T3
		JOIN	[gears].dbo.COMPONENT_TYPE T4
		  ON	T4.component_type_id= T3.component_type_id
		JOIN	[gears].dbo.PROJECT_COMPONENTS T2
		  ON	T3.component_id= T2.component_id
		WHERE	T4.component_type = 'DB'  		  
		)
		,DBNameList
		AS
		(
		SELECT		project_id 
				,dbaadmin.dbo.dbaudf_Concatenate(DBName) DBNames
		FROM		DBNames
		GROUP BY	project_id
		)
		,APPLNames
		AS
		(
		SELECT	DISTINCT
			T2.project_id
			,APPLname
		FROM	[DEPLcontrol].[dbo].[Base_Appl_Info] T5
		JOIN	[gears].dbo.COMPONENTS T3
		  ON	T5.DBname = T3.component_name
		JOIN	[gears].dbo.COMPONENT_TYPE T4
		  ON	T4.component_type_id= T3.component_type_id
		JOIN	[gears].dbo.PROJECT_COMPONENTS T2
		  ON	T3.component_id= T2.component_id
		WHERE	T4.component_type = 'DB'
		)
		,APPLNameList
		AS
		(
		SELECT		project_id 
				,dbaadmin.dbo.dbaudf_Concatenate(APPLNames.APPLname) APPLNames
		FROM		APPLNames
		GROUP BY	project_id
		)
		,ENVnums
		AS
		(
		SELECT	DISTINCT
			T2.project_id
			,ENVnum
		FROM	[DEPLcontrol].[dbo].[Base_Appl_Info] T5
		JOIN	[gears].dbo.COMPONENTS T3
		  ON	T5.DBname = T3.component_name
		JOIN	[gears].dbo.COMPONENT_TYPE T4
		  ON	T4.component_type_id= T3.component_type_id
		JOIN	[gears].dbo.PROJECT_COMPONENTS T2
		  ON	T3.component_id= T2.component_id
		WHERE	T4.component_type = 'DB'
		)
		,ENVNumList
		AS
		(
		SELECT		project_id 
				,dbaadmin.dbo.dbaudf_Concatenate(ENVnum) ENVNums
		FROM		ENVnums
		GROUP BY	project_id
		)
SELECT		 COMP.[project_id]
		,COMP.[project_name]
		,COMP.[project_version]
		,DBNameList.DBNames
		,APPLnameList.APPLNames
		,ENVNumList.ENVNums
FROM		COMP		
JOIN		DBNameList
	ON	DBNameList.project_id = COMP.project_id
JOIN		APPLNameList
	ON	APPLNameList.project_id = COMP.project_id
JOIN		ENVNumList
	ON	ENVNumList.project_id = COMP.project_id

GO
EXEC sys.sp_addextendedproperty @name=N'BuildApplication', @value=N'' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Project_DB_APPL_ENV_Map'
GO
EXEC sys.sp_addextendedproperty @name=N'BuildBranch', @value=N'' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Project_DB_APPL_ENV_Map'
GO
EXEC sys.sp_addextendedproperty @name=N'BuildNumber', @value=N'' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Project_DB_APPL_ENV_Map'
GO
EXEC sys.sp_addextendedproperty @name=N'DeplFileName', @value=N'' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Project_DB_APPL_ENV_Map'
GO
EXEC sys.sp_addextendedproperty @name=N'Version', @value=N'1.0.0' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Project_DB_APPL_ENV_Map'
GO
