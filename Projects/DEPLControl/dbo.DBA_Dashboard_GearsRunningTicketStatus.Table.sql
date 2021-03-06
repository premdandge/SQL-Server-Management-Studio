USE [DEPLcontrol]
GO
/****** Object:  Table [dbo].[DBA_Dashboard_GearsRunningTicketStatus]    Script Date: 10/4/2013 11:02:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[DBA_Dashboard_GearsRunningTicketStatus](
	[GRTStatusID] [int] IDENTITY(1,1) NOT NULL,
	[TicketID] [int] NULL,
	[Complete] [bit] NULL,
	[Link] [varchar](4000) NULL,
	[Code] [varchar](50) NULL,
	[StatusDate] [datetime] NULL,
	[StatusMessage] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
