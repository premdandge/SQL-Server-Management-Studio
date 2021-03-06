USE [DEPLcontrol]
GO
/****** Object:  Table [dbo].[LargeFile_Override]    Script Date: 10/4/2013 11:02:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LargeFile_Override](
	[DBname] [sysname] NOT NULL,
	[Project] [sysname] NOT NULL,
	[Release] [sysname] NOT NULL,
	[FileType] [sysname] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_clust_LargeFile_Override]    Script Date: 10/4/2013 11:02:05 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_clust_LargeFile_Override] ON [dbo].[LargeFile_Override]
(
	[DBname] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
