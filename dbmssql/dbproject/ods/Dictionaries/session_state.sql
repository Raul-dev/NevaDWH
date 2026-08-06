IF NOT EXISTS(SELECT 1 FROM [mq].[DataSource] WHERE [DataSourceId] = 1)
  INSERT [mq].[DataSource] ([DataSourceId], [Name]) VALUES (1, N'ods1c')

IF NOT EXISTS(SELECT 1 FROM [mq].[MessageType] WHERE [MessageTypeId] = 1)
BEGIN
  INSERT [mq].[MessageType] ([MessageTypeId], [Name]) VALUES (1, N'Message Data')
  INSERT [mq].[MessageType] ([MessageTypeId], [Name]) VALUES (2, N'File Data')
END

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

IF NOT EXISTS(SELECT 1 FROM [mq].[Session] WHERE [DataSourceId] = 1)
BEGIN
  SET IDENTITY_INSERT [mq].[Session] ON
  INSERT INTO [mq].[Session] ([SessionId], [DataSourceId], [SessionStateId], [ErrorMessage])
  SELECT 0, 1, 5, NULL
  SET IDENTITY_INSERT [mq].[Session] OFF
END

IF NOT EXISTS(SELECT 1 FROM [config].[Setting] WHERE SettingId = 'AuditProcAll')
  INSERT INTO [config].[Setting] (SettingId, StrValue) VALUES ('AuditProcAll', N'AuditProcAll')

IF EXISTS (SELECT * FROM sys.servers WHERE NAME = N'LinkSRVOds')
  EXECUTE sp_dropserver @server = 'LinkSRVOds'

IF NOT EXISTS (SELECT * FROM sys.servers WHERE NAME = N'LinkSRVOds')
BEGIN
  DECLARE @database VARCHAR(200) = DB_NAME();

  EXECUTE sp_addlinkedserver @server = 'LinkSRVOds',
               @srvproduct = ' ',
               @provider = 'SQLNCLI',
               @datasrc = @@SERVERNAME,
               @catalog = @database
END

EXEC sp_serveroption LinkSRVOds, 'RPC OUT', 'TRUE'
EXEC sp_serveroption LinkSRVOds, 'remote proc transaction promotion', 'FALSE'

IF EXISTS (SELECT * FROM sys.servers WHERE NAME = N'LinkSRVLogLanding')
  EXECUTE sp_dropserver @server = 'LinkSRVLogLanding', @droplogins = 'droplogins'

IF NOT EXISTS (SELECT * FROM sys.servers WHERE NAME = N'LinkSRVLogLanding')
BEGIN
  EXECUTE sp_addlinkedserver @server = 'LinkSRVLogLanding',
               @srvproduct = ' ',
               @provider = 'SQLNCLI',
               @datasrc = @@SERVERNAME,
               @catalog = @database
END

EXEC sp_serveroption LinkSRVLogLanding, 'RPC OUT', 'TRUE'
EXEC sp_serveroption LinkSRVLogLanding, 'remote proc transaction promotion', 'FALSE'

IF EXISTS (SELECT * FROM sys.servers WHERE NAME = N'LinkSRVLog')
  EXECUTE sp_dropserver @server = 'LinkSRVLog', @droplogins = 'droplogins'

IF NOT EXISTS (SELECT * FROM sys.servers WHERE NAME = N'LinkSRVLog')
BEGIN
  EXECUTE sp_addlinkedserver @server = 'LinkSRVLog',
               @srvproduct = ' ',
               @provider = 'SQLNCLI',
               @datasrc = @@SERVERNAME,
               @catalog = N'$(log)'
END

EXEC sp_serveroption LinkSRVLog, 'RPC OUT', 'TRUE'
EXEC sp_serveroption LinkSRVLog, 'remote proc transaction promotion', 'FALSE'

EXEC [target].[sp_FillDimDate] @FromDate = '20240101', @ToDate = '20300101'
