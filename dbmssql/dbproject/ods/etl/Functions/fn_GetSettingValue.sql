
CREATE FUNCTION [etl].[fn_GetSettingValue](
    @SettingId VARCHAR(50)
) RETURNS NVARCHAR(256)
AS
BEGIN
    RETURN (SELECT StrValue FROM [etl].[Setting] WITH (NOLOCK) WHERE SettingId = @SettingId)
END
