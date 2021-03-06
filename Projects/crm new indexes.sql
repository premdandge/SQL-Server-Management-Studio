use [Getty_Images_US_Inc__MSCRM]
go

SET QUOTED_IDENTIFIER ON
go

SET ARITHABORT ON
go

SET CONCAT_NULL_YIELDS_NULL ON
go

SET ANSI_NULLS ON
go

SET ANSI_PADDING ON
go

SET ANSI_WARNINGS ON
go

SET NUMERIC_ROUNDABORT OFF
go

CREATE VIEW [dbo].[_dta_mv_0] WITH SCHEMABINDING
 AS 
SELECT  [dbo].[SalesOrderBase].[SalesOrderId] as _col_1,  [dbo].[SalesOrderBase].[StateCode] as _col_2,  count_big(*) as _col_3 FROM  [dbo].[SalesOrderExtensionBase],  [dbo].[SalesOrderBase]   WHERE  [dbo].[SalesOrderExtensionBase].[SalesOrderId] = [dbo].[SalesOrderBase].[SalesOrderId]  GROUP BY  [dbo].[SalesOrderBase].[SalesOrderId],  [dbo].[SalesOrderBase].[StateCode]  

go

SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET NUMERIC_ROUNDABORT OFF

go

CREATE UNIQUE CLUSTERED INDEX [_dta_index__dta_mv_0_c_6_1488685047__K1_K2] ON [dbo].[_dta_mv_0]
(
	[_col_1] ASC,
	[_col_2] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
go

SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET NUMERIC_ROUNDABORT OFF

go

CREATE NONCLUSTERED INDEX [_dta_index__dta_mv_0_6_1488685047__K2] ON [dbo].[_dta_mv_0]
(
	[_col_2] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
go

