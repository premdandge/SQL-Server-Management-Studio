/*================================================================================
Customer Lightboxes - Query:  Identify Customers that have created/modified lightboxes 
in the last 7 days
==================================================================================*/
GO
SET NOCOUNT ON

DECLARE		@dateset			datetime
SET			@dateset			= CAST(CONVERT(VarChar(12),getdate()-7,101)AS DateTime)+.0625

;WITH		CM -- Country Map
	AS		(
			SELECT 'UNKNOWN' [SalesTeam],'Unknown' [Region],'Unknown' [SubRegion],'Unknown' [Territory],'Unknown' [Country],'Unk' [CountryCode] UNION ALL
			SELECT 'INDIRECT','APAC','Other APAC','Other APAC','India','AFG' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Other EMEA','Yugoslavia','ALB' UNION ALL
			SELECT 'FRANCE','EMEA','S.Europe','France','France','DZA' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Guam','ASM' UNION ALL
			SELECT 'IBERIA','EMEA','S.Europe','Iberia','Spain','AND' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','AGO' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Aruba','AIA' UNION ALL
			SELECT 'Australia/NZ','APAC','Australasia','Australasia','Australia','ATA' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Aruba','ATG' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Argentina','ARG' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Other EMEA','Russia','ARM' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Aruba','ABW' UNION ALL
			SELECT 'Australia/NZ','APAC','Australasia','Australasia','Australia','AUS' UNION ALL
			SELECT 'GLR','EMEA','GLR','GLR','Austria','AUT' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Other EMEA','Russia','AZE' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Bahamas','BHS' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Middle East','Turkey','BHR' UNION ALL
			SELECT 'INDIRECT','APAC','Other APAC','Other APAC','India','BGD' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Barbados','BRB' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Other EMEA','Belarus','BLR' UNION ALL
			SELECT 'BENELUX','EMEA','NEB','Benelux','Belgium','BEL' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Costa Rica','BLZ' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','BEN' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Bermuda','BMU' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Bolivia','BOL' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Other EMEA','Yugoslavia','BIH' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','BWA' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Brazil','BRA' UNION ALL
			SELECT 'HK&SEA','APAC','SEA/HK','SEA','Indonesia','IOT' UNION ALL
			SELECT 'HK&SEA','APAC','SEA/HK','SEA','Malaysia','BRN' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Other EMEA','Bulgaria','BGR' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','BFA' UNION ALL
			SELECT 'HK&SEA','APAC','SEA/HK','SEA','Thailand','KHM' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','Egypt','CMR' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','CPV' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Cayman Islands','CYM' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','TCD' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Chile','CHL' UNION ALL
			SELECT 'INDIRECT','APAC','China','China','China','CHN' UNION ALL
			SELECT 'HK&SEA','APAC','SEA/HK','SEA','Indonesia','CXR' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Colombia','COL' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','Egypt','COG' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','COD' UNION ALL
			SELECT 'Australia/NZ','APAC','Australasia','Australasia','Australia','COK' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Costa Rica','CRI' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','Egypt','CIV' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Central Europe','Croatia','HRV' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Aruba','CUB' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Other EMEA','Cyprus','CYP' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Central Europe','Czech Republic','CZE' UNION ALL
			SELECT 'NORDIC','EMEA','NEB','Northern Europe','Denmark','DNK' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','DJI' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Aruba','DMA' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Dominican Republic','DOM' UNION ALL
			SELECT 'NORTH AMERICA','Americas','N.America','N.America','Canada','CAN' UNION ALL
			SELECT 'NORTH AMERICA','Americas','N.America','N.America','United States','USA' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Ecuador','ECU' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','Egypt','EGY' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','El Salvador','SLV' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','Egypt','ERI' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Other EMEA','Baltic','EST' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','ETH' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Argentina','FLK' UNION ALL
			SELECT 'NORDIC','EMEA','NEB','Northern Europe','Denmark','FRO' UNION ALL
			SELECT 'Australia/NZ','APAC','Australasia','Australasia','Australia','FJI' UNION ALL
			SELECT 'NORDIC','EMEA','NEB','Northern Europe','Finland','FIN' UNION ALL
			SELECT 'FRANCE','EMEA','S.Europe','France','France','FRA' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Costa Rica','GUF' UNION ALL
			SELECT 'FRANCE','EMEA','S.Europe','France','France','PYF' UNION ALL
			SELECT 'FRANCE','EMEA','S.Europe','France','France','ATF' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','Egypt','GAB' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','GMB' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Other EMEA','Georgia','GEO' UNION ALL
			SELECT 'GLR','EMEA','GLR','GLR','Germany','DEU' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','GHA' UNION ALL
			SELECT 'UKI','EMEA','UKI','UKI','United Kingdom','GIB' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Other EMEA','Greece','GRC' UNION ALL
			SELECT 'NORDIC','EMEA','NEB','Northern Europe','Denmark','GRL' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Aruba','GRD' UNION ALL
			SELECT 'FRANCE','EMEA','S.Europe','France','France','GLP' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Guam','GUM' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Guatemala','GTM' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','GIN' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Guyana','GUY' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Aruba','HTI' UNION ALL
			SELECT 'ITALY','EMEA','S.Europe','Italy','Italy','VAT' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Honduras','HND' UNION ALL
			SELECT 'HK&SEA','APAC','SEA/HK','Hong Kong','Hong Kong','HKG' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Other EMEA','Hungary','HUN' UNION ALL
			SELECT 'INDIRECT','EMEA','NEB','Northern Europe','Iceland','ISL' UNION ALL
			SELECT 'INDIRECT','APAC','Other APAC','Other APAC','India','IND' UNION ALL
			SELECT 'HK&SEA','APAC','SEA/HK','SEA','Indonesia','IDN' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Middle East','Turkey','IRN' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Middle East','Turkey','IRQ' UNION ALL
			SELECT 'UKI','EMEA','UKI','UKI','Ireland','IRL' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Middle East','Israel','ISR' UNION ALL
			SELECT 'ITALY','EMEA','S.Europe','Italy','Italy','ITA' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Jamaica','JAM' UNION ALL
			SELECT 'Japan','APAC','Japan','Japan','Japan','JPN' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Middle East','Turkey','JOR' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Other EMEA','Russia','KAZ' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','KEN' UNION ALL
			SELECT 'INDIRECT','APAC','Other APAC','Other APAC','Korea','PRK' UNION ALL
			SELECT 'INDIRECT','APAC','Other APAC','Other APAC','Korea','KOR' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Middle East','Turkey','KWT' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Other EMEA','Russia','KGZ' UNION ALL
			SELECT 'HK&SEA','APAC','SEA/HK','SEA','Thailand','LAO' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Other EMEA','Baltic','LVA' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Middle East','Lebanon','LBN' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','LSO' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','Egypt','LBY' UNION ALL
			SELECT 'GLR','EMEA','GLR','GLR','Austria','LIE' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Other EMEA','Baltic','LTU' UNION ALL
			SELECT 'BENELUX','EMEA','NEB','Benelux','Luxembourg','LUX' UNION ALL
			SELECT 'HK&SEA','APAC','SEA/HK','Hong Kong','Hong Kong','MAC' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Other EMEA','Yugoslavia','MKD' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','MDG' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','MWI' UNION ALL
			SELECT 'HK&SEA','APAC','SEA/HK','SEA','Malaysia','MYS' UNION ALL
			SELECT 'INDIRECT','APAC','Other APAC','Other APAC','India','MDV' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','MLI' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Other EMEA','Malta','MLT' UNION ALL
			SELECT 'FRANCE','EMEA','S.Europe','France','France','MTQ' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','MUS' UNION ALL
			SELECT 'FRANCE','EMEA','S.Europe','France','France','MYT' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Mexico','MEX' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Other EMEA','Russia','MDA' UNION ALL
			SELECT 'FRANCE','EMEA','S.Europe','France','France','MCO' UNION ALL
			SELECT 'INDIRECT','APAC','Other APAC','Other APAC','India','MNG' UNION ALL
			SELECT 'FRANCE','EMEA','S.Europe','France','France','MAR' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','MOZ' UNION ALL
			SELECT 'INDIRECT','APAC','Other APAC','Other APAC','India','MMR' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','NAM' UNION ALL
			SELECT 'INDIRECT','APAC','Other APAC','Other APAC','India','NPL' UNION ALL
			SELECT 'BENELUX','EMEA','NEB','Benelux','Netherlands','NLD' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Aruba','ANT' UNION ALL
			SELECT 'Australia/NZ','APAC','Australasia','Australasia','Australia','NCL' UNION ALL
			SELECT 'Australia/NZ','APAC','Australasia','Australasia','New Zealand','NZL' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Aruba','NIC' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','NGA' UNION ALL
			SELECT 'Australia/NZ','APAC','Australasia','Australasia','Australia','NIU' UNION ALL
			SELECT 'HK&SEA','APAC','SEA/HK','SEA','Philippines','MNP' UNION ALL
			SELECT 'NORDIC','EMEA','NEB','Northern Europe','Norway','NOR' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Middle East','Turkey','OMN' UNION ALL
			SELECT 'INDIRECT','APAC','Other APAC','Other APAC','India','PAK' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Middle East','Turkey','PSE' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Panama','PAN' UNION ALL
			SELECT 'HK&SEA','APAC','SEA/HK','SEA','Indonesia','PNG' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Paraguay','PRY' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Peru','PER' UNION ALL
			SELECT 'HK&SEA','APAC','SEA/HK','SEA','Philippines','PHL' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Other EMEA','Poland','POL' UNION ALL
			SELECT 'IBERIA','EMEA','S.Europe','Iberia','Portugal','PRT' UNION ALL
			SELECT 'IBERIA','EMEA','S.Europe','Iberia','Portugal','PR1' UNION ALL
			SELECT 'IBERIA','EMEA','S.Europe','Iberia','Portugal','PR2' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Puerto Rico','PRI' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Middle East','Turkey','QAT' UNION ALL
			SELECT 'FRANCE','EMEA','S.Europe','France','France','REU' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Other EMEA','Romania','ROM' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Other EMEA','Russia','RUS' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','Egypt','RWA' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Aruba','KNA' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Aruba','LCA' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Guam','WSM' UNION ALL
			SELECT 'ITALY','EMEA','S.Europe','Italy','Italy','SMR' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Middle East','Turkey','SAU' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','SEN' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','Egypt','SYC' UNION ALL
			SELECT 'HK&SEA','APAC','SEA/HK','SEA','Singapore','SGP' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Central Europe','Czech Republic','SVK' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Central Europe','Slovenia','SVN' UNION ALL
			SELECT 'Australia/NZ','APAC','Australasia','Australasia','Australia','SLB' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','ZAF' UNION ALL
			SELECT 'IBERIA','EMEA','S.Europe','Iberia','Spain','ESP' UNION ALL
			SELECT 'IBERIA','EMEA','S.Europe','Iberia','Spain','ES1' UNION ALL
			SELECT 'HK&SEA','APAC','SEA/HK','SEA','Sri Lanka','LKA' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Aruba','VCT' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','SDN' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Other EMEA','Russia','SUR' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','SWZ' UNION ALL
			SELECT 'NORDIC','EMEA','NEB','Northern Europe','Sweden','SWE' UNION ALL
			SELECT 'GLR','EMEA','GLR','GLR','Switzerland','CHE' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Middle East','Turkey','SYR' UNION ALL
			SELECT 'HK&SEA','APAC','SEA/HK','Hong Kong','Taiwan','TWN' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Other EMEA','Russia','TJK' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','Egypt','TZA' UNION ALL
			SELECT 'HK&SEA','APAC','SEA/HK','SEA','Thailand','THA' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','TGO' UNION ALL
			SELECT 'Australia/NZ','APAC','Australasia','Australasia','Australia','TON' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Trinidad and Tobago','TTO' UNION ALL
			SELECT 'FRANCE','EMEA','S.Europe','France','France','TUN' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Middle East','Turkey','TUR' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Aruba','TCA' UNION ALL
			SELECT 'Australia/NZ','APAC','Australasia','Australasia','Australia','TUV' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','Egypt','UGA' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Other EMEA','Ukraine','UKR' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Middle East','United Arab Emirates','ARE' UNION ALL
			SELECT 'UKI','EMEA','UKI','UKI','United Kingdom','GBR' UNION ALL
			SELECT 'UKI','EMEA','UKI','UKI','United Kingdom','GB1' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Uruguay','URY' UNION ALL
			SELECT 'NORTH AMERICA','Americas','N.America','N.America','United States','UMI' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Other EMEA','Russia','UZB' UNION ALL
			SELECT 'Australia/NZ','APAC','Australasia','Australasia','Australia','VUT' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Venezuela','VEN' UNION ALL
			SELECT 'HK&SEA','APAC','SEA/HK','SEA','Vietnam','VNM' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Virgin Islands','VGB' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Virgin Islands','VIR' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','ESH' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Middle East','Turkey','YEM' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Other EMEA','Yugoslavia','YUG' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','ZMB' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','ZWE' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','Equatorial Guinea','GNQ' UNION ALL
			SELECT 'UNKNOWN','Unknown','Unknown','Unknown','Unknown','ALL' UNION ALL
			SELECT 'Australia/NZ','APAC','Australasia','Australasia','Australia','PCN' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','BDI' UNION ALL
			SELECT 'INDIRECT','APAC','Other APAC','Other APAC','India','BTN' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','BVT' UNION ALL
			SELECT 'Australia/NZ','APAC','Australasia','Australasia','Australia','CCK' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','COM' UNION ALL
			SELECT 'HK&SEA','APAC','SEA/HK','SEA','Indonesia','FSM' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','GNB' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','HMD' UNION ALL
			SELECT 'Australia/NZ','APAC','Australasia','Australasia','Australia','KIR' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','LBR' UNION ALL
			SELECT 'Australia/NZ','APAC','Australasia','Australasia','Australia','MHL' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','MRT' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Montserrat','MSR' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','NER' UNION ALL
			SELECT 'Australia/NZ','APAC','Australasia','Australasia','Australia','NFK' UNION ALL
			SELECT 'HK&SEA','APAC','SEA/HK','SEA','Indonesia','NRU' UNION ALL
			SELECT 'HK&SEA','APAC','SEA/HK','SEA','Indonesia','PLW' UNION ALL
			SELECT 'INDIRECT','Americas','L.America','L.America','Argentina','SGS' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','SHN' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Other EMEA','Russia','SJM' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','SLE' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','SOM' UNION ALL
			SELECT 'FRANCE','EMEA','S.Europe','France','France','SPM' UNION ALL
			SELECT 'IBERIA','EMEA','S.Europe','Iberia','Portugal','STP' UNION ALL
			SELECT 'Australia/NZ','APAC','Australasia','Australasia','New Zealand','TKL' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Other EMEA','Turkmenistan','TKM' UNION ALL
			SELECT 'HK&SEA','APAC','SEA/HK','SEA','Philippines','TMP' UNION ALL
			SELECT 'Australia/NZ','APAC','Australasia','Australasia','Australia','WLF' UNION ALL
			SELECT 'INDIRECT','EMEA','Other EMEA','Africa','South Africa','CAF'
			)
			/*=============================================================================
				Pull all details for these lightboxes
			===============================================================================*/	
			,LBD -- LIGHT BOX DETAILS
	AS		(
			SELECT		--DISTINCT --TOP 100 
						cr.nvchcountryname							[BillingCountry]
						, i.nchcountrycode							[BillingCountryCode]
						, m.iCompanyID
						, i.iIndividualID
						, i.vchGivenName
							+ ' '
							+ i.vchFamilyName						[CreatedBy]
						, i.vchUserName
						, m.iMediaBinID								[LightBoxID]
						, m.vchmediabinname							[LightboxName]
						, CONVERT(VarChar(8),m.dtCreated,112)		[LightboxCreated]
						, os.vchOriginalSystemName					[Site]
						, i.iOrgTypeCategoryOrgTypeRelID
						
						, mi.vchMasterID
						, convert(varchar(8),m.dtModified,112)		[dtLastModified]
						, convert(varchar(8),mi.dtcreated,112)		[DateItemAdded]
						
			FROM		wcds.dbo.mediabin m WITH(NOLOCK)
			JOIN		wcds.dbo.mediabinitem mi WITH(NOLOCK)
					ON	m.imediabinid = mi.imediabinid
					AND	(
						m.dtCreated		> @dateset
					OR	m.dtModified	> @dateset
						)
			JOIN		wcds.dbo.individual i WITH(NOLOCK)
					ON	i.nchcountrycode IN ('ATA','AUS','IOT','BRN','KHM','CXR','COK','FJI','HKG','IDN','JPN','LAO','MAC','MYS','NCL','NZL','NIU','MNP','PNG','PHL','SGP','SLB','LKA','TWN','THA','TON','TUV','VUT','VNM','PCN','CCK','FSM','KIR','MHL','NFK','NRU','PLW','TKL','TMP','WLF')
					AND	i.iindividualid = m.iCreatedByID
			LEFT JOIN	wcds.dbo.countryreadonly cr WITH(NOLOCK)
					ON	i.nchcountrycode = cr.nchcountrycode
			LEFT JOIN	wcds.dbo.OriginalSystem os 
					ON	m.iOriginalSystemID=os.iOriginalSystemID
			)

			,LBI -- LIGHT BOX ITEMS
	AS		(
			SELECT		T1.[LightBoxID]
						,COUNT(DISTINCT vchMasterID)																			[#ItemsInLightbox]
						,MAX(dtLastModified)																					[LastModified]
						,MAX(DateItemAdded)																						[LastItemAdded]
						,STUFF((SELECT ','+vchMasterID FROM LBD WHERE [LightBoxID] = T1.[LightBoxID] for xml path('')),1,1,'')	[LightBoxList]
			FROM		LBD T1
			GROUP BY	T1.[LightBoxID]
			)
			,LBD2 -- LIGHT BOX DETAILS 2
	AS		(
			SELECT		--DISTINCT 
						x.[BillingCountry]
						,x.[BillingCountryCode]
						,x.iCompanyID
						,x.iIndividualID
						,x.CreatedBy
						,x.vchUserName
						,x.LightBoxID
						,x.LightBoxName
						,x.[LightboxCreated]
						,x.[Site]
						
						,y.[LastModified]
						,y.[LastItemAdded]
						,y.[#ItemsInLightbox]
						,y.[LightBoxList]
						
						,oc.OrgTypeCategoryName
						,ot.OrgTypeName			
						,email.vchemailaddress		[Email]
						,ph.vchphonenumber			[ContactPhone]
						
			FROM		LBD x
			LEFT JOIN	LBI y 
					ON	x.LightBoxID=y.LightBoxID
					
			LEFT JOIN	wcds.dbo.OrgTypeCategoryOrgTypeRel o   
					on	o.OrgTypeCategoryOrgTypeRelID =x.iOrgTypeCategoryOrgTypeRelID
			LEFT JOIN	wcds.dbo.OrgType ot 
					ON	o.OrgTypeID=ot.OrgTypeID
			LEFT JOIN	wcds.dbo.OrgTypeCategory oc 
					ON	o.OrgTypeCategoryID= oc.OrgTypeCategoryID
			LEFT JOIN	wcds.dbo.email email						    
					ON	email.iindividualid = x.iindividualid
			LEFT JOIN	wcds.dbo.phone ph							
					ON	ph.ientityid = x.iindividualid
					AND	itechnologytypeid = 400
					AND	iusagetypeid = 302
			)
			,ASS -- ASSIGNMENTS
	AS		(
			SELECT		co.icompanyid [companyid]
						,co.vchCompanyName [CompanyName]
						,MAX(CASE sci.iCompensationRoleID when 1 THEN ae.vchgivenname + ' ' + ae.vchfamilyname END)		as [StillsAE]
						,MAX(CASE sci.iCompensationRoleID when 6 THEN ae.vchgivenname + ' ' + ae.vchfamilyname END)		as [OutsideAE]
						,MAX(CASE sci.iCompensationRoleID when 11 THEN ae.vchgivenname + ' ' + ae.vchfamilyname END)	as [Researcher]
			FROM		wcds.dbo.CompanySCIUserRel sci
			JOIN		wcds.dbo.company co				
					ON	co.icompanyid = sci.icompanyid
					AND	sci.iCompensationRoleID in (6,1,11)	-- OutsideAE,Stills AE,Researcher
					AND	sci.istatusid = 1					--Still active
			JOIN	wcds.dbo.individual ae			
					ON	ae.iindividualid = sci.iSCIOwnerId
			GROUP BY	co.icompanyid,co.vchCompanyName
			)
SELECT		DISTINCT 
			b.SalesTeam
			,b.Region
			,b.SubRegion
			,b.Territory
			,c.StillsAE
			,c.OutsideAE
			,c.Researcher
			,c.[CompanyName]
			,a.*
FROM		LBD2 a
LEFT JOIN	CM b 
		ON	b.CountryCode = a.[BillingCountryCode]
LEFT JOIN	ASS  c  
		ON	a.iCompanyID=c.CompanyID
WHERE		SalesTeam IN ('Australia/NZ','Japan','HK&SEA')
	AND		vchUserName <> 'Unknown User'
	AND		vchUserName <> 'Unknown'
--SalesTeam = 'Australia/NZ'
--SalesTeam = 'BENELUX'
--SalesTeam = 'FRANCE'
--SalesTeam = 'GLR'
--SalesTeam = 'HK&SEA'
--SalesTeam = 'IBERIA'
--SalesTeam = 'INDIRECT'
--SalesTeam = 'ITALY'
--SalesTeam = 'Japan'
--SalesTeam = 'NORDIC'
--SalesTeam = 'NORTH AMERICA'
--SalesTeam = 'UKI'
GO

