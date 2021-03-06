WITH	LastCheckIn
		AS
		(
		SELECT		SQLname
					,MAX(check_date) AS last_date
		FROM		[dbacentral].[dbo].[SQLHealth_Central]
		GROUP BY	SQLname
		)
SELECT		SHC.[hl_id]
			,SHC.[SQLname]
			,SHC.[Domain]
			,SHC.[ENVname]
			,SHC.[Subject01]
			,SHC.[Value01]
			,SHC.[Grade01]
			,SHC.[Notes01]
			,SHC.[Check_date]
FROM		[dbacentral].[dbo].[SQLHealth_Central] SHC
INNER JOIN	LastCheckIn
		ON	SHC.[SQLname] = LastCheckIn.[SQLname]
		AND	SHC.[Check_date] = LastCheckIn.last_date
WHERE		SHC.[ENVname] = 'production'
ORDER BY	SHC.[SQLname]