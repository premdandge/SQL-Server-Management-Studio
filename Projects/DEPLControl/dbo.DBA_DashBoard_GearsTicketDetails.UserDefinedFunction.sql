USE [DEPLcontrol]
GO
/****** Object:  UserDefinedFunction [dbo].[DBA_DashBoard_GearsTicketDetails]    Script Date: 10/4/2013 11:02:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[DBA_DashBoard_GearsTicketDetails] 
(
	@Gears_ID int
	,@UseRemote bit = 0 
)
RETURNS 
@Results TABLE 
(
	[APPL]		sysname
	,[DB]		sysname
	,[Process]	sysname
	,[Type]		sysname
	,[Detail]	sysname
	,[Status]	sysname
	,[SQL]		sysname
	,[Domain]	sysname
	,[Base]		sysname
	,[Go]		VarChar(128)
	,[RecordOrder]	Int
	,[seq_id]	Int
	,[reqdet_id]	Int
)
AS
BEGIN
	INSERT INTO	@Results
	SELECT		[APPL]
			,[DB]
			,[Process]
			,[Type]
			,[Detail]
			,[Status]
			,[SQL]
			,[Domain]
			,[Base]
			,[Go]
			,[RecordOrder]
			,[seq_id]
			,[reqdet_id]
	FROM		[DEPLcontrol].[dbo].[DBA_DashBoard_GearsTicketDetails_Local_Amer]
	WHERE		[Gears_id]=@Gears_ID
	
	IF @UseRemote = 0
	BEGIN
		INSERT INTO	@Results
		SELECT		[APPL]
				,[DB]
				,[Process]
				,[Type]
				,[Detail]
				,[Status]
				,[SQL]
				,[Domain]
				,[Base]
				,[Go]
				,[RecordOrder]
				,[seq_id]
				,[reqdet_id]
		FROM		[DEPLcontrol].[dbo].[DBA_DashBoard_GearsTicketDetails_Local_Stage]
		WHERE		[Gears_id]=@Gears_ID	
		
		INSERT INTO	@Results
		SELECT		[APPL]
				,[DB]
				,[Process]
				,[Type]
				,[Detail]
				,[Status]
				,[SQL]
				,[Domain]
				,[Base]
				,[Go]
				,[RecordOrder]
				,[seq_id]
				,[reqdet_id]
		FROM		[DEPLcontrol].[dbo].[DBA_DashBoard_GearsTicketDetails_Local_Prod]
		WHERE		[Gears_id]=@Gears_ID	
	END
	ELSE
	BEGIN
		INSERT INTO	@Results
		SELECT		[APPL]
				,[DB]
				,[Process]
				,[Type]
				,[Detail]
				,[Status]
				,[SQL]
				,[Domain]
				,[Base]
				,[Go]
				,[RecordOrder]
				,[seq_id]
				,[reqdet_id]
		FROM		[DEPLcontrol].[dbo].[DBA_DashBoard_GearsTicketDetails_Remote_Stage]
		WHERE		[Gears_id]=@Gears_ID	
		
		INSERT INTO	@Results
		SELECT		[APPL]
				,[DB]
				,[Process]
				,[Type]
				,[Detail]
				,[Status]
				,[SQL]
				,[Domain]
				,[Base]
				,[Go]
				,[RecordOrder]
				,[seq_id]
				,[reqdet_id]
		FROM		[DEPLcontrol].[dbo].[DBA_DashBoard_GearsTicketDetails_Remote_Prod]
		WHERE		[Gears_id]=@Gears_ID	
	END
	RETURN 
END

GO
