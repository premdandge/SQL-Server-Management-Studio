USE [DEPLcontrol]
GO
/****** Object:  View [dbo].[DB_APPL_MAP]    Script Date: 10/4/2013 11:02:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW	[dbo].[DB_APPL_MAP]
AS
SELECT		DBName
		,dbaadmin.dbo.dbaudf_Concatenate(APPLName) APPLnameList
FROM		(
		SELECT		DISTINCT 
				DBName
				,APPLName
		FROM		[DEPLcontrol].[dbo].[Base_Appl_Info]
		) T1 
GROUP BY	DBName


GO
EXEC sys.sp_addextendedproperty @name=N'BuildApplication', @value=N'' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'DB_APPL_MAP'
GO
EXEC sys.sp_addextendedproperty @name=N'BuildBranch', @value=N'' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'DB_APPL_MAP'
GO
EXEC sys.sp_addextendedproperty @name=N'BuildNumber', @value=N'' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'DB_APPL_MAP'
GO
EXEC sys.sp_addextendedproperty @name=N'DeplFileName', @value=N'' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'DB_APPL_MAP'
GO
EXEC sys.sp_addextendedproperty @name=N'Version', @value=N'1.0.0' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'DB_APPL_MAP'
GO
