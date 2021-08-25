-- Epic -> NCD 
SELECT 
	C_EPIC.vocabulary_id AS 'C_EPIC.vocabulary_id'
	, C_EPIC.concept_name AS 'C_EPIC.concept_name'
	, C_NDC.vocabulary_id AS 'C_NDC.vocabulary_id'
	, C_NDC.concept_name AS 'C_NDC.concept_name'
FROM
	cdm_std.concept C_EPIC
	, cdm_std.concept C_NDC
	, cdm_std.concept_relationship CR
WHERE 
	C_EPIC.vocabulary_id = 'EPIC ERX .1'
	AND C_NDC.vocabulary_id = 'NDC'
	AND CR.relationship_id = 'Maps to'
	AND CR.concept_id_1 = C_EPIC.concept_id 
	AND CR.concept_id_2 = C_NDC.concept_id

-- Epic -> RxNorm
SELECT 
	C_EPIC.vocabulary_id AS 'C_EPIC.vocabulary_id'
	, C_EPIC.concept_name AS 'C_EPIC.concept_name'
	, C_RXNORM.vocabulary_id AS 'C_RXNORM.vocabulary_id'
	, C_RXNORM.concept_name AS 'C_RXNORM.concept_name'
FROM
	cdm_std.concept C_EPIC
	, cdm_std.concept C_RXNORM
	, cdm_std.concept_relationship CR
WHERE 
	C_EPIC.vocabulary_id = 'EPIC ERX .1'
	AND C_RXNORM.vocabulary_id IN ('RxNorm', 'RxNorm Extension')
	AND CR.relationship_id = 'Maps to'
	AND CR.concept_id_1 = C_EPIC.concept_id 
	AND CR.concept_id_2 = C_RXNORM.concept_id

-- Concepts in drug_exposure
SELECT *
FROM cdm_std.drug_exposure DE
	, cdm_std.concept C
WHERE DE.drug_source_concept_id = C.concept_id

-- Map from NCD to RxNorm
SELECT C_NDC.vocabulary_id AS 'C_NDC.vocabulary_id'
	, C_NDC.concept_name AS 'C_NDC.concept_name'
	, C_RXNORM.vocabulary_id AS 'C_RXNORM.vocabulary_id'
	, C_RXNORM.concept_name AS 'C_RXNORM.concept_name'
FROM cdm_std.concept C_NDC
	, cdm_std.concept C_RXNORM
	, cdm_std.concept_relationship CR
WHERE C_NDC.vocabulary_id = 'NDC'
	AND C_RXNORM.vocabulary_id IN ('RxNorm', 'RxNorm Extension')
	AND CR.relationship_id = 'Maps to'
	AND CR.concept_id_1 = C_NDC.concept_id 
	AND CR.concept_id_2 = C_RXNORM.concept_id 
