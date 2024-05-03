
/*
SELECT * FROM sys.sql_modules WHERE object_id  in (
SELECT object_id  FROM sys.objects WHERE name= 'fn_GetSettigValue'
)
CREATE TABLE [dbo].[Setting] (
SettingID    varchar(50) Primary Key,
StrValue nvarchar(256)
)

DROP FUNCTION [dbo].[fn_GetSettigValue]
*/
CREATE   Function [dbo].[fn_GetSettingValue](
    @SettingID    varchar(50)
) RETURNS nvarchar(256)
AS
BEGIN
    DECLARE @Value nvarchar(256)
    SET @Value = (SELECT StrValue FROM [dbo].[Setting] WITH( READCOMMITTED ) WHERE SettingID = @SettingID)
    RETURN @Value;
END