USE [dbaadmin]
GO
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbaudf_SplitByLines') IS NOT NULL
DROP FUNCTION [dbo].[dbaudf_SplitByLines]
GO


CREATE function [dbo].[dbaudf_SplitByLines] ( @String VARCHAR(max))
returns @SplittedValues TABLE
(
    OccurenceId INT IDENTITY(1,1),
    SplitValue VARCHAR(max)
)
as
BEGIN

	DECLARE	@SplitLength	INT
		,@SplitValue	VarChar(max)
		,@CRLF		CHAR(2)

	SELECT	@CRLF		= CHAR(13)+CHAR(10)
		,@String	= @String + @CRLF

	WHILE LEN(@String) > 0

	BEGIN
		SELECT		@SplitLength	= COALESCE(NULLIF(CHARINDEX(@CRLF,@String),0)-1,LEN(@String))
				,@SplitValue	= LEFT(@String,@SplitLength)
				,@String	= STUFF(@String,1,@SplitLength+2,'')

		INSERT INTO	@SplittedValues([SplitValue])
		SELECT		@SplitValue
	END

	RETURN

END

GO