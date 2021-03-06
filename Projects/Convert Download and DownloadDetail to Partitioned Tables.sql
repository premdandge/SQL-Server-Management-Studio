USE [WCDS]
GO

--SELECT * FROM dbaadmin.dbo.dbaudf_ListDrives()
/*

ALTER DATABASE [WCDS] ADD FILEGROUP [WCDS_D_2010_10]
ALTER DATABASE [WCDS] ADD FILEGROUP [WCDS_D_2010_11]
ALTER DATABASE [WCDS] ADD FILEGROUP [WCDS_D_2010_12]
ALTER DATABASE [WCDS] ADD FILEGROUP [WCDS_D_2011_01]
ALTER DATABASE [WCDS] ADD FILEGROUP [WCDS_D_2011_02]
ALTER DATABASE [WCDS] ADD FILEGROUP [WCDS_D_2011_03]
ALTER DATABASE [WCDS] ADD FILEGROUP [WCDS_D_2011_04]
ALTER DATABASE [WCDS] ADD FILEGROUP [WCDS_D_2011_05]
ALTER DATABASE [WCDS] ADD FILEGROUP [WCDS_D_2011_06]
ALTER DATABASE [WCDS] ADD FILEGROUP [WCDS_D_2011_07]
ALTER DATABASE [WCDS] ADD FILEGROUP [WCDS_D_2011_08]
ALTER DATABASE [WCDS] ADD FILEGROUP [WCDS_D_2011_09]
ALTER DATABASE [WCDS] ADD FILEGROUP [WCDS_D_2011_10]
ALTER DATABASE [WCDS] ADD FILEGROUP [WCDS_D_2011_11]
ALTER DATABASE [WCDS] ADD FILEGROUP [WCDS_D_2011_12]
ALTER DATABASE [WCDS] ADD FILEGROUP [WCDS_D_2012_01]


ALTER DATABASE [WCDS] ADD FILE ( NAME = N'WCDS_D_2010_10', FILENAME = N'E:\SQL\DATA\WCDS_D_2010_10.ndf' , SIZE = 1024KB , FILEGROWTH = 1024KB ) TO FILEGROUP [WCDS_D_2010_10]
ALTER DATABASE [WCDS] ADD FILE ( NAME = N'WCDS_D_2010_11', FILENAME = N'E:\SQL\DATA\WCDS_D_2010_11.ndf' , SIZE = 1024KB , FILEGROWTH = 1024KB ) TO FILEGROUP [WCDS_D_2010_11]
ALTER DATABASE [WCDS] ADD FILE ( NAME = N'WCDS_D_2010_12', FILENAME = N'E:\SQL\DATA\WCDS_D_2010_12.ndf' , SIZE = 1024KB , FILEGROWTH = 1024KB ) TO FILEGROUP [WCDS_D_2010_12]
ALTER DATABASE [WCDS] ADD FILE ( NAME = N'WCDS_D_2011_01', FILENAME = N'E:\SQL\DATA\WCDS_D_2011_01.ndf' , SIZE = 1024KB , FILEGROWTH = 1024KB ) TO FILEGROUP [WCDS_D_2011_01]
ALTER DATABASE [WCDS] ADD FILE ( NAME = N'WCDS_D_2011_02', FILENAME = N'E:\SQL\DATA\WCDS_D_2011_02.ndf' , SIZE = 1024KB , FILEGROWTH = 1024KB ) TO FILEGROUP [WCDS_D_2011_02]
ALTER DATABASE [WCDS] ADD FILE ( NAME = N'WCDS_D_2011_03', FILENAME = N'E:\SQL\DATA\WCDS_D_2011_03.ndf' , SIZE = 1024KB , FILEGROWTH = 1024KB ) TO FILEGROUP [WCDS_D_2011_03]
ALTER DATABASE [WCDS] ADD FILE ( NAME = N'WCDS_D_2011_04', FILENAME = N'E:\SQL\DATA\WCDS_D_2011_04.ndf' , SIZE = 1024KB , FILEGROWTH = 1024KB ) TO FILEGROUP [WCDS_D_2011_04]
ALTER DATABASE [WCDS] ADD FILE ( NAME = N'WCDS_D_2011_05', FILENAME = N'E:\SQL\DATA\WCDS_D_2011_05.ndf' , SIZE = 1024KB , FILEGROWTH = 1024KB ) TO FILEGROUP [WCDS_D_2011_05]
ALTER DATABASE [WCDS] ADD FILE ( NAME = N'WCDS_D_2011_06', FILENAME = N'E:\SQL\DATA\WCDS_D_2011_06.ndf' , SIZE = 1024KB , FILEGROWTH = 1024KB ) TO FILEGROUP [WCDS_D_2011_06]
ALTER DATABASE [WCDS] ADD FILE ( NAME = N'WCDS_D_2011_07', FILENAME = N'E:\SQL\DATA\WCDS_D_2011_07.ndf' , SIZE = 1024KB , FILEGROWTH = 1024KB ) TO FILEGROUP [WCDS_D_2011_07]
ALTER DATABASE [WCDS] ADD FILE ( NAME = N'WCDS_D_2011_08', FILENAME = N'E:\SQL\DATA\WCDS_D_2011_08.ndf' , SIZE = 1024KB , FILEGROWTH = 1024KB ) TO FILEGROUP [WCDS_D_2011_08]
ALTER DATABASE [WCDS] ADD FILE ( NAME = N'WCDS_D_2011_09', FILENAME = N'E:\SQL\DATA\WCDS_D_2011_09.ndf' , SIZE = 1024KB , FILEGROWTH = 1024KB ) TO FILEGROUP [WCDS_D_2011_09]
ALTER DATABASE [WCDS] ADD FILE ( NAME = N'WCDS_D_2011_10', FILENAME = N'E:\SQL\DATA\WCDS_D_2011_10.ndf' , SIZE = 1024KB , FILEGROWTH = 1024KB ) TO FILEGROUP [WCDS_D_2011_10]
ALTER DATABASE [WCDS] ADD FILE ( NAME = N'WCDS_D_2011_11', FILENAME = N'E:\SQL\DATA\WCDS_D_2011_11.ndf' , SIZE = 1024KB , FILEGROWTH = 1024KB ) TO FILEGROUP [WCDS_D_2011_11]
ALTER DATABASE [WCDS] ADD FILE ( NAME = N'WCDS_D_2011_12', FILENAME = N'E:\SQL\DATA\WCDS_D_2011_12.ndf' , SIZE = 1024KB , FILEGROWTH = 1024KB ) TO FILEGROUP [WCDS_D_2011_12]
ALTER DATABASE [WCDS] ADD FILE ( NAME = N'WCDS_D_2012_01', FILENAME = N'E:\SQL\DATA\WCDS_D_2012_01.ndf' , SIZE = 1024KB , FILEGROWTH = 1024KB ) TO FILEGROUP [WCDS_D_2012_01]

DROP PARTITION SCHEME [ps_Download]
DROP PARTITION FUNCTION [pf_Download]

GO
CREATE PARTITION FUNCTION [pf_Download](datetime) 
AS RANGE LEFT FOR VALUES	(
							N'1900-01-01T00:00:00'
							, N'2010-10-01T00:00:00'
							, N'2010-11-01T00:00:00'
							, N'2010-12-01T00:00:00'
							, N'2011-01-01T00:00:00'
							, N'2011-02-01T00:00:00'
							, N'2011-03-01T00:00:00'
							, N'2011-04-01T00:00:00'
							, N'2011-05-01T00:00:00'
							, N'2011-06-01T00:00:00'
							, N'2011-07-01T00:00:00'
							, N'2011-08-01T00:00:00'
							, N'2011-09-01T00:00:00'
							, N'2011-10-01T00:00:00'
							, N'2011-11-01T00:00:00'
							, N'2011-12-01T00:00:00'
							, N'2012-01-01T00:00:00'
							)

GO

CREATE PARTITION SCHEME [ps_Download] 
AS PARTITION [pf_Download] TO	(
								[PRIMARY]
								,[PRIMARY]
								, [WCDS_D_2010_10]
								, [WCDS_D_2010_11]
								, [WCDS_D_2010_12]
								, [WCDS_D_2011_01]
								, [WCDS_D_2011_02]
								, [WCDS_D_2011_03]
								, [WCDS_D_2011_04]
								, [WCDS_D_2011_05]
								, [WCDS_D_2011_06]
								, [WCDS_D_2011_07]
								, [WCDS_D_2011_08]
								, [WCDS_D_2011_09]
								, [WCDS_D_2011_10]
								, [WCDS_D_2011_11]
								, [WCDS_D_2011_12]
								, [WCDS_D_2012_01]
								)
GO

*/

DROP INDEX [nclDownload_CreatedDate] ON [dbo].[Download]

ALTER TABLE [dbo].[Download] DROP CONSTRAINT [PKCLDownload_DownloadId]

CREATE CLUSTERED INDEX [IX_CL_Download_CreatedDate] 
ON [dbo].[Download] ([CreatedDate])
--ON [ps_Download]([CreatedDate])

ALTER TABLE		[dbo].[Download]
ADD CONSTRAINT	[PK_NCL_Download_DownloadId] 
PRIMARY KEY NONCLUSTERED ([DownloadID] ASC,[CreatedDate] ASC) 
--ON [ps_Download]([CreatedDate])


GO


/****** Object:  Index [DownloadDetail_CompSourceIDDetailID]    Script Date: 10/26/2011 19:56:20 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DownloadDetail]') AND name = N'DownloadDetail_CompSourceIDDetailID')
DROP INDEX [DownloadDetail_CompSourceIDDetailID] ON [dbo].[DownloadDetail] WITH ( ONLINE = OFF )
GO

/****** Object:  Index [IDX_DownloadDetail_PremiumAccessLookup]    Script Date: 10/26/2011 19:56:20 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DownloadDetail]') AND name = N'IDX_DownloadDetail_PremiumAccessLookup')
DROP INDEX [IDX_DownloadDetail_PremiumAccessLookup] ON [dbo].[DownloadDetail] WITH ( ONLINE = OFF )
GO

/****** Object:  Index [nclDownloadDetail_CompanyIdImageId]    Script Date: 10/26/2011 19:56:20 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DownloadDetail]') AND name = N'nclDownloadDetail_CompanyIdImageId')
DROP INDEX [nclDownloadDetail_CompanyIdImageId] ON [dbo].[DownloadDetail] WITH ( ONLINE = OFF )
GO

/****** Object:  Index [NCLDownloadDetail_DownloadSourceID]    Script Date: 10/26/2011 19:56:20 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DownloadDetail]') AND name = N'NCLDownloadDetail_DownloadSourceID')
DROP INDEX [NCLDownloadDetail_DownloadSourceID] ON [dbo].[DownloadDetail] WITH ( ONLINE = OFF )
GO

/****** Object:  Index [nclDownloadDetail_StatusModifiedDateTime]    Script Date: 10/26/2011 19:56:20 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DownloadDetail]') AND name = N'nclDownloadDetail_StatusModifiedDateTime')
DROP INDEX [nclDownloadDetail_StatusModifiedDateTime] ON [dbo].[DownloadDetail] WITH ( ONLINE = OFF )
GO

/****** Object:  Index [nclDownloadDetailPlus]    Script Date: 10/26/2011 19:56:20 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DownloadDetail]') AND name = N'nclDownloadDetailPlus')
DROP INDEX [nclDownloadDetailPlus] ON [dbo].[DownloadDetail] WITH ( ONLINE = OFF )
GO

/****** Object:  Index [clDownloadDetail_DownloadId]    Script Date: 10/26/2011 19:56:20 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DownloadDetail]') AND name = N'clDownloadDetail_DownloadId')
DROP INDEX [clDownloadDetail_DownloadId] ON [dbo].[DownloadDetail] WITH ( ONLINE = OFF )
GO


CREATE CLUSTERED INDEX [clDownloadDetail_StatusModifiedDateTime] ON [dbo].[DownloadDetail] 
(
	[StatusModifiedDateTime] ASC
)WITH (PAD_INDEX  = ON, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) 
--ON [ps_Download]([StatusModifiedDateTime])


CREATE NONCLUSTERED INDEX [nclDownloadDetail_DownloadId] ON [dbo].[DownloadDetail] 
(
	[DownloadId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) 
--ON [ps_Download]([StatusModifiedDateTime])

CREATE NONCLUSTERED INDEX [DownloadDetail_CompSourceIDDetailID] ON [dbo].[DownloadDetail] 
(
	[CompanyId] ASC,
	[DownloadSourceId] ASC,
	[SourceDetailID] ASC
)
INCLUDE ( [DownloadId],
[ImageID],
[StatusID]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) 
--ON [ps_Download]([StatusModifiedDateTime])


CREATE NONCLUSTERED INDEX [IDX_DownloadDetail_PremiumAccessLookup] ON [dbo].[DownloadDetail] 
(
	[ImageID] ASC,
	[SourceDetailID] ASC
)WITH (PAD_INDEX  = ON, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) 
--ON [ps_Download]([StatusModifiedDateTime])

CREATE NONCLUSTERED INDEX [nclDownloadDetail_CompanyIdImageId] ON [dbo].[DownloadDetail] 
(
	[CompanyId] ASC,
	[ImageID] ASC
)WITH (PAD_INDEX  = ON, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) 
--ON [ps_Download]([StatusModifiedDateTime])

CREATE NONCLUSTERED INDEX [NCLDownloadDetail_DownloadSourceID] ON [dbo].[DownloadDetail] 
(
	[DownloadSourceId] ASC
)WITH (PAD_INDEX  = ON, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) 
--ON [ps_Download]([StatusModifiedDateTime])



CREATE NONCLUSTERED INDEX [nclDownloadDetailPlus] ON [dbo].[DownloadDetail] 
(
	[IndividualId] ASC,
	[DownloadSourceId] ASC,
	[StatusModifiedDateTime] ASC
)
INCLUDE ( [DownloadId],
[ImageID],
[SourceDetailID]) WITH (PAD_INDEX  = ON, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) 
--ON [ps_Download]([StatusModifiedDateTime])




