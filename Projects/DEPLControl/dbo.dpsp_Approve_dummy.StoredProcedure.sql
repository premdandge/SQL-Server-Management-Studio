USE [DEPLcontrol]
GO
/****** Object:  StoredProcedure [dbo].[dpsp_Approve_dummy]    Script Date: 10/4/2013 11:02:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dpsp_Approve_dummy] 
	(
	@gears_id int = null
	,@auto char(1) = 'n'
	,@runtype nvarchar(10) = null
	,@DBA_override char(1) = 'n'
	)
AS
BEGIN

--INSERT INTO dbo.dummyresults (data)
--SELECT	'EXEC [DEPLcontrol].[dbo].[dpsp_Approve]'
--	+ ' @gears_id = ' +  CAST(@gears_id AS VarChar(20))
--	+ ', @auto = ''' + @auto + ''''
--	+ ', @runtype = ' + COALESCE(''''+@runtype+'''','NULL')
--	+ ', @DBA_override = ''' + @DBA_override + ''''

EXEC [DEPLcontrol].[dbo].[dpsp_Approve]
	 @gears_id
	, @auto
	, @runtype
	, @DBA_override
END

GO
EXEC sys.sp_addextendedproperty @name=N'BuildApplication', @value=N'' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'dpsp_Approve_dummy'
GO
EXEC sys.sp_addextendedproperty @name=N'BuildBranch', @value=N'' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'dpsp_Approve_dummy'
GO
EXEC sys.sp_addextendedproperty @name=N'BuildNumber', @value=N'' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'dpsp_Approve_dummy'
GO
EXEC sys.sp_addextendedproperty @name=N'DeplFileName', @value=N'' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'dpsp_Approve_dummy'
GO
EXEC sys.sp_addextendedproperty @name=N'Version', @value=N'1.0.0' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'dpsp_Approve_dummy'
GO
