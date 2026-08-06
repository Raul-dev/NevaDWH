
CREATE FUNCTION [etl].[fn_GetSettingInt](
    @SettingId VARCHAR(50)
) RETURNS INT
AS
BEGIN
    RETURN (SELECT CAST(LTRIM(StrValue) AS INT) FROM [etl].[Setting] WITH (NOLOCK) WHERE SettingId = @SettingId)
END
