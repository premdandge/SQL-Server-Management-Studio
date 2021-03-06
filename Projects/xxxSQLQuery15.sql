USE [Getty_Images_US_Inc__MSCRM]
GO

IF  EXISTS (SELECT * FROM sys.fulltext_indexes fti WHERE fti.object_id = OBJECT_ID(N'[dbo].[DocumentIndex]'))
DROP FULLTEXT INDEX ON [dbo].[DocumentIndex]
GO

IF  EXISTS (SELECT * FROM sysfulltextcatalogs ftc WHERE ftc.name = N'ftcat_documentindex_9e0efd13ecab427f974e7f1336eb7159')
DROP FULLTEXT CATALOG [ftcat_documentindex_9e0efd13ecab427f974e7f1336eb7159]
GO

ALTER DATABASE [Getty_Images_US_Inc__MSCRM]
REMOVE FILE  [ftrow_ftcat_documentindex_9e0efd13ecab427f974e7f1336eb7159]
GO
ALTER DATABASE [Getty_Images_US_Inc__MSCRM]
REMOVE FILEGROUP [ftfg_ftcat_documentindex_9e0efd13ecab427f974e7f1336eb7159] 
GO

ALTER DATABASE [Getty_Images_US_Inc__MSCRM]
ADD FILEGROUP [FullText]
GO
ALTER DATABASE [Getty_Images_US_Inc__MSCRM]
ADD FILE ( NAME = N'FullTextData', FILENAME = N'D:\SQL\MSSQL10_50.MSSQLSERVER\MSSQL\FTData\FullTextData.ndf' , SIZE = 1024KB , MAXSIZE = UNLIMITED, FILEGROWTH = 10%)
TO FILEGROUP [FullText]
GO

IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [Getty_Images_US_Inc__MSCRM].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO

IF NOT EXISTS (SELECT * FROM sysfulltextcatalogs ftc WHERE ftc.name = N'FullTextCatalog')
CREATE FULLTEXT CATALOG [FullTextCatalog]
ON FILEGROUP [FullText]
WITH ACCENT_SENSITIVITY = ON
AS DEFAULT
AUTHORIZATION [dbo]
GO

IF not EXISTS (SELECT * FROM sys.fulltext_indexes fti WHERE fti.object_id = OBJECT_ID(N'[dbo].[DocumentIndex]'))
CREATE FULLTEXT INDEX ON [dbo].[DocumentIndex](
[KeyWords] LANGUAGE [English], 
[SearchText] LANGUAGE [English], 
[Title] LANGUAGE [English])
KEY INDEX [cndx_PrimaryKey_DocumentIndex] ON  ([FullTextCatalog],FILEGROUP [FullText])
WITH CHANGE_TRACKING AUTO
GO



INSERT INTO [dbo].[DocumentIndex]
           ([DocumentIndexId]
           ,[SubjectId]
           ,[OrganizationId]
           ,[IsPublished]
           ,[DocumentTypeCode]
           ,[DocumentId]
           ,[Location]
           ,[Title]
           ,[Number]
           ,[KeyWords]
           ,[SearchText]
           ,[CreatedOn]
           ,[ModifiedBy]
           ,[ModifiedOn]
           ,[CreatedBy]
           ,[ModifiedOnBehalfBy]
           ,[CreatedOnBehalfBy])
     VALUES
           (NEWID()
           ,(SELECT TOP 1 SubjectId FROM dbo.SubjectBase)
           ,(SELECT TOP 1 OrganizationId FROM dbo.OrganizationBase)
           ,0
           ,1
           ,NEWID()
           ,''
           ,''
           ,''
           ,''
           ,''
           ,getdate()
           ,NEWID()
           ,getdate()
           ,NEWID()
           ,NEWID()
           ,NEWID())
GO 100










SELECT		FULLTEXTCATALOGPROPERTY (ftc.name,'IndexSize')
		,a.*
FROM		sys.fileGroups fg
LEFT JOIN	sys.allocation_units a 
	ON	a.data_space_id = fg.data_space_id

LEFT JOIN	sys.fulltext_indexes fti
	ON	a.data_space_id = fti.data_space_id
LEFT JOIN	sys.fulltext_catalogs ftc
	ON	fti.fulltext_catalog_id = ftc.fulltext_catalog_id

LEFT JOIN	sys.partitions p 
	ON	p.partition_id = a.container_id
LEFT JOIN	sys.internal_tables it 
	ON	p.object_id = it.object_id



SELECT * FROM sys.fulltext_catalogs 
SELECT * FROM sys.fulltext_indexes


IF  EXISTS (SELECT * FROM sys.fulltext_indexes fti WHERE fti.object_id = OBJECT_ID(N'[dbo].[DocumentIndex]'))
DROP FULLTEXT INDEX ON [dbo].[DocumentIndex]
GO

IF  EXISTS (SELECT * FROM sysfulltextcatalogs ftc WHERE ftc.name = N'FullTextCatalog')
DROP FULLTEXT CATALOG [FullTextCatalog]
GO
ALTER DATABASE [Getty_Images_US_Inc__MSCRM]
REMOVE FILE  [FullTextData]
GO
ALTER DATABASE [Getty_Images_US_Inc__MSCRM]
REMOVE FILEGROUP [FullText] 
GO
