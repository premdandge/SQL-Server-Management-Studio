
;WITH		FoundServers
		AS
		(
		      SELECT 'ASHPSQLTFS0A.amer.gettywan.com' [FQDN]
		UNION ALL SELECT 'EDSQLG0A.amer.gettywan.com'
		UNION ALL SELECT 'FREAGMSSQL01.gettyimages.net'
		UNION ALL SELECT 'FREAGMSSQL01.gettyimages.net'
		UNION ALL SELECT 'FREAGMSSQL01.gettyimages.net'
		UNION ALL SELECT 'FREBCTBSQL01.gettyimages.net'
		UNION ALL SELECT 'FREBGMSSQLA01.gettyimages.net'
		UNION ALL SELECT 'FREBGMSSQLB01.gettyimages.net'
		UNION ALL SELECT 'FREBGMSSQLB01.gettyimages.net'
		UNION ALL SELECT 'FREBPCXSQL01.gettyimages.net'
		UNION ALL SELECT 'FRECCTBSQL01.gettyimages.net'
		UNION ALL SELECT 'FRECGMSSQLA01.gettyimages.net'
		UNION ALL SELECT 'FRECGMSSQLB01.gettyimages.net'
		UNION ALL SELECT 'FRECGMSSQLB01.gettyimages.net'
		UNION ALL SELECT 'FRECPCXSQL01.gettyimages.net'
		UNION ALL SELECT 'FREDCOGSRS01.amer.gettywan.com'
		UNION ALL SELECT 'FREDGSYSSQL01.amer.gettywan.com'
		UNION ALL SELECT 'FREDSQLDIST01.amer.gettywan.com'
		UNION ALL SELECT 'FREDSQLPERF01.amer.gettywan.com'
		UNION ALL SELECT 'FREDSQLPERF01.amer.gettywan.com'
		UNION ALL SELECT 'FREDSQLPERF01.amer.gettywan.com'
		UNION ALL SELECT 'FREDSQLTAX01.amer.gettywan.com'
		UNION ALL SELECT 'FREDSQLTOL01.amer.gettywan.com'
		UNION ALL SELECT 'FREDSRSSQL01.gettyimages.net'
		UNION ALL SELECT 'FRELGMSSQLA.gettyimages.net'
		UNION ALL SELECT 'FRELGMSSQLA.gettyimages.net'
		UNION ALL SELECT 'FRELLNPSQL01.gettyimages.net'
		UNION ALL SELECT 'FREPCOGSRS01.amer.gettywan.com'
		UNION ALL SELECT 'FREPHYPERSQL01.amer.gettywan.com'
		UNION ALL SELECT 'FREPNBPRO01.amer.gettywan.com'
		UNION ALL SELECT 'FREPSQLDWARCH.amer.gettywan.com'
		UNION ALL SELECT 'FREPSQLEDW01.amer.gettywan.com'
		UNION ALL SELECT 'FREPSQLGLB01.amer.gettywan.com'
		UNION ALL SELECT 'FREPSQLNOE01.amer.gettywan.com'
		UNION ALL SELECT 'FREPSQLRYLA01.amer.gettywan.com'
		UNION ALL SELECT 'FREPSQLRYLA11.amer.gettywan.com'
		UNION ALL SELECT 'FREPSQLRYLA12.amer.gettywan.com'
		UNION ALL SELECT 'FREPSQLRYLA13.amer.gettywan.com'
		UNION ALL SELECT 'FREPSQLRYLA14.amer.gettywan.com'
		UNION ALL SELECT 'FREPSQLRYLA15.amer.gettywan.com'
		UNION ALL SELECT 'FREPSQLRYLB01.amer.gettywan.com'
		UNION ALL SELECT 'FREPSQLRYLB11.amer.gettywan.com'
		UNION ALL SELECT 'FREPSQLRYLB12.amer.gettywan.com'
		UNION ALL SELECT 'FREPSQLRYLB13.amer.gettywan.com'
		UNION ALL SELECT 'FREPSQLRYLB14.amer.gettywan.com'
		UNION ALL SELECT 'FREPSQLRYLB15.amer.gettywan.com'
		UNION ALL SELECT 'frepsqlrylj04.amer.gettywan.com'
		UNION ALL SELECT 'FREPSQLRYLR01.amer.gettywan.com'
		UNION ALL SELECT 'FREPTSSQL01.gettyimages.net'
		UNION ALL SELECT 'FREPVARSQL01.amer.gettywan.com'
		UNION ALL SELECT 'FRESCOGSRS01.amer.gettywan.com'
		UNION ALL SELECT 'FRESSQLRYL01.amer.gettywan.com'
		UNION ALL SELECT 'FRESSQLRYL11.amer.gettywan.com'
		UNION ALL SELECT 'FRESSQLRYL12.amer.gettywan.com'
		UNION ALL SELECT 'FRESSQLRYLI01.amer.gettywan.com'
		UNION ALL SELECT 'FRESSQLTAX01.amer.gettywan.com'
		UNION ALL SELECT 'FRETCOGSRS01.amer.gettywan.com'
		UNION ALL SELECT 'FRETHYPERSQL01.amer.gettywan.com'
		UNION ALL SELECT 'FRETRYLABP01.amer.gettywan.com'
		UNION ALL SELECT 'FRETRYLABP01.amer.gettywan.com'
		UNION ALL SELECT 'FRETSCOMRPTSQL1.amer.gettywan.com'
		UNION ALL SELECT 'FRETSCOMSQL01.amer.gettywan.com'
		UNION ALL SELECT 'FRETSQLCTX01.amer.gettywan.com'
		UNION ALL SELECT 'FRETSQLDBA01.amer.gettywan.com'
		UNION ALL SELECT 'FRETSQLDIP02.amer.gettywan.com'
		UNION ALL SELECT 'FRETSQLDIP02.amer.gettywan.com'
		UNION ALL SELECT 'FRETSQLDIST01.amer.gettywan.com'
		UNION ALL SELECT 'FRETSQLNOE01.amer.gettywan.com'
		UNION ALL SELECT 'FRETSQLRYL02.amer.gettywan.com'
		UNION ALL SELECT 'FRETSQLRYL03.amer.gettywan.com'
		UNION ALL SELECT 'FRETSQLRYLI02.amer.gettywan.com'
		UNION ALL SELECT 'FRETSQLRYLI03.amer.gettywan.com'
		UNION ALL SELECT 'FRETSQLTAX01.amer.gettywan.com'
		UNION ALL SELECT 'G1SQLB.production.local'
		UNION ALL SELECT 'G1SQLB.production.local'
		UNION ALL SELECT 'GMSSQLDEV01.gettyimages.net'
		UNION ALL SELECT 'GMSSQLDEV01.gettyimages.net'
		UNION ALL SELECT 'GMSSQLDEV01.gettyimages.net'
		UNION ALL SELECT 'GMSSQLDEV04.gettyimages.net'
		UNION ALL SELECT 'GMSSQLDEV04.gettyimages.net'
		UNION ALL SELECT 'GMSSQLDEV04.gettyimages.net'
		UNION ALL SELECT 'GMSSQLLOAD02.gettyimages.net'
		UNION ALL SELECT 'GMSSQLLOAD02.gettyimages.net'
		UNION ALL SELECT 'GMSSQLLOAD02.gettyimages.net'
		UNION ALL SELECT 'GMSSQLTEST01.gettyimages.net'
		UNION ALL SELECT 'GMSSQLTEST01.gettyimages.net'
		UNION ALL SELECT 'GMSSQLTEST01.gettyimages.net'
		UNION ALL SELECT 'GMSSQLTEST03.gettyimages.net'
		UNION ALL SELECT 'GMSSQLTEST03.gettyimages.net'
		UNION ALL SELECT 'GMSSQLTEST03.gettyimages.net'
		UNION ALL SELECT 'GONESSQLA.stage.local'
		UNION ALL SELECT 'GONESSQLA.stage.local'
		UNION ALL SELECT 'GONESSQLB.stage.local'
		UNION ALL SELECT 'GONESSQLB.stage.local'
		UNION ALL SELECT 'NYMVSQLDEV02.amer.gettywan.com'
		UNION ALL SELECT 'PCSQLDEV01.gettyimages.net'
		UNION ALL SELECT 'PCSQLDEV04.gettyimages.net'
		UNION ALL SELECT 'PCSQLLOAD02.gettyimages.net'
		UNION ALL SELECT 'PCSQLLOADA.gettyimages.net'
		UNION ALL SELECT 'PCSQLTEST01.gettyimages.net'
		UNION ALL SELECT 'PCSQLTEST01.gettyimages.net'
		UNION ALL SELECT 'PCSQLTEST03.gettyimages.net'
		UNION ALL SELECT 'SEABACHSQL01.gettyimages.net'
		UNION ALL SELECT 'SEABCRM5SQL01.amer.gettywan.com'
		UNION ALL SELECT 'SEABSCFWSQL01.gettyimages.net'
		UNION ALL SELECT 'SEACACHSQL01.gettyimages.net'
		UNION ALL SELECT 'SEACCRM5SQL01.amer.gettywan.com'
		UNION ALL SELECT 'SEACEDSQL01.amer.gettywan.com'
		UNION ALL SELECT 'SEACSCFWSQL01.gettyimages.net'
		UNION ALL SELECT 'SEACSQLDIST01.amer.gettywan.com'
		UNION ALL SELECT 'SEADCASPSQLA.production.local'
		UNION ALL SELECT 'SEADCBLACKBRY01.amer.gettywan.com'
		UNION ALL SELECT 'SEADCLABSSQL01.production.local'
		UNION ALL SELECT 'SEADCPCSQLA.production.local'
		UNION ALL SELECT 'SEADCSHSQLA.production.local'
		UNION ALL SELECT 'SEADROYSQL02.amer.gettywan.com'
		UNION ALL SELECT 'SEADSDTSQLA02.gettyimages.net'
		UNION ALL SELECT 'SEADSDTSQLB02.gettyimages.net'
		UNION ALL SELECT 'SEADSPSSQL01.amer.gettywan.com'
		UNION ALL SELECT 'SEADSPSSQL01.amer.gettywan.com'
		UNION ALL SELECT 'SEADSQLBOB01.amer.gettywan.com'
		UNION ALL SELECT 'SEADSQLRYL01.amer.gettywan.com'
		UNION ALL SELECT 'SEADSQLRYLPMT01.amer.gettywan.com'
		UNION ALL SELECT 'SEADSQLRYLPRC01.amer.gettywan.com'
		UNION ALL SELECT 'SEADW2625.amer.gettywan.com'
		UNION ALL SELECT 'SEAFREGLOBEAPP1.amer.gettywan.com'
		UNION ALL SELECT 'SEAFRESQLBO01.amer.gettywan.com'
		UNION ALL SELECT 'seafresqlbo02.amer.gettywan.com'
		UNION ALL SELECT 'SEAFRESQLBOT01.amer.gettywan.com'
		UNION ALL SELECT 'SEAFRESQLBOT01.amer.gettywan.com'
		UNION ALL SELECT 'SEAFRESQLBOT01.amer.gettywan.com'
		UNION ALL SELECT 'seafresqlproj01.amer.gettywan.com'
		UNION ALL SELECT 'SEAFRESQLSB01.amer.gettywan.com'
		UNION ALL SELECT 'SEAFRESQLSB01.amer.gettywan.com'
		UNION ALL SELECT 'SEAFRESQLSB01.amer.gettywan.com'
		UNION ALL SELECT 'seafresqltal04.amer.gettywan.com'
		UNION ALL SELECT 'SEALABSSQL01.gettyimages.net'
		UNION ALL SELECT 'SEALACHSQL02.gettyimages.net'
		UNION ALL SELECT 'SEALACHSQL02.gettyimages.net'
		UNION ALL SELECT 'SEALACHSQL02.gettyimages.net'
		UNION ALL SELECT 'SEALASPSQL01.gettyimages.net'
		UNION ALL SELECT 'SEALSCFWSQL02.gettyimages.net'
		UNION ALL SELECT 'SEAPASPSQLA.production.local'
		UNION ALL SELECT 'SEAPBIT9SEC01.amer.gettywan.com'
		UNION ALL SELECT 'SEAPCOGSQL01.amer.gettywan.com'
		UNION ALL SELECT 'SEAPCRMSQL1A.amer.gettywan.com'
		UNION ALL SELECT 'SEAPCTBSQLA.production.local'
		UNION ALL SELECT 'SEAPDBASQL01.amer.gettywan.com'
		UNION ALL SELECT 'SEAPDBASQL01.amer.gettywan.com'
		UNION ALL SELECT 'SEAPDBASQL01.amer.gettywan.com'
		UNION ALL SELECT 'SEAPDBASQL02.production.local'
		UNION ALL SELECT 'SEAPDWDCSQLD01.amer.gettywan.com'
		UNION ALL SELECT 'SEAPDWDCSQLD02.amer.gettywan.com'
		UNION ALL SELECT 'seapdwdcsqlp01.amer.gettywan.com'
		UNION ALL SELECT 'seapdwdcsqlp02.amer.gettywan.com'
		UNION ALL SELECT 'SEAPEWSDEPLOY01.amer.gettywan.com'
		UNION ALL SELECT 'SEAPFINSQL01.amer.gettywan.com'
		UNION ALL SELECT 'SEAPFOGLIGHT01.amer.gettywan.com'
		UNION ALL SELECT 'SEAPGSYSSQL01.amer.gettywan.com'
		UNION ALL SELECT 'SEAPHWUSQL01.amer.gettywan.com'
		UNION ALL SELECT 'SEAPHYPSQL01.amer.gettywan.com'
		UNION ALL SELECT 'SEAPLOGSQL01.production.local'
		UNION ALL SELECT 'SEAPLOGSQL01.production.local'
		UNION ALL SELECT 'SEAPLOGSQL01.production.local'
		UNION ALL SELECT 'SEAPLYNCSQL02.amer.gettywan.com'
		UNION ALL SELECT 'SEAPPERFWEBSQL1.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSCFWSQLA.production.local'
		UNION ALL SELECT 'seapscomsql01.amer.gettywan.com'
		UNION ALL SELECT 'seapscomsql02.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSCOMSQLDW01.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSCOMSQLDW02.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSDTSQLA.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSDTSQLA.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSDTSQLB.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSDTSQLB.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSECDB01.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSECDB02.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSQLBO01.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSQLBOC.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSQLBOD.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSQLBOD.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSQLBOD.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSQLBOE.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSQLBOE.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSQLBOE.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSQLCSO01.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSQLCTX01.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSQLDBA01.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSQLDIP01.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSQLDPLY01.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSQLDPLY02.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSQLDPLY03.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSQLDPLY04.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSQLDPLY05.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSQLLSHP01.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSQLLSHP01.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSQLLYNC01.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSQLMVINT01.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSQLOPS01.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSQLORRPT01.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSQLRYL0A.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSQLRYLDST01.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSQLRYLI0A.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSQLRYLPMT01.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSQLRYLPRC01.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSQLRYLPRC02.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSQLRYLRPT01.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSQLSHR21.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSQLSHR22.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSQLSP1301.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSQLSPS01.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSQLSPS02.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSQLTAX01.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSQLTFS01.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSQLTFS02.amer.gettywan.com'
		UNION ALL SELECT 'SEAPSQLWBS0A.amer.gettywan.com'
		UNION ALL SELECT 'seaptelemate01.amer.gettywan.com'
		UNION ALL SELECT 'SEAPVCENTSQL.amer.gettywan.com'
		UNION ALL SELECT 'SEAPWSUS01.amer.gettywan.com'
		UNION ALL SELECT 'SEASASPSQLA.stage.local'
		UNION ALL SELECT 'SEASCRMSQL01.amer.gettywan.com'
		UNION ALL SELECT 'SEASCRMSQL1A.amer.gettywan.com'
		UNION ALL SELECT 'SEASCTBSQLA.stage.local'
		UNION ALL SELECT 'SEASDBASQL01.stage.local'
		UNION ALL SELECT 'SEASDELSQL01.production.local'
		UNION ALL SELECT 'SEASEDSQL0A.amer.gettywan.com'
		UNION ALL SELECT 'SEASSCFWSQLA.stage.local'
		UNION ALL SELECT 'SEASSDTSQLA.amer.gettywan.com'
		UNION ALL SELECT 'SEASSDTSQLA.amer.gettywan.com'
		UNION ALL SELECT 'SEASSDTSQLB.amer.gettywan.com'
		UNION ALL SELECT 'SEASSDTSQLB.amer.gettywan.com'
		UNION ALL SELECT 'SEASSQLBOB01.amer.gettywan.com'
		UNION ALL SELECT 'SEASSQLBOC.amer.gettywan.com'
		UNION ALL SELECT 'SEASSQLDIST0A.amer.gettywan.com'
		UNION ALL SELECT 'SEASSQLRYL0A.amer.gettywan.com'
		UNION ALL SELECT 'SEASSQLRYLI0A.amer.gettywan.com'
		UNION ALL SELECT 'SEASSQLRYLPMT01.amer.gettywan.com'
		UNION ALL SELECT 'SEASSQLRYLPRC01.amer.gettywan.com'
		UNION ALL SELECT 'SEASSQLRYLPRC02.amer.gettywan.com'
		UNION ALL SELECT 'SEASSQLRYLRPT01.amer.gettywan.com'
		UNION ALL SELECT 'SEASTGPCSQLA.stage.local'
		UNION ALL SELECT 'SEASTGSHSQLA.stage.local'
		UNION ALL SELECT 'SEATACHSQL01.gettyimages.net'
		UNION ALL SELECT 'SEATACHSQL01.gettyimages.net'
		UNION ALL SELECT 'SEATACHSQL01.gettyimages.net'
		UNION ALL SELECT 'SEATASPSQL01.gettyimages.net'
		UNION ALL SELECT 'SEATCRM5SQL01.amer.gettywan.com'
		UNION ALL SELECT 'SEATCSOSQL02.amer.gettywan.com'
		UNION ALL SELECT 'SEATDBA02.amer.gettywan.com'
		UNION ALL SELECT 'SEATDBA03.amer.gettywan.com'
		UNION ALL SELECT 'SEATRHZSQL01.amer.gettywan.com'
		UNION ALL SELECT 'SEATROYSQL01.amer.gettywan.com'
		UNION ALL SELECT 'SEATSCFWSQL01.gettyimages.net'
		UNION ALL SELECT 'SEATSCFWSQL03.gettyimages.net'
		UNION ALL SELECT 'SEATSDTSQLA01.gettyimages.net'
		UNION ALL SELECT 'SEATSDTSQLA02.gettyimages.net'
		UNION ALL SELECT 'SEATSDTSQLB01.gettyimages.net'
		UNION ALL SELECT 'SEATSDTSQLB02.gettyimages.net'
		UNION ALL SELECT 'SEATSHPSQL01.amer.gettywan.com'
		UNION ALL SELECT 'SEATSQLBOB01.amer.gettywan.com'
		UNION ALL SELECT 'SEATSQLPUP01.gettyimages.net'
		UNION ALL SELECT 'SEATSQLPUP01.gettyimages.net'
		UNION ALL SELECT 'SEATSQLPUP01.gettyimages.net'
		UNION ALL SELECT 'SEATSQLRYL01.amer.gettywan.com'
		UNION ALL SELECT 'SEATSQLRYLPMT01.amer.gettywan.com'
		UNION ALL SELECT 'SEATSQLRYLPRC01.amer.gettywan.com'
		UNION ALL SELECT 'SHAREDSQLLOAD01.gettyimages.net'
		UNION ALL SELECT 'sqldeployer02.amer.gettywan.com'
		UNION ALL SELECT 'SQLDEPLOYER04.amer.gettywan.com'
		UNION ALL SELECT 'SQLDISTG0A.amer.gettywan.com'
		)
		,
		OurList
		AS
		(
		SELECT		*
		FROM		[dbacentral].[dbo].[DBA_ServerInfo]
		WHERE		Active = 'y'
			OR	FQDN IN (SELECT FQDN FROM FoundServers)
			OR	ServerName IN (SELECT REVERSE(PARSENAME(REVERSE(FQDN),1)) FROM FoundServers)
		)


SELECT		DISTINCT
		T1.ServerName
		,T1.SQLName
		,T1.FQDN
		,T1.[IPnum]
		,T1.Active
		,T2.FQDN
		,COALESCE(T1.FQDN,T2.FQDN) SortField
FROM		[OurList] T1
FULL JOIN	[FoundServers] T2
	ON	T1.FQDN = T2.FQDN
ORDER BY	6	