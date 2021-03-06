
-- EXEC [dbaadmin].[dbo].[dbasp_Mirror_Database] 'G1SQLB\B','MirrorTest'





USE [dbaadmin]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ADD DYNAMIC LINKED SERVER SO PROCEDURE DOES NOT FAIL
IF  EXISTS (SELECT srv.name FROM sys.servers srv WHERE srv.server_id != 0 AND srv.name = N'DYN_DBA_RMT')
	EXEC master.dbo.sp_dropserver @server=N'DYN_DBA_RMT', @droplogins='droplogins'
	
EXEC sp_addlinkedserver @server='DYN_DBA_RMT',@srvproduct='',@provider='SQLNCLI',@datasrc=@@ServerName
GO

IF OBJECT_ID('dbasp_Mirror_Database') IS NOT NULL
	DROP PROCEDURE [dbo].[dbasp_Mirror_Database]
GO

CREATE PROCEDURE [dbo].[dbasp_Mirror_Database]
	(
	@ServerName	SYSNAME		= ''
	,@DBName	SYSNAME		= ''
	,@BackupPath	VARCHAR(MAX)	= NULL
	,@RestorePath	VARCHAR(MAX)	= NULL
	,@FullReset	BIT		= 1
	)
AS

	SET NOCOUNT ON
	SET ANSI_NULLS ON
	SET ANSI_WARNINGS ON

	DECLARE		@MostRecent_Full	DATETIME
			,@MostRecent_Diff	DATETIME
			,@MostRecent_Log	DATETIME
			,@CMD			VARCHAR(8000)
			,@COPY_CMD		VARCHAR(8000)
			,@DELETE_CMD		VARCHAR(MAX)
			,@FileName		VARCHAR(MAX)
			,@AgentJob		SYSNAME
			,@MachineName		SYSNAME
			,@RemoteEndpointName	SYSNAME
			,@RemoteEndpointID	INT
			,@RemoteEndpointPort	INT
			,@LocalEndpointName	SYSNAME
			,@LocalEndpointID	INT
			,@LocalEndpointPort	INT
			,@CreateEndpoint	VarChar(8000)
			,@Local_FQDN		SYSNAME
			,@Remote_FQDN		SYSNAME
			,@ShareName		VarChar(500)
			,@LogPath		VarChar(100)
			,@DataPath		VarChar(100)
			
	DECLARE		@CopyAndDeletes		TABLE (CopyCMD VarChar(max),DeleteCMD VarChar(max))
				
	SELECT		@MachineName	= LEFT(@ServerName,CHARINDEX('\',@ServerName+'\')-1)
			,@BackupPath	= COALESCE(@BackupPath,'\\'+@MachineName+'\'+REPLACE(@ServerName,'\','$')+'_backup')
			,@RestorePath	= COALESCE(@RestorePath,'\\'+ LEFT(@@ServerName,CHARINDEX('\',@@ServerName+'\')-1)+'\'+REPLACE(@@ServerName,'\','$')+'_backup')
			,@COPY_CMD	= 'ROBOCOPY '+@BackupPath+' '+@RestorePath+' '
			,@CreateEndpoint = 'CREATE ENDPOINT [Mirroring] 
	AUTHORIZATION [sa]
	STATE=STARTED
	AS TCP (LISTENER_PORT = 5022, LISTENER_IP = ALL)
	FOR DATA_MIRRORING (ROLE = PARTNER, AUTHENTICATION = WINDOWS NEGOTIATE
, ENCRYPTION = REQUIRED ALGORITHM RC4)'

	-- ADD DYNAMIC LINKED SERVER
	IF  EXISTS (SELECT srv.name FROM sys.servers srv WHERE srv.server_id != 0 AND srv.name = N'DYN_DBA_RMT')
		EXEC master.dbo.sp_dropserver @server=N'DYN_DBA_RMT', @droplogins='droplogins'
  
	EXEC sp_addlinkedserver @server='DYN_DBA_RMT',@srvproduct='',@provider='SQLNCLI',@datasrc=@ServerName
	EXEC master.dbo.sp_serveroption @server=N'DYN_DBA_RMT', @optname=N'rpc', @optvalue=N'true'
	EXEC master.dbo.sp_serveroption @server=N'DYN_DBA_RMT', @optname=N'rpc out', @optvalue=N'true'

	-- DISABLE LOG BACKUPS ON PRIMARY TILL MIRRORING IS DONE
	SET @CMD = 'EXEC msdb.dbo.sp_update_job @job_name=N''MAINT - TranLog Backup'', @enabled=0'
	EXEC (@CMD)  AT [DYN_DBA_RMT]	

	-- GET LOCAL MIRRORING ENPOINT INFO
	SELECT		@LocalEndpointID	= endpoint_id
			,@LocalEndpointPort	= port
	FROM		master.sys.tcp_endpoints 
	WHERE		TYPE=4

	IF @LocalEndpointID IS NOT NULL
		SELECT		@LocalEndpointName = NAME
		FROM		master.sys.endpoints 
		WHERE		endpoint_id = @LocalEndpointID
	ELSE
	BEGIN
		EXEC (@CreateEndpoint)

		SELECT		@LocalEndpointID	= endpoint_id
				,@LocalEndpointPort	= port
				,@LocalEndpointName	= 'Mirroring'-- select *
		FROM		master.sys.tcp_endpoints 
		WHERE		TYPE=4
	END


	-- GET REMOTE MIRRORING ENPOINT INFO
	SELECT		@RemoteEndpointID	= endpoint_id
			,@RemoteEndpointPort	= port
	FROM		[DYN_DBA_RMT].master.sys.tcp_endpoints 
	WHERE		TYPE=4

	IF @RemoteEndpointID IS NOT NULL
		SELECT		@RemoteEndpointName = NAME
		FROM		[DYN_DBA_RMT].master.sys.endpoints 
		WHERE		endpoint_id = @RemoteEndpointID
	ELSE
	BEGIN
		EXEC (@CreateEndpoint) AT [DYN_DBA_RMT]

		SELECT		@LocalEndpointID	= endpoint_id
				,@LocalEndpointPort	= port
				,@LocalEndpointName	= 'Mirroring'
		FROM		[DYN_DBA_RMT].master.sys.tcp_endpoints 
		WHERE		TYPE=4
	END

	-- GET LOCAL FQDN
	EXEC xp_instance_regread N'HKEY_LOCAL_MACHINE', N'SYSTEM\CurrentControlSet\Services\Tcpip\Parameters', N'Domain', @Local_FQDN OUTPUT
	SELECT @Local_FQDN = Cast(SERVERPROPERTY('MachineName') as nvarchar) + '.' + @Local_FQDN

	-- GET REMOTE FQDN
	EXEC [DYN_DBA_RMT].master..xp_instance_regread N'HKEY_LOCAL_MACHINE', N'SYSTEM\CurrentControlSet\Services\Tcpip\Parameters', N'Domain', @Remote_FQDN OUTPUT
	SELECT @Remote_FQDN = @MachineName + '.' + @Remote_FQDN


	IF @FullReset = 1 AND DB_ID(@DBNAME) IS NOT NULL 
	BEGIN
		Print '**** FULL RESET REQUESTED, '+UPPER(@DBNAME)+' DATABASE WILL BE DROPED AND RECREATED. ***'
		
		IF EXISTS(select * From master.sys.database_mirroring WHERE database_id = DB_ID(@DBName) AND mirroring_partner_name IS NOT NULL)
		BEGIN
			SET @CMD = 'ALTER DATABASE ['+@DBName+'] SET PARTNER OFF;'
			EXEC (@CMD)
		END
		
		IF EXISTS(select * From master.sys.databases WHERE database_id = DB_ID(@DBName) AND state_desc = 'RESTORING')
		SET @CMD = 'RESTORE DATABASE ['+@DBName+'] WITH RECOVERY;'
		EXEC (@CMD)
		
		SET @CMD = 'ALTER DATABASE ['+@DBName+'] SET RESTRICTED_USER WITH ROLLBACK IMMEDIATE;DROP DATABASE ['+@DBName+']'
		EXEC (@CMD)
	END


	;WITH		SourceFiles
			AS
			(
			SELECT		*
			FROM		dbaadmin.dbo.dbaudf_Dir(@BackupPath)
			WHERE		LEFT(name,len(@DBName)+1) = @DBName + '_'
				AND	IsFileSystem = 1
				AND	IsFolder = 0
				AND	error IS NULL
			)
			,QueuedFiles
			AS
			(
			SELECT		*
			FROM		dbaadmin.dbo.dbaudf_Dir(@RestorePath+'\')
			WHERE		LEFT(name,len(@DBName)+1) = @DBName + '_'
			)
			,Files
			AS
			(
			SELECT		S.*
					,CASE	WHEN Q.name IS NULL 		THEN 'Not Coppied'
						ELSE 'Coppied'
						END AS [Status]

			FROM		SourceFiles S 
			LEFT JOIN	QueuedFiles Q 
				ON	Q.name = S.Name

			WHERE		(RIGHT(s.path,4) = 'cDIF' AND s.ModifyDate = (SELECT MAX(ModifyDate) FROM SourceFiles WHERE RIGHT(path,4) = 'cDIF'))
				OR	(RIGHT(s.path,4) = 'cBAK' AND s.ModifyDate = (SELECT MAX(ModifyDate) FROM SourceFiles WHERE RIGHT(path,4) = 'cBAK'))
				OR	(RIGHT(s.path,3) = 'TRN' AND s.ModifyDate >= (SELECT MAX(ModifyDate) FROM SourceFiles WHERE RIGHT(path,4) = 'cDIF'))
			)
			
	INSERT INTO	@CopyAndDeletes
	SELECT		CASE F.[Status] WHEN 'Not Coppied' THEN @COPY_CMD + ' '+STUFF(f.path,1,CHARINDEX(f.name,f.Path)-1,'') END
			,CASE WHEN F.[Status] IS NULL THEN 'exec dbaadmin.dbo.dbasp_UnlockAndDelete '''+Q.path+''',1,1,0'+CHAR(13)+CHAR(10) END
	FROM		QueuedFiles Q
	FULL JOIN	Files F 
		ON	F.name = Q.name


	

	DECLARE CopyAndDeleteCursor CURSOR
	FOR
	SELECT * FROM @CopyAndDeletes

	OPEN CopyAndDeleteCursor
	FETCH NEXT FROM CopyAndDeleteCursor INTO @COPY_CMD,@DELETE_CMD
	WHILE (@@fetch_status <> -1)
	BEGIN
		IF (@@fetch_status <> -2)
		BEGIN
			IF @COPY_CMD IS NOT NULL
			BEGIN
				PRINT @COPY_CMD
				exec xp_CmdShell @COPY_CMD
			END
			
			IF @DELETE_CMD IS NOT NULL
			BEGIN
				PRINT @DELETE_CMD
				EXEC(@DELETE_CMD)
			END

		END
		FETCH NEXT FROM CopyAndDeleteCursor INTO @COPY_CMD,@DELETE_CMD
	END

	CLOSE CopyAndDeleteCursor
	DEALLOCATE CopyAndDeleteCursor

	-- GET LOG PATH
	SET		@ShareName	= REPLACE(@@ServerName,'\','$')+'_ldf'			
	exec dbaadmin.dbo.dbasp_get_share_path @ShareName,@LogPath OUT

	-- GET DATA PATH
	SET		@ShareName	= REPLACE(@@ServerName,'\','$')+'_mdf'			
	exec dbaadmin.dbo.dbasp_get_share_path @ShareName,@DataPath OUT
	
	
	-- RESET ANY PROCESSED FILES IF RESTARTING DATABASE				
	IF @FullReset = 1  OR DB_ID(@DBName) IS NULL
	BEGIN
		EXECUTE [dbaadmin].[dbo].[dbasp_autorestore] 
		   @full_path =@RestorePath
		  ,@dbname = @DBName
		  ,@datapath = @DataPath
		  ,@logpath = @LogPath
		  ,@differential_flag = 'Y'
		  ,@db_norecovOnly_flag = 'Y'
		  ,@Script_out='N'
	END


	DECLARE RestoreLogCursor CURSOR
	FOR
	SELECT		'restore log '+@DBName+' from disk ='''+[path]+''' with norecovery'
	FROM		dbaadmin.dbo.dbaudf_Dir(@RestorePath+'\')
	WHERE		LEFT([name],len(@DBName)+1) = @DBName + '_'
		and	RIGHT([path],4)='cTRN'
	ORDER BY	[ModifyDate]

	OPEN RestoreLogCursor
	FETCH NEXT FROM RestoreLogCursor INTO @CMD
	WHILE (@@fetch_status <> -1)
	BEGIN
		IF (@@fetch_status <> -2)
		BEGIN
			PRINT(@CMD)
			EXEC(@CMD)
		END
		FETCH NEXT FROM RestoreLogCursor INTO @CMD
	END

	CLOSE RestoreLogCursor
	DEALLOCATE RestoreLogCursor


	-- STOP MIRRORING PARTNER AT PRIMARY
	IF EXISTS(select * From [DYN_DBA_RMT].master.sys.database_mirroring T1 JOIN [DYN_DBA_RMT].master.sys.databases T2 ON T1.database_id = T2.database_id WHERE T2.name = @DBName AND T1.mirroring_partner_name IS NOT NULL)
	BEGIN
		SET @CMD = 'ALTER DATABASE ['+@DBName+'] SET PARTNER OFF'
		PRINT @CMD
		EXEC (@CMD) AT [DYN_DBA_RMT]
	END
	
	-- SET MIRRORING PARTNER AT MIRROR
	SET @CMD = 'ALTER DATABASE ['+@DBName+'] SET PARTNER = ''TCP://'+@Remote_FQDN+':'+CAST(@RemoteEndpointPort AS VarChar(10))+''''
	PRINT @CMD
	EXEC (@CMD) 	
	
	-- SET MIRRORING PARTNER AT PRIMARY
	SET @CMD = 'ALTER DATABASE ['+@DBName+'] SET PARTNER = ''TCP://'+@Local_FQDN+':'+CAST(@LocalEndpointPort AS VarChar(10))+''''
	PRINT @CMD
	EXEC (@CMD) AT [DYN_DBA_RMT]

	-- ENABLE LOG BACKUPS ON PRIMARY NOW THAT MIRRORING IS DONE
	SET @CMD = 'EXEC msdb.dbo.sp_update_job @job_name=N''MAINT - TranLog Backup'', @enabled=1'
	EXEC (@CMD)  AT [DYN_DBA_RMT]
	
	-- REMOVE DYNAMIC LINKED SERVER
	IF  EXISTS (SELECT srv.name FROM sys.servers srv WHERE srv.server_id != 0 AND srv.name = N'DYN_DBA_RMT')
		EXEC master.dbo.sp_dropserver @server=N'DYN_DBA_RMT', @droplogins='droplogins'	
GO	


-- REMOVE DYNAMIC LINKED SERVER
IF  EXISTS (SELECT srv.name FROM sys.servers srv WHERE srv.server_id != 0 AND srv.name = N'DYN_DBA_RMT')
	EXEC master.dbo.sp_dropserver @server=N'DYN_DBA_RMT', @droplogins='droplogins'
