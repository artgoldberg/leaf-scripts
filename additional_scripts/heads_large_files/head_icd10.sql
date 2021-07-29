/*
 * Load the UMLS_ICD10 table with the ICD10 hierarchy obtained from, I presume, the UMLS 
 * Computable Hierarchies File (MRHIER.RRF). This file samples the head of icd10_test.sql.
 * It's not clear why this file is not represented as 'CREATE TABLE' statement for UMLS_ICD10 and
 * a BULK INSERT command of a data file containing the values below.
 */
USE [rpt]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [LEAF_SCRATCH].[UMLS_ICD10](
	[AUI] [nvarchar](20) NULL,
	[ParentAUI] [nvarchar](20) NULL,
	[MinCode] [nvarchar](20) NULL,
	[MaxCode] [nvarchar](20) NULL,
	[CodeCount] [int] NULL,
	[OntologyType] [nvarchar](20) NULL,
	[SqlSetWhere] [nvarchar](1000) NULL,
	[UiDisplayName] [nvarchar](1000) NULL
) ON [PRIMARY]
GO
INSERT [LEAF_SCRATCH].[UMLS_ICD10] ([AUI], [ParentAUI], [MinCode], [MaxCode], [CodeCount], [OntologyType], [SqlSetWhere], [UiDisplayName]) VALUES (N'A17773406', N'A17786169', N'A03.3', N'A03.3', 1, N'ICD10CM', N'= ''A03.3''', N'Shigellosis due to Shigella sonnei (ICD10CM:A03.3)')
INSERT [LEAF_SCRATCH].[UMLS_ICD10] ([AUI], [ParentAUI], [MinCode], [MaxCode], [CodeCount], [OntologyType], [SqlSetWhere], [UiDisplayName]) VALUES (N'A17773417', N'A17786178', N'A08.11', N'A08.11', 1, N'ICD10CM', N'= ''A08.11''', N'Acute gastroenteropathy due to Norwalk agent (ICD10CM:A08.11)')
INSERT [LEAF_SCRATCH].[UMLS_ICD10] ([AUI], [ParentAUI], [MinCode], [MaxCode], [CodeCount], [OntologyType], [SqlSetWhere], [UiDisplayName]) VALUES (N'A17773418', N'A17837361', N'A08.31', N'A08.31', 1, N'ICD10CM', N'= ''A08.31''', N'Calicivirus enteritis (ICD10CM:A08.31)')
INSERT [LEAF_SCRATCH].[UMLS_ICD10] ([AUI], [ParentAUI], [MinCode], [MaxCode], [CodeCount], [OntologyType], [SqlSetWhere], [UiDisplayName]) VALUES (N'A17773419', N'A17837361', N'A08.32', N'A08.32', 1, N'ICD10CM', N'= ''A08.32''', N'Astrovirus enteritis (ICD10CM:A08.32)')
INSERT [LEAF_SCRATCH].[UMLS_ICD10] ([AUI], [ParentAUI], [MinCode], [MaxCode], [CodeCount], [OntologyType], [SqlSetWhere], [UiDisplayName]) VALUES (N'A17773436', N'A17773435', N'A22.7', N'A22.7', 1, N'ICD10CM', N'= ''A22.7''', N'Anthrax sepsis (ICD10CM:A22.7)')
INSERT [LEAF_SCRATCH].[UMLS_ICD10] ([AUI], [ParentAUI], [MinCode], [MaxCode], [CodeCount], [OntologyType], [SqlSetWhere], [UiDisplayName]) VALUES (N'A17773475', N'A17824770', N'A50.9', N'A50.9', 1, N'ICD10CM', N'= ''A50.9''', N'Congenital syphilis, unspecified (ICD10CM:A50.9)')
INSERT [LEAF_SCRATCH].[UMLS_ICD10] ([AUI], [ParentAUI], [MinCode], [MaxCode], [CodeCount], [OntologyType], [SqlSetWhere], [UiDisplayName]) VALUES (N'A17773483', N'A17786251', N'A52.13', N'A52.13', 1, N'ICD10CM', N'= ''A52.13''', N'Late syphilitic meningitis (ICD10CM:A52.13)')
INSERT [LEAF_SCRATCH].[UMLS_ICD10] ([AUI], [ParentAUI], [MinCode], [MaxCode], [CodeCount], [OntologyType], [SqlSetWhere], [UiDisplayName]) VALUES (N'A17773513', N'A18918881', N'A81.00', N'A81.9', 10, N'ICD10CM', N'BETWEEN ''A81.00'' AND ''A81.9''', N'Atypical virus infections of central nervous system (ICD10CM:A81.00-A81.9)')
INSERT [LEAF_SCRATCH].[UMLS_ICD10] ([AUI], [ParentAUI], [MinCode], [MaxCode], [CodeCount], [OntologyType], [SqlSetWhere], [UiDisplayName]) VALUES (N'A17773514', N'A17850208', N'A81.83', N'A81.83', 1, N'ICD10CM', N'= ''A81.83''', N'Fatal familial insomnia (ICD10CM:A81.83)')
INSERT [LEAF_SCRATCH].[UMLS_ICD10] ([AUI], [ParentAUI], [MinCode], [MaxCode], [CodeCount], [OntologyType], [SqlSetWhere], [UiDisplayName]) VALUES (N'A17773520', N'A18918881', N'A85.0', N'A85.8', 4, N'ICD10CM', N'BETWEEN ''A85.0'' AND ''A85.8''', N'Other viral encephalitis, not elsewhere classified (ICD10CM:A85.0-A85.8)')
INSERT [LEAF_SCRATCH].[UMLS_ICD10] ([AUI], [ParentAUI], [MinCode], [MaxCode], [CodeCount], [OntologyType], [SqlSetWhere], [UiDisplayName]) VALUES (N'A17773525', N'A17799039', N'A92.1', N'A92.1', 1, N'ICD10CM', N'= ''A92.1''', N'O''nyong-nyong fever (ICD10CM:A92.1)')
INSERT [LEAF_SCRATCH].[UMLS_ICD10] ([AUI], [ParentAUI], [MinCode], [MaxCode], [CodeCount], [OntologyType], [SqlSetWhere], [UiDisplayName]) VALUES (N'A17773529', N'A17850221', N'A96.2', N'A96.2', 1, N'ICD10CM', N'= ''A96.2''', N'Lassa fever (ICD10CM:A96.2)')
INSERT [LEAF_SCRATCH].[UMLS_ICD10] ([AUI], [ParentAUI], [MinCode], [MaxCode], [CodeCount], [OntologyType], [SqlSetWhere], [UiDisplayName]) VALUES (N'A17773534', N'A17850226', N'B00.51', N'B00.51', 1, N'ICD10CM', N'= ''B00.51''', N'Herpesviral iridocyclitis (ICD10CM:B00.51)')
INSERT [LEAF_SCRATCH].[UMLS_ICD10] ([AUI], [ParentAUI], [MinCode], [MaxCode], [CodeCount], [OntologyType], [SqlSetWhere], [UiDisplayName]) VALUES (N'A17773538', N'A17811915', N'B02.22', N'B02.22', 1, N'ICD10CM', N'= ''B02.22''', N'Postherpetic trigeminal neuralgia (ICD10CM:B02.22)')
INSERT [LEAF_SCRATCH].[UMLS_ICD10] ([AUI], [ParentAUI], [MinCode], [MaxCode], [CodeCount], [OntologyType], [SqlSetWhere], [UiDisplayName]) VALUES (N'A17773546', N'A17773544', N'B08.02', N'B08.02', 1, N'ICD10CM', N'= ''B08.02''', N'Orf virus disease (ICD10CM:B08.02)')
INSERT [LEAF_SCRATCH].[UMLS_ICD10] ([AUI], [ParentAUI], [MinCode], [MaxCode], [CodeCount], [OntologyType], [SqlSetWhere], [UiDisplayName]) VALUES (N'A17773571', N'A17786362', N'B38.1', N'B38.1', 1, N'ICD10CM', N'= ''B38.1''', N'Chronic pulmonary coccidioidomycosis (ICD10CM:B38.1)')
INSERT [LEAF_SCRATCH].[UMLS_ICD10] ([AUI], [ParentAUI], [MinCode], [MaxCode], [CodeCount], [OntologyType], [SqlSetWhere], [UiDisplayName]) VALUES (N'A17773589', N'A17824900', N'B57.42', N'B57.42', 1, N'ICD10CM', N'= ''B57.42''', N'Meningoencephalitis in Chagas'' disease (ICD10CM:B57.42)')
INSERT [LEAF_SCRATCH].[UMLS_ICD10] ([AUI], [ParentAUI], [MinCode], [MaxCode], [CodeCount], [OntologyType], [SqlSetWhere], [UiDisplayName]) VALUES (N'A17773422', N'A17824713', N'A15.5', N'A15.5', 1, N'ICD10CM', N'= ''A15.5''', N'Tuberculosis of larynx, trachea and bronchus (ICD10CM:A15.5)')
INSERT [LEAF_SCRATCH].[UMLS_ICD10] ([AUI], [ParentAUI], [MinCode], [MaxCode], [CodeCount], [OntologyType], [SqlSetWhere], [UiDisplayName]) VALUES (N'A17773445', N'A17850132', N'A30.4', N'A30.4', 1, N'ICD10CM', N'= ''A30.4''', N'Borderline lepromatous leprosy (ICD10CM:A30.4)')
INSERT [LEAF_SCRATCH].[UMLS_ICD10] ([AUI], [ParentAUI], [MinCode], [MaxCode], [CodeCount], [OntologyType], [SqlSetWhere], [UiDisplayName]) VALUES (N'A17773463', N'A17798975', N'A48.1', N'A48.1', 1, N'ICD10CM', N'= ''A48.1''', N'Legionnaires'' disease (ICD10CM:A48.1)')
INSERT [LEAF_SCRATCH].[UMLS_ICD10] ([AUI], [ParentAUI], [MinCode], [MaxCode], [CodeCount], [OntologyType], [SqlSetWhere], [UiDisplayName]) VALUES (N'A17773474', N'A17824770', N'A50.7', N'A50.7', 1, N'ICD10CM', N'= ''A50.7''', N'Late congenital syphilis, unspecified (ICD10CM:A50.7)')
INSERT [LEAF_SCRATCH].[UMLS_ICD10] ([AUI], [ParentAUI], [MinCode], [MaxCode], [CodeCount], [OntologyType], [SqlSetWhere], [UiDisplayName]) VALUES (N'A17773484', N'A17786251', N'A52.15', N'A52.15', 1, N'ICD10CM', N'= ''A52.15''', N'Late syphilitic neuropathy (ICD10CM:A52.15)')
INSERT [LEAF_SCRATCH].[UMLS_ICD10] ([AUI], [ParentAUI], [MinCode], [MaxCode], [CodeCount], [OntologyType], [SqlSetWhere], [UiDisplayName]) VALUES (N'A17773499', N'A18910969', N'A66.0', N'A66.9', 10, N'ICD10CM', N'BETWEEN ''A66.0'' AND ''A66.9''', N'Yaws (ICD10CM:A66.0-A66.9)')
INSERT [LEAF_SCRATCH].[UMLS_ICD10] ([AUI], [ParentAUI], [MinCode], [MaxCode], [CodeCount], [OntologyType], [SqlSetWhere], [UiDisplayName]) VALUES (N'A17773517', N'A17799032', N'A83.4', N'A83.4', 1, N'ICD10CM', N'= ''A83.4''', N'Australian encephalitis (ICD10CM:A83.4)')
INSERT [LEAF_SCRATCH].[UMLS_ICD10] ([AUI], [ParentAUI], [MinCode], [MaxCode], [CodeCount], [OntologyType], [SqlSetWhere], [UiDisplayName]) VALUES (N'A17773524', N'A18924114', N'A91', N'A91', 1, N'ICD10CM', N'= ''A91''', N'Dengue hemorrhagic fever (ICD10CM:A91)')
INSERT [LEAF_SCRATCH].[UMLS_ICD10] ([AUI], [ParentAUI], [MinCode], [MaxCode], [CodeCount], [OntologyType], [SqlSetWhere], [UiDisplayName]) VALUES (N'A17773526', N'A17799039', N'A92.30', N'A92.39', 4, N'ICD10CM', N'BETWEEN ''A92.30'' AND ''A92.39''', N'West Nile virus infection (ICD10CM:A92.30-A92.39)')
INSERT [LEAF_SCRATCH].[UMLS_ICD10] ([AUI], [ParentAUI], [MinCode], [MaxCode], [CodeCount], [OntologyType], [SqlSetWhere], [UiDisplayName]) VALUES (N'A17773530', N'A17850221', N'A96.9', N'A96.9', 1, N'ICD10CM', N'= ''A96.9''', N'Arenaviral hemorrhagic fever, unspecified (ICD10CM:A96.9)')
INSERT [LEAF_SCRATCH].[UMLS_ICD10] ([AUI], [ParentAUI], [MinCode], [MaxCode], [CodeCount], [OntologyType], [SqlSetWhere], [UiDisplayName]) VALUES (N'A17773537', N'A17837482', N'B01.9', N'B01.9', 1, N'ICD10CM', N'= ''B01.9''', N'Varicella without complication (ICD10CM:B01.9)')
INSERT [LEAF_SCRATCH].[UMLS_ICD10] ([AUI], [ParentAUI], [MinCode], [MaxCode], [CodeCount], [OntologyType], [SqlSetWhere], [UiDisplayName]) VALUES (N'A17773542', N'A17837487', N'B06.81', N'B06.89', 3, N'ICD10CM', N'BETWEEN ''B06.81'' AND ''B06.89''', N'Rubella with other complications (ICD10CM:B06.81-B06.89)')
INSERT [LEAF_SCRATCH].[UMLS_ICD10] ([AUI], [ParentAUI], [MinCode], [MaxCode], [CodeCount], [OntologyType], [SqlSetWhere], [UiDisplayName]) VALUES (N'A17773545', N'A17850244', N'B08.011', N'B08.011', 1, N'ICD10CM', N'= ''B08.011''', N'Vaccinia not from vaccine (ICD10CM:B08.011)')
INSERT [LEAF_SCRATCH].[UMLS_ICD10] ([AUI], [ParentAUI], [MinCode], [MaxCode], [CodeCount], [OntologyType], [SqlSetWhere], [UiDisplayName]) VALUES (N'A17773564', N'A17862888', N'B36.1', N'B36.1', 1, N'ICD10CM', N'= ''B36.1''', N'Tinea nigra (ICD10CM:B36.1)')
INSERT [LEAF_SCRATCH].[UMLS_ICD10] ([AUI], [ParentAUI], [MinCode], [MaxCode], [CodeCount], [OntologyType], [SqlSetWhere], [UiDisplayName]) VALUES (N'A17773566', N'A18913609', N'B37.0', N'B37.9', 16, N'ICD10CM', N'BETWEEN ''B37.0'' AND ''B37.9''', N'Candidiasis (ICD10CM:B37.0-B37.9)')
INSERT [LEAF_SCRATCH].[UMLS_ICD10] ([AUI], [ParentAUI], [MinCode], [MaxCode], [CodeCount], [OntologyType], [SqlSetWhere], [UiDisplayName]) VALUES (N'A17773584', N'A17850303', N'B46.4', N'B46.4', 1, N'ICD10CM', N'= ''B46.4''', N'Disseminated mucormycosis (ICD10CM:B46.4)')
INSERT [LEAF_SCRATCH].[UMLS_ICD10] ([AUI], [ParentAUI], [MinCode], [MaxCode], [CodeCount], [OntologyType], [SqlSetWhere], [UiDisplayName]) VALUES (N'A17773602', N'A17824912', N'B69.81', N'B69.89', 2, N'ICD10CM', N'IN (''B69.81'',''B69.89'')', N'Cysticercosis of other sites (ICD10CM:B69.81-B69.89)')
INSERT [LEAF_SCRATCH].[UMLS_ICD10] ([AUI], [ParentAUI], [MinCode], [MaxCode], [CodeCount], [OntologyType], [SqlSetWhere], [UiDisplayName]) VALUES (N'A17773612', N'A18924116', N'B76.0', N'B76.9', 4, N'ICD10CM', N'BETWEEN ''B76.0'' AND ''B76.9''', N'Hookworm diseases (ICD10CM:B76.0-B76.9)')
INSERT [LEAF_SCRATCH].[UMLS_ICD10] ([AUI], [ParentAUI], [MinCode], [MaxCode], [CodeCount], [OntologyType], [SqlSetWhere], [UiDisplayName]) VALUES (N'A17773429', N'A17786186', N'A18.09', N'A18.09', 1, N'ICD10CM', N'= ''A18.09''', N'Other musculoskeletal tuberculosis (ICD10CM:A18.09)')
INSERT [LEAF_SCRATCH].[UMLS_ICD10] ([AUI], [ParentAUI], [MinCode], [MaxCode], [CodeCount], [OntologyType], [SqlSetWhere], [UiDisplayName]) VALUES (N'A17773446', N'A17798957', N'A31.0', N'A31.0', 1, N'ICD10CM', N'= ''A31.0''', N'Pulmonary mycobacterial infection (ICD10CM:A31.0)')
