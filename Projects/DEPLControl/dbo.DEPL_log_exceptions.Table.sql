USE [DEPLcontrol]
GO
/****** Object:  Table [dbo].[DEPL_log_exceptions]    Script Date: 10/4/2013 11:02:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[DEPL_log_exceptions](
	[dplogx_id] [int] IDENTITY(1,1) NOT NULL,
	[servername] [sysname] NOT NULL,
	[projectname] [sysname] NULL,
	[projectver] [nvarchar](15) NULL,
	[envnum] [nvarchar](15) NULL,
	[dbname] [sysname] NOT NULL,
	[foldername] [sysname] NULL,
	[scriptname] [sysname] NULL,
	[status] [nvarchar](10) NULL,
	[duration] [nvarchar](10) NULL,
	[overtimelimit] [char](1) NULL,
	[createdate] [datetime] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
