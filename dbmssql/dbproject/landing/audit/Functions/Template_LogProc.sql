CREATE FUNCTION [audit].[Template_LogProc](
) RETURNS @LogProc TABLE (
  [ID]            bigint        identity(1,1) NOT NULL,
  [LogID]         bigint        NOT NULL Primary Key,
  [AuditTypeID]   int           NOT NULL,
  [Msg]           varchar(max)  COLLATE Cyrillic_General_CI_AS NULL
)
AS
BEGIN
  RETURN
END
