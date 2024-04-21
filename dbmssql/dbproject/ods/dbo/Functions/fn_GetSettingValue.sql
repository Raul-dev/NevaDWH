
/*
SELECT * FROM sys.sql_modules WHERE object_id  in (
SELECT object_id  FROM sys.objects WHERE name= 'fn_GetSettigValue'
)
DROP TABLE [dbo].[Setting]
CREATE TABLE [dbo].[Setting] (
SettingID	varchar(50) Primary Key,
StrValue nvarchar(256)
)

DROP FUNCTION [dbo].[fn_GetSettigValue]
SELECT [dbo].[fn_GetSettingValue]('dx')
*/
CREATE     Function [dbo].[fn_GetSettingValue](
	@SettingID	varchar(50)
) RETURNS nvarchar(256)
AS
BEGIN
	RETURN (SELECT StrValue FROM [dbo].[Setting] WITH( NOLOCK ) WHERE SettingID = @SettingID)
END