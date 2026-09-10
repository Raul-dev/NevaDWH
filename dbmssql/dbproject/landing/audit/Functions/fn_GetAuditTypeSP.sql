CREATE FUNCTION [audit].[fn_GetAuditTypeSP](
  @AuditEnable nvarchar(256) = NULL
) RETURNS int
AS
BEGIN
  IF @AuditEnable = N'AuditProcAll'
    RETURN 1

  IF @AuditEnable IS NULL OR @AuditEnable IN (N'DisableLog', N'')
    RETURN NULL

  IF @AuditEnable = N'AuditProcAllLnk'
    RETURN 2

  RETURN ISNULL((
    SELECT [IntValue]
    FROM [audit].[Setting]
    WHERE [Code] = @AuditEnable
  ), 0)
END
