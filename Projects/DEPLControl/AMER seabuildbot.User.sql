USE [DEPLcontrol]
GO
/****** Object:  User [AMER\seabuildbot]    Script Date: 10/4/2013 11:02:04 AM ******/
CREATE USER [AMER\seabuildbot] FOR LOGIN [AMER\seabuildbot] WITH DEFAULT_SCHEMA=[dbo]
GO
ALTER ROLE [db_owner] ADD MEMBER [AMER\seabuildbot]
GO
