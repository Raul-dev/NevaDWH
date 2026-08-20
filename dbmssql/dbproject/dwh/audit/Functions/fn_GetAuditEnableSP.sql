CREATE FUNCTION [audit].[fn_GetAuditEnableSP](
  @SettingId nvarchar(256) = NULL
) RETURNS nvarchar(256)
AS
BEGIN
  RETURN NULLIF([config].[fn_GetSettingValue](ISNULL(@SettingId, N'AuditProcAll')), N'')
END
