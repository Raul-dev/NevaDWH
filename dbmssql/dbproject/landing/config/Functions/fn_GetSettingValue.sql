CREATE FUNCTION [config].[fn_GetSettingValue](
  @SettingId varchar(50)
) RETURNS nvarchar(256)
AS
BEGIN
  RETURN (SELECT StrValue FROM [config].[Setting] WITH (NOLOCK) WHERE SettingId = @SettingId)
END
