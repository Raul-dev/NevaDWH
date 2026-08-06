CREATE FUNCTION [config].[fn_GetSettingInt](
  @SettingId varchar(50)
) RETURNS int
AS
BEGIN
  RETURN (SELECT CAST(LTRIM(StrValue) AS int) FROM [config].[Setting] WITH (NOLOCK) WHERE SettingId = @SettingId)
END
