:CONNECT SEAPSQLSHR02A


DECLARE		@ServerName	VarChar(max)
SET		@ServerName	= 'seapsqlorrpt01'

;with		cte 
		as 
		(
		select  VMGROUPID
			,[PARENTID]
			,CAST([NAME] AS VarChar(max)) [Path]
		from    [vcentral].[dbo].[VPXV_VMGROUPS]
		where   [PARENTID] not in (SELECT VMGROUPID FROM [vcentral].[dbo].[VPXV_VMGROUPS])
		union all
		select  child.VMGROUPID
			,child.[PARENTID]
			,parent.[Path] + CAST('\'+ child.NAME AS VarChar(max)) [Path]
		from    [vcentral].[dbo].[VPXV_VMGROUPS] child
		join    cte parent
		on      parent.VMGROUPID = child.[PARENTID]
		)
		,Path
		AS
		(
		select		VMGROUPID
				,[Path]
		from		cte
		--order by	[Path]
		)
SELECT		vpxv_vms.vmid
		, vpxv_vms.NAME ServerName
		, vpxv_vms.hostid
		, vpxv_hosts.NAME ESX_HostName
		,[GUEST_STATE]
		,(SELECT [Path] FROM [Path] WHERE [Path].[VMGROUPID] = vpxv_vms.[VMGROUPID]) [Path]
		,(SELECT TOP 1 Active FROM SEAPDBASQL01.dbacentral.dbo.DBA_ServerInfo WHERE ServerName = vpxv_vms.NAME) DBA_ServerInfo_Active
FROM [vcentral].[dbo].vpxv_vms vpxv_vms
JOIN [vcentral].[dbo].vpxv_hosts vpxv_hosts on VPXV_VMS.HOSTID = VPXV_HOSTS.HOSTID
WHERE (
(vpxv_hosts.hostid = vpxv_vms.hostid)
AND (vpxv_vms.NAME Like '%'+@ServerName+'%')
)
ORDER BY 2
GO

