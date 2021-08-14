/*
 * Identify all roots in LeafDB.app.Concept; there should be exactly 1 for each domain
 * Author: Arthur.Goldberg@mssm.edu
 */

/*

DELETE
FROM LeafDB.app.Concept
WHERE ExternalId = N'Example ExternalId';

-- Insert test rows
INSERT INTO LeafDB.app.Concept(Id,
                               ParentId,
                               ExternalId,
                               IsRoot,
                               UiDisplayName)
VALUES (NEWID(),
        (SELECT TOP 1 Id
         FROM LeafDB.app.Concept),
        N'Example ExternalId',
        1,
        N'IsRoot = 0 AND ParentId is a concept');

INSERT INTO LeafDB.app.Concept(Id,
                               ParentId,
                               ExternalId,
                               IsRoot,
                               UiDisplayName)
VALUES (NEWID(),
        NEWID(),
        N'Example ExternalId',
        1,
        N'IsRoot = 1 AND ParentId is not a concept');

INSERT INTO LeafDB.app.Concept(Id,
                               ParentId,
                               ExternalId,
                               IsRoot,
                               UiDisplayName)
VALUES (NEWID(),
        NEWID(),
        N'Example ExternalId',
        0,
        N'IsRoot = 0 AND ParentId is not a concept');
 */

-- Find each concept that is not a root and whose parent is not a concept
-- Should be empty set
SELECT Id,
       ExternalId,
       UiDisplayName,
       IsRoot
FROM LeafDB.app.Concept
WHERE IsRoot = 0
      AND ParentId NOT IN (SELECT Id
                           FROM LeafDB.app.Concept)
      
