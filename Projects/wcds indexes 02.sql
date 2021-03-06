use [WCDS]
go

CREATE NONCLUSTERED INDEX [_dta_index_Address_9_37575172__K1_K4_K5_K6_K7_K8_K9_K10_K11_K14_13_22] ON [dbo].[Address] 
(
	[iAddressID] ASC,
	[iEntityID] ASC,
	[iEntityTypeID] ASC,
	[vchAddress1] ASC,
	[vchAddress2] ASC,
	[vchAddress3] ASC,
	[vchCity] ASC,
	[chStateCode] ASC,
	[vchProvince] ASC,
	[vchPostalCode] ASC
)
INCLUDE ( [nchCountryCode],
[iValidateAddressStatusID]) WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
go

CREATE STATISTICS [Stat_Address_5_1] ON [dbo].[Address]([iEntityTypeID], [iAddressID])
go

CREATE STATISTICS [Stat_Address_19_21] ON [dbo].[Address]([dtCreated], [dtModified])
go

CREATE STATISTICS [Stat_Address_6_7_8_9_10_11_14_1] ON [dbo].[Address]([vchAddress1], [vchAddress2], [vchAddress3], [vchCity], [chStateCode], [vchProvince], [vchPostalCode], [iAddressID])
go

CREATE STATISTICS [Stat_Address_4_5_6_7_8_9_10_11_14] ON [dbo].[Address]([iEntityID], [iEntityTypeID], [vchAddress1], [vchAddress2], [vchAddress3], [vchCity], [chStateCode], [vchProvince], [vchPostalCode])
go

CREATE NONCLUSTERED INDEX [IX_Email_iIndividualID_vchEmailAddress] ON [dbo].[Email] 
(
	[iIndividualID] ASC,
	[vchEmailAddress] ASC
)WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
go

CREATE STATISTICS [Stat_EMail_5_2] ON [dbo].[Email]([vchEmailAddress], [iIndividualID])
go

CREATE NONCLUSTERED INDEX [IX_Individual_1_17_2_3_4_5_8_9_10_12_I_13_14_15_20_22_24_25_34_51_52_53_54_55_56_57_58_60] ON [dbo].[Individual] 
(
	[iIndividualID] ASC,
	[iPrimMailToAddressID] ASC,
	[iStatusID] ASC,
	[iTypeID] ASC,
	[iOriginalSystemID] ASC,
	[vchUserName] ASC,
	[vchGivenName] ASC,
	[vchMiddleName] ASC,
	[vchFamilyName] ASC,
	[vchTitle] ASC
)
INCLUDE ( [vchOffice],
[nchCountryCode],
[iPrimBillToAddressID],
[dtCreated],
[dtModified],
[iOfficeId],
[dtDateOfBirth],
[tiAssociatedFlag],
[iOrgTypeCategoryOrgTypeRelID],
[iJobTitleCategoryJobTitleRelID],
[vchJobTitleText],
[tiGIPrintedMaterialFlag],
[tiJIPrintedMaterialFlag],
[tiPSPrintedMaterialFlag],
[tiCAPrintedMaterialFlag],
[tiPHPrintedMaterialFlag],
[tiTSPrintedMaterialFlag]) WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
go

CREATE NONCLUSTERED INDEX [IX_Individual_15_17_1_51_52_3_2_4_5_8_9_10_I_12_13_14_20_22_24_25_34_53_54_55_56_57_58_60] ON [dbo].[Individual] 
(
	[iPrimBillToAddressID] ASC,
	[iPrimMailToAddressID] ASC,
	[iIndividualID] ASC,
	[iOrgTypeCategoryOrgTypeRelID] ASC,
	[iJobTitleCategoryJobTitleRelID] ASC,
	[iTypeID] ASC,
	[iStatusID] ASC,
	[iOriginalSystemID] ASC,
	[vchUserName] ASC,
	[vchGivenName] ASC,
	[vchMiddleName] ASC,
	[vchFamilyName] ASC
)
INCLUDE ( [vchTitle],
[vchOffice],
[nchCountryCode],
[dtCreated],
[dtModified],
[iOfficeId],
[dtDateOfBirth],
[tiAssociatedFlag],
[vchJobTitleText],
[tiGIPrintedMaterialFlag],
[tiJIPrintedMaterialFlag],
[tiPSPrintedMaterialFlag],
[tiCAPrintedMaterialFlag],
[tiPHPrintedMaterialFlag],
[tiTSPrintedMaterialFlag]) WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
go

CREATE NONCLUSTERED INDEX [IX_Individual_17_1_2_3_51_52_15_4_5_8_9_10_I_12_13_14_20_22_24_25_34_53_54_55_56_57_58_60] ON [dbo].[Individual] 
(
	[iPrimMailToAddressID] ASC,
	[iIndividualID] ASC,
	[iStatusID] ASC,
	[iTypeID] ASC,
	[iOrgTypeCategoryOrgTypeRelID] ASC,
	[iJobTitleCategoryJobTitleRelID] ASC,
	[iPrimBillToAddressID] ASC,
	[iOriginalSystemID] ASC,
	[vchUserName] ASC,
	[vchGivenName] ASC,
	[vchMiddleName] ASC,
	[vchFamilyName] ASC
)
INCLUDE ( [vchTitle],
[vchOffice],
[nchCountryCode],
[dtCreated],
[dtModified],
[iOfficeId],
[dtDateOfBirth],
[tiAssociatedFlag],
[vchJobTitleText],
[tiGIPrintedMaterialFlag],
[tiJIPrintedMaterialFlag],
[tiPSPrintedMaterialFlag],
[tiCAPrintedMaterialFlag],
[tiPHPrintedMaterialFlag],
[tiTSPrintedMaterialFlag]) WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
go

CREATE STATISTICS [Stat_Individual_1_22] ON [dbo].[Individual]([iIndividualID], [dtModified])
go

CREATE STATISTICS [Stat_Individual_20_22] ON [dbo].[Individual]([dtCreated], [dtModified])
go

CREATE STATISTICS [Stat_Individual_3_17] ON [dbo].[Individual]([iTypeID], [iPrimMailToAddressID])
go

CREATE STATISTICS [Stat_Individual_51_17] ON [dbo].[Individual]([iOrgTypeCategoryOrgTypeRelID], [iPrimMailToAddressID])
go

CREATE STATISTICS [Stat_Individual_52_17_1] ON [dbo].[Individual]([iJobTitleCategoryJobTitleRelID], [iPrimMailToAddressID], [iIndividualID])
go

CREATE STATISTICS [Stat_Individual_52_15_1] ON [dbo].[Individual]([iJobTitleCategoryJobTitleRelID], [iPrimBillToAddressID], [iIndividualID])
go

CREATE STATISTICS [Stat_Individual_3_15_17] ON [dbo].[Individual]([iTypeID], [iPrimBillToAddressID], [iPrimMailToAddressID])
go

CREATE STATISTICS [Stat_Individual_52_15_17] ON [dbo].[Individual]([iJobTitleCategoryJobTitleRelID], [iPrimBillToAddressID], [iPrimMailToAddressID])
go

CREATE STATISTICS [Stat_Individual_1_20_22] ON [dbo].[Individual]([iIndividualID], [dtCreated], [dtModified])
go

CREATE STATISTICS [Stat_Individual_51_15_17] ON [dbo].[Individual]([iOrgTypeCategoryOrgTypeRelID], [iPrimBillToAddressID], [iPrimMailToAddressID])
go

CREATE STATISTICS [Stat_Individual_15_17_1_52] ON [dbo].[Individual]([iPrimBillToAddressID], [iPrimMailToAddressID], [iIndividualID], [iJobTitleCategoryJobTitleRelID])
go

CREATE STATISTICS [Stat_Individual_51_15_1_52] ON [dbo].[Individual]([iOrgTypeCategoryOrgTypeRelID], [iPrimBillToAddressID], [iIndividualID], [iJobTitleCategoryJobTitleRelID])
go

CREATE STATISTICS [Stat_Individual_2_15_1_51_52] ON [dbo].[Individual]([iStatusID], [iPrimBillToAddressID], [iIndividualID], [iOrgTypeCategoryOrgTypeRelID], [iJobTitleCategoryJobTitleRelID])
go

CREATE STATISTICS [Stat_Individual_17_1_3_51_52] ON [dbo].[Individual]([iPrimMailToAddressID], [iIndividualID], [iTypeID], [iOrgTypeCategoryOrgTypeRelID], [iJobTitleCategoryJobTitleRelID])
go

CREATE STATISTICS [Stat_Individual_1_2_3_17_51] ON [dbo].[Individual]([iIndividualID], [iStatusID], [iTypeID], [iPrimMailToAddressID], [iOrgTypeCategoryOrgTypeRelID])
go

CREATE STATISTICS [Stat_Individual_15_1_3_51_52] ON [dbo].[Individual]([iPrimBillToAddressID], [iIndividualID], [iTypeID], [iOrgTypeCategoryOrgTypeRelID], [iJobTitleCategoryJobTitleRelID])
go

CREATE STATISTICS [Stat_Individual_2_15_17_1_51] ON [dbo].[Individual]([iStatusID], [iPrimBillToAddressID], [iPrimMailToAddressID], [iIndividualID], [iOrgTypeCategoryOrgTypeRelID])
go

CREATE STATISTICS [Stat_Individual_15_1_2_3_51] ON [dbo].[Individual]([iPrimBillToAddressID], [iIndividualID], [iStatusID], [iTypeID], [iOrgTypeCategoryOrgTypeRelID])
go

CREATE STATISTICS [Stat_Individual_15_17_1_3_51] ON [dbo].[Individual]([iPrimBillToAddressID], [iPrimMailToAddressID], [iIndividualID], [iTypeID], [iOrgTypeCategoryOrgTypeRelID])
go

CREATE STATISTICS [Stat_Individual_51_52_1_3_2_15] ON [dbo].[Individual]([iOrgTypeCategoryOrgTypeRelID], [iJobTitleCategoryJobTitleRelID], [iIndividualID], [iTypeID], [iStatusID], [iPrimBillToAddressID])
go

CREATE STATISTICS [Stat_Individual_2_17_1_51_52_15] ON [dbo].[Individual]([iStatusID], [iPrimMailToAddressID], [iIndividualID], [iOrgTypeCategoryOrgTypeRelID], [iJobTitleCategoryJobTitleRelID], [iPrimBillToAddressID])
go

CREATE STATISTICS [Stat_Individual_1_2_3_15_17_51] ON [dbo].[Individual]([iIndividualID], [iStatusID], [iTypeID], [iPrimBillToAddressID], [iPrimMailToAddressID], [iOrgTypeCategoryOrgTypeRelID])
go

CREATE STATISTICS [Stat_Individual_1_2_3_4_5_8_9_10_12] ON [dbo].[Individual]([iIndividualID], [iStatusID], [iTypeID], [iOriginalSystemID], [vchUserName], [vchGivenName], [vchMiddleName], [vchFamilyName], [vchTitle])
go

CREATE STATISTICS [Stat_Individual_1_17_15_2_3_4_5_8_9_10] ON [dbo].[Individual]([iIndividualID], [iPrimMailToAddressID], [iPrimBillToAddressID], [iStatusID], [iTypeID], [iOriginalSystemID], [vchUserName], [vchGivenName], [vchMiddleName], [vchFamilyName])
go

CREATE STATISTICS [Stat_Individual_1_15_2_3_4_5_8_9_10_12] ON [dbo].[Individual]([iIndividualID], [iPrimBillToAddressID], [iStatusID], [iTypeID], [iOriginalSystemID], [vchUserName], [vchGivenName], [vchMiddleName], [vchFamilyName], [vchTitle])
go

CREATE STATISTICS [Stat_Individual_1_15_51_52_3_2_4_5_8_9_10] ON [dbo].[Individual]([iIndividualID], [iPrimBillToAddressID], [iOrgTypeCategoryOrgTypeRelID], [iJobTitleCategoryJobTitleRelID], [iTypeID], [iStatusID], [iOriginalSystemID], [vchUserName], [vchGivenName], [vchMiddleName], [vchFamilyName])
go

CREATE STATISTICS [Stat_Individual_51_52_1_3_2_17_4_5_8_9_10] ON [dbo].[Individual]([iOrgTypeCategoryOrgTypeRelID], [iJobTitleCategoryJobTitleRelID], [iIndividualID], [iTypeID], [iStatusID], [iPrimMailToAddressID], [iOriginalSystemID], [vchUserName], [vchGivenName], [vchMiddleName], [vchFamilyName])
go

CREATE STATISTICS [Stat_Individual_17_1_51_52_15_3_2_4_5_8_9_10] ON [dbo].[Individual]([iPrimMailToAddressID], [iIndividualID], [iOrgTypeCategoryOrgTypeRelID], [iJobTitleCategoryJobTitleRelID], [iPrimBillToAddressID], [iTypeID], [iStatusID], [iOriginalSystemID], [vchUserName], [vchGivenName], [vchMiddleName], [vchFamilyName])
go


