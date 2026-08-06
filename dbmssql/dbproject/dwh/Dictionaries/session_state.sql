IF NOT EXISTS(SELECT 1 FROM [mq].[DataSource] WHERE [DataSourceId] = 1)
  INSERT [mq].[DataSource] ([DataSourceId], [Name]) VALUES (1, N'dwh1')

DECLARE @session_state AS TABLE
(
  [SessionStateId] TINYINT,
  [Name]           NVARCHAR(100)
)

INSERT @session_state ([SessionStateId], [Name]) VALUES
(1, N'Начало обработки очереди RabbitMQ'),
(2, N'Завершение обработки очереди RabbitMQ'),
(3, N'Ошибка в процедуре'),
(4, N'Ошибка в сервисе'),
(5, N'Ручной запуск процедур загрузки из буфера'),
(6, N'Удаление из архива')

IF EXISTS (
  SELECT 1 FROM [mq].[SessionState] d
  LEFT OUTER JOIN @session_state s ON s.[SessionStateId] = d.[SessionStateId]
  WHERE s.[SessionStateId] IS NULL) THROW 60000, N'The table [mq].[SessionState] was change.', 1;

MERGE INTO [mq].[SessionState] trg
USING @session_state src ON src.[SessionStateId] = trg.[SessionStateId]
WHEN MATCHED THEN UPDATE SET [Name] = src.[Name]
WHEN NOT MATCHED BY TARGET THEN
  INSERT ([SessionStateId], [Name]) VALUES (src.[SessionStateId], src.[Name])
WHEN NOT MATCHED BY SOURCE THEN DELETE;

IF NOT EXISTS(SELECT 1 FROM [config].[Setting] WHERE SettingId = 'AuditProcAll')
  INSERT INTO [config].[Setting] (SettingId, StrValue) VALUES ('AuditProcAll', N'AuditProcAll')

IF EXISTS (SELECT 1 FROM sys.servers WHERE name = N'LinkSRVLanding')
  EXEC sp_dropserver N'LinkSRVLanding', 'droplogins';

IF NOT EXISTS (SELECT 1 FROM sys.servers WHERE name = N'LinkSRVLanding')
  EXEC sp_addlinkedserver
    @server = N'LinkSRVLanding',
    @srvproduct = N'',
    @provider = N'SQLNCLI',
    @datasrc = @@SERVERNAME,
    @catalog = N'$(landing)';

EXEC sp_serveroption N'LinkSRVLanding', N'RPC OUT', N'true';
EXEC sp_serveroption N'LinkSRVLanding', N'remote proc transaction promotion', N'false';

IF EXISTS (SELECT 1 FROM sys.servers WHERE name = N'LinkSRVOds')
  EXEC sp_dropserver N'LinkSRVOds', 'droplogins';

IF NOT EXISTS (SELECT 1 FROM sys.servers WHERE name = N'LinkSRVOds')
  EXEC sp_addlinkedserver
    @server = N'LinkSRVOds',
    @srvproduct = N'',
    @provider = N'SQLNCLI',
    @datasrc = @@SERVERNAME,
    @catalog = N'$(ods)';

EXEC sp_serveroption N'LinkSRVOds', N'RPC OUT', N'true';
EXEC sp_serveroption N'LinkSRVOds', N'remote proc transaction promotion', N'false';

IF EXISTS (SELECT 1 FROM sys.servers WHERE name = N'LinkSRVLogLanding')
  EXEC sp_dropserver N'LinkSRVLogLanding', 'droplogins';

IF NOT EXISTS (SELECT 1 FROM sys.servers WHERE name = N'LinkSRVLogLanding')
  EXEC sp_addlinkedserver
    @server = N'LinkSRVLogLanding',
    @srvproduct = N'',
    @provider = N'SQLNCLI',
    @datasrc = @@SERVERNAME,
    @catalog = N'$(dwh)';

EXEC sp_serveroption N'LinkSRVLogLanding', N'RPC OUT', N'true';
EXEC sp_serveroption N'LinkSRVLogLanding', N'remote proc transaction promotion', N'false';

IF EXISTS (SELECT 1 FROM sys.servers WHERE name = N'LinkSRVLog')
  EXEC sp_dropserver N'LinkSRVLog', 'droplogins';

IF NOT EXISTS (SELECT 1 FROM sys.servers WHERE name = N'LinkSRVLog')
  EXEC sp_addlinkedserver
    @server = N'LinkSRVLog',
    @srvproduct = N'',
    @provider = N'SQLNCLI',
    @datasrc = @@SERVERNAME,
    @catalog = N'$(log)';

EXEC sp_serveroption N'LinkSRVLog', N'RPC OUT', N'true';
EXEC sp_serveroption N'LinkSRVLog', N'remote proc transaction promotion', N'false';

EXEC [target].[sp_FillDimDate] @FromDate = '20240101', @ToDate = '20300101';
