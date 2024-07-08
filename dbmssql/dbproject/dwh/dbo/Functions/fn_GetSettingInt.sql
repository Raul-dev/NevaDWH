
/*
SELECT * FROM sys.sql_modules WHERE object_id  in (
SELECT object_id  FROM sys.objects WHERE name= 'fn_GetSettigValue'
)
DROP TABLE [dbo].[Setting]
CREATE TABLE [dbo].[Setting] (
SettingID    varchar(50) Primary Key,
StrValue nvarchar(256)
)

DROP FUNCTION [dbo].[fn_GetSettigValue]
SELECT [dbo].[fn_GetSettingValue]('dx')
*/
CREATE     Function [dbo].[fn_GetSettingInt](
    @SettingID    varchar(50)
) RETURNS INT
AS
BEGIN
    RETURN (SELECT CAST(LTRIM(StrValue) AS INT) FROM [dbo].[Setting] WITH( NOLOCK ) WHERE SettingID = @SettingID)
END