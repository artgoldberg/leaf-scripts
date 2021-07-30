/*
 * Map Epic diagnosis codes to ICD10CM codes.
 * Filter to Epic codes that map 1-to-1 to ICD10 and have been used in clinical events.
 * Author: Arthur.Goldberg@mssm.edu
 */

-- get count of mapped ICD10 codes for each Epic id 
WITH epic_id_map_freq AS
    (SELECT DiagnosisDim.DiagnosisEpicId, COUNT(DTD.Value) num_ICD10_codes
    FROM src.caboodle.DiagnosisDim DiagnosisDim 
         INNER JOIN caboodle.DiagnosisTerminologyDim DTD ON DiagnosisDim.DiagnosisKey = DTD.DiagnosisKey
    WHERE DTD.[Type] = 'ICD-10-CM'
    GROUP BY DiagnosisDim.DiagnosisEpicId)

-- get Epic diagnosis codes that map 1-to-1 to ICD10
SELECT DiagnosisDim.DiagnosisEpicId, DiagnosisDim.name EpicName, DTD.Value ICD10_code, DTD.DisplayString ICD10_name
FROM src.caboodle.DiagnosisDim DiagnosisDim 
     INNER JOIN caboodle.DiagnosisTerminologyDim DTD ON DiagnosisDim.DiagnosisKey = DTD.DiagnosisKey
WHERE DTD.[Type] = 'ICD-10-CM'
    AND DiagnosisDim.DiagnosisEpicId IN (SELECT DiagnosisEpicId
                                         FROM epic_id_map_freq
                                         WHERE epic_id_map_freq.num_ICD10_codes = 1)
    -- get active diagnoses
    AND DiagnosisDim.DiagnosisEpicId IN (SELECT DISTINCT DiagnosisKey
                                         FROM src.caboodle.DiagnosisEventFact)
