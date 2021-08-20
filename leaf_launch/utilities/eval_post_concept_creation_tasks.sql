-- Evaluate the updates made by post_concept_creation_tasks.sql

-- Provide counts of concepts that 1) need patient counts and 2) have been recently updated
USE LeafDB;

DECLARE @num_concepts_need_patient_counts INT = (SELECT COUNT(*)
                                                 FROM app.Concept
                                                 WHERE IsPatientCountAutoCalculated IS NULL
                                                 OR IsPatientCountAutoCalculated = 1)
PRINT CAST(@num_concepts_need_patient_counts AS VARCHAR) +
    ' records in app.Concept should have patient counts.'

-- todo: make this time period an input param
DECLARE @hours_ago INT = 12

DECLARE @now_minus_hours_ago DATETIME = dateadd(hour, -@hours_ago, GETDATE())
PRINT '@now_minus_hours_ago: ' + CONVERT(VARCHAR, @now_minus_hours_ago, 120)

DECLARE @num_concepts_w_recent_patient_counts INT = (SELECT COUNT(*)
                                                     FROM app.Concept
                                                     WHERE (IsPatientCountAutoCalculated IS NULL
                                                     OR IsPatientCountAutoCalculated = 1)
                                                     AND UiDisplayPatientCount IS NOT NULL
                                                     AND @now_minus_hours_ago < PatientCountLastUpdateDateTime)

PRINT CAST(@num_concepts_w_recent_patient_counts AS VARCHAR) +
    ' of the records in app.Concept that should have patient counts were updated in the last ' +
    CAST(@hours_ago AS VARCHAR) + ' hours'


-- latest update timestamps of indices of concepts?
