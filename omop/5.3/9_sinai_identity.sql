/*
* Add Sinai's identity to the LeafDB
*/
DELETE FROM [network].[Identity]
INSERT INTO [network].[Identity] ([Lock], [Name], [Abbreviation], [Description], [TotalPatients], [Latitude], [Longitude], [PrimaryColor], [SecondaryColor])
SELECT 
    [Lock] = 'X'
   ,[Name] = 'Mount Sinai Health System'
   ,[Abbreviation] = 'MSHS'
   ,[Description] = 'The Mount Sinai Health System is an integrated health care system providing exceptional medical care to our local and global communities.'
   ,[TotalPatients] = 13000000
   ,[Latitude] = 40.79
   ,[Longitude] = -73.95
   ,[PrimaryColor] = '#06ABEB'
   ,[SecondaryColor] = '#DC298D'
