DELETE FROM leaf_setup.athena.CONCEPT;
DELETE FROM leaf_setup.athena.CONCEPT_ANCESTOR;
DELETE FROM leaf_setup.athena.CONCEPT_CLASS;
DELETE FROM leaf_setup.athena.CONCEPT_RELATIONSHIP;
DELETE FROM leaf_setup.athena.CONCEPT_SYNONYM;
DELETE FROM leaf_setup.athena.[DOMAIN];
DELETE FROM leaf_setup.athena.DRUG_STRENGTH;
DELETE FROM leaf_setup.athena.RELATIONSHIP;
DELETE FROM leaf_setup.athena.VOCABULARY;

BULK INSERT leaf_setup.athena.CONCEPT
   FROM '/tmp/vocabulary_download_v5_{ac0c225f-6b7e-440f-bb9d-ca03bdcf93c6}_1617400890873/CONCEPT.csv'
   WITH (  
         ROWTERMINATOR ='\n'
         , FIRSTROW=2
        );

BULK INSERT leaf_setup.athena.CONCEPT_ANCESTOR
   FROM '/tmp/vocabulary_download_v5_{ac0c225f-6b7e-440f-bb9d-ca03bdcf93c6}_1617400890873/CONCEPT_ANCESTOR.csv'
   WITH (  
         ROWTERMINATOR ='\n'
         , FIRSTROW=2
        );

BULK INSERT leaf_setup.athena.CONCEPT_CLASS
   FROM '/tmp/vocabulary_download_v5_{ac0c225f-6b7e-440f-bb9d-ca03bdcf93c6}_1617400890873/CONCEPT_CLASS.csv'
   WITH (  
         ROWTERMINATOR ='\n'
         , FIRSTROW=2
        );

BULK INSERT leaf_setup.athena.CONCEPT_RELATIONSHIP
   FROM '/tmp/vocabulary_download_v5_{ac0c225f-6b7e-440f-bb9d-ca03bdcf93c6}_1617400890873/CONCEPT_RELATIONSHIP.csv'
   WITH (  
         ROWTERMINATOR ='\n'
         , FIRSTROW=2
        );

BULK INSERT leaf_setup.athena.CONCEPT_SYNONYM
   FROM '/tmp/vocabulary_download_v5_{ac0c225f-6b7e-440f-bb9d-ca03bdcf93c6}_1617400890873/CONCEPT_SYNONYM.csv'
   WITH (  
         ROWTERMINATOR ='\n'
         , FIRSTROW=2
        );

BULK INSERT leaf_setup.athena.[DOMAIN]
   FROM '/tmp/vocabulary_download_v5_{ac0c225f-6b7e-440f-bb9d-ca03bdcf93c6}_1617400890873/DOMAIN.csv'
   WITH (  
         ROWTERMINATOR ='\n'
         , FIRSTROW=2
        );

-- failed: VALID_START_DATE & VALID_END_DATE must allow NULL
-- BULK INSERT leaf_setup.athena.DRUG_STRENGTH
--    FROM '/tmp/vocabulary_download_v5_{ac0c225f-6b7e-440f-bb9d-ca03bdcf93c6}_1617400890873/DRUG_STRENGTH.csv'
--    WITH (  
--          ROWTERMINATOR ='\n'
--          , FIRSTROW=2
--         );

BULK INSERT leaf_setup.athena.RELATIONSHIP
   FROM '/tmp/vocabulary_download_v5_{ac0c225f-6b7e-440f-bb9d-ca03bdcf93c6}_1617400890873/RELATIONSHIP.csv'
   WITH (  
         ROWTERMINATOR ='\n'
         , FIRSTROW=2
        );

BULK INSERT leaf_setup.athena.VOCABULARY
   FROM '/tmp/vocabulary_download_v5_{ac0c225f-6b7e-440f-bb9d-ca03bdcf93c6}_1617400890873/VOCABULARY.csv'
   WITH (  
         ROWTERMINATOR ='\n'
         , FIRSTROW=2
        );
