CREATE FUNCTION [audit].[fn_GetAuditEnableSP](
  @SettingId nvarchar(256) = NULL
) RETURNS nvarchar(256)
AS
BEGIN
   IF @SettingId IN (N'AuditProcAll', N'AuditProcEtl' )
     RETURN 1
   RETURN NULL
  --RETURN NULLIF([config].[fn_GetSettingValue](ISNULL(@SettingId, N'AuditProcAll')), N'')
END
