USE [DEPLcontrol]
GO
/****** Object:  UserDefinedFunction [dbo].[GetDEPLInstanceID]    Script Date: 10/4/2013 11:02:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetDEPLInstanceID]()
		RETURNS sysname
		AS
		BEGIN
			DECLARE @DEPLInstanceID sysname

			SELECT		@DEPLInstanceID = COALESCE(CAST(Value AS sysname),'11111111-1111-1111-1111-111111111111')
			FROM		DEPLInfo.sys.fn_listextendedproperty('DEPLInstanceID', default, default, default, default, default, default) 

			RETURN @DEPLInstanceID
		END
GO
