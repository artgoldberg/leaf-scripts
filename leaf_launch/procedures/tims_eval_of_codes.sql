/*
 * From Tim's email on "Additional tables desired in src.caboodle"
 */
select

eap.ProcedureEpicId

,eap.SurgicalProcedureEpicId

,eap.Code

,eap.CodeSet

,cd.ProcedureEpicId

,cd.SurgicalProcedureEpicId

,cd.Code

,cd.CodeSet

,count(*)

from SurgicalProcedureEventFact spef

join ProcedureDim eap

on spef.ProcedureDurableKey = eap.DurableKey

and eap.IsCurrent = 1

join ProcedureDim cd

on spef.ProcedureCodeDurableKey = cd.DurableKey

and cd.IsCurrent = 1

where spef.ProcedureDurableKey > 0

and spef.ProcedureCodeDurableKey > 0

and substring(eap.SurgicalProcedureEpicId, 4, 5) != cd.Code

and cd.Code != '*Unspecified'

group by

eap.ProcedureEpicId

,eap.SurgicalProcedureEpicId

,eap.Code

,eap.CodeSet

,cd.ProcedureEpicId

,cd.SurgicalProcedureEpicId

,cd.Code

,cd.CodeSet