
IF OBJECT_ID('tempdb..#Done') IS NULL
	CREATE TABLE #Done ([Done] VarChar(max))

SET NOCOUNT ON
DECLARE	@Ticket_id	INT = 63805
DECLARE @Done Table ([Done] VarChar(max))
DECLARE @Text VarChar(Max)
SET		@Text = ''

WHILE EXISTS(SELECT 1 FROM deplcontrol.dbo.DBA_DashBoard_GearsTicketDetails (@Ticket_id,1) WHERE Process = 'end' AND Status != 'Completed')
BEGIN
		DELETE	@Done
		SET		@Text = ''
		PRINT	'				-- JUST DONE --'
		PRINT	'--------------------------------------------'
		INSERT INTO @Done
		SELECT	* 
		FROM	( 
				INSERT INTO  #Done
				OUTPUT INSERTED.*
				  SELECT DISTINCT SQL +' '+ APPL + ' ' + DB + ' ' + Status [Done]
				  FROM deplcontrol.dbo.DBA_DashBoard_GearsTicketDetails (@Ticket_id,1)
				  WHERE Status = 'Completed'
				  and (( APPL > '' AND DB > '' ) OR Process = 'end')
				 AND SQL +' '+ APPL + ' ' + DB + ' ' + Status NOT IN (SELECT Done FROM #Done)
				 ) Done 
		SELECT	@Text = @Text + Done +CHAR(13)+CHAR(10)FROM @Done
		PRINT	@Text
		SET		@Text = ''

		PRINT	''
		PRINT	'			    -- NOT DONE --'
		PRINT	'--------------------------------------------'
		SELECT	@Text = @Text + SQL +' '+ APPL + ' ' + DB + ' ' + Status  +CHAR(13)+CHAR(10)
		FROM	deplcontrol.dbo.DBA_DashBoard_GearsTicketDetails (@Ticket_id,1)
		WHERE	Process = 'end' AND Status != 'Completed'

		PRINT	@Text
		PRINT	''
		PRINT	''

		SET @Text = ''

		;WITH		DeployStatus
					AS
					(
					SELECT	SQLName
							, CASE
								WHEN Setup_Status NOT IN('~/Images/2.png','~/Images/0.png')		THEN 'Setup'
								WHEN Restore_Status NOT IN('~/Images/2.png','~/Images/0.png')	THEN 'Restore'
								WHEN Deploy_Status NOT IN('~/Images/2.png','~/Images/0.png')	THEN 'Deploy'
								WHEN End_Status NOT IN('~/Images/2.png','~/Images/0.png')		THEN 'Final'
								End AS [Step]
							, REPLACE(LogPath,'file://','')
							+ CASE
								WHEN Setup_Status NOT IN('~/Images/2.png','~/Images/0.png')		THEN 'DEPLrd_00_start_process.txt'
								WHEN Restore_Status NOT IN('~/Images/2.png','~/Images/0.png')	THEN 'DEPLrd_01_restore_process.txt'
								WHEN Deploy_Status NOT IN('~/Images/2.png','~/Images/0.png')	THEN 'DEPLrd_51_SQLDeploy_process.txt'
								WHEN End_Status NOT IN('~/Images/2.png','~/Images/0.png')		THEN 'DEPLrd_99_end_process.txt'
								End AS [ReportLink]
					FROM	deplcontrol.dbo.DBA_DashBoard_GearsTicket_HL (@Ticket_id,1)
					WHERE	Setup_Status	NOT IN('~/Images/2.png','~/Images/0.png')
						OR	Restore_Status	NOT IN('~/Images/2.png','~/Images/0.png')	
						OR	Deploy_Status	NOT IN('~/Images/2.png','~/Images/0.png')
						OR	End_Status		NOT IN('~/Images/2.png','~/Images/0.png')
					)
		SELECT		@Text = @Text +
					SQLName +CHAR(13)+CHAR(10)
					+CAST([Step] AS CHAR(20))+[ReportLink]+CHAR(13)+CHAR(10)
					+'-------------------------------------------------------------------------------------------------'+CHAR(13)+CHAR(10)
					+COALESCE(nullif(dbaadmin.[dbo].[dbaudf_TailFile]([ReportLink],DEFAULT,20),''),'								-- LOG COULD NOT BE READ --')+CHAR(13)+CHAR(10)
					+'-------------------------------------------------------------------------------------------------'+CHAR(13)+CHAR(10)+CHAR(13)+CHAR(10)+CHAR(13)+CHAR(10)
		FROM		DeployStatus

		PRINT		@Text

		RAISERROR('',-1,-1) WITH NOWAIT
		WAITFOR DELAY '00:00:30' -- HOW OFTEN TO REFRESH
END
			  