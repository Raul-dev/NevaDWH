IF NOT EXISTS(SELECT 1 FROM data_source WHERE data_source_id =1 )
    INSERT [data_source] ([data_source_id], [name]) VALUES(1, N'ods1c')
IF NOT EXISTS(SELECT 1 FROM msgtype WHERE msgtype_id =1 )
BEGIN
    INSERT [msgtype] ([msgtype_id], [name]) VALUES(1, N'Message Data')
    INSERT [msgtype] ([msgtype_id], [name]) VALUES(2, N'File Data')
END


DECLARE @session_state AS TABLE
(
    [session_state_id] TINYINT,
    [name] NVARCHAR(100)
)

INSERT @session_state ([session_state_id], [name]) VALUES
(1, N'Начало обработки очереди RabbitMQ'),
(2, N'Завершение обработки очереди RabbitMQ'),
(3, N'Ошибка в процедуре'),
(4, N'Ошибка в сервисе'),
(5, N'Ручной запуск процедур загрузки из буфера'),
(6, N'Удаление из архива')

IF EXISTS ( 
    SELECT 1 FROM [dbo].[session_state] d 
    LEFT OUTER JOIN @session_state s ON s.[session_state_id] = d.[session_state_id]
    WHERE s.[session_state_id] IS NULL) THROW 60000, N'The table [session_state] was change. ', 1;

MERGE INTO [dbo].[session_state] trg
USING 
@session_state src ON src.[session_state_id] = trg.[session_state_id]
WHEN MATCHED THEN UPDATE SET 
    [name] = src.[name]
WHEN NOT MATCHED BY TARGET THEN 
    INSERT ([session_state_id] , [name]) VALUES (src.[session_state_id] , src.[name])
WHEN NOT MATCHED BY SOURCE THEN DELETE;

if NOT EXISTS(SELECT 1 FROM [session] WHERe data_source_id =1 )
BEGIN
    SET IDENTITY_INSERT [session] ON
    INSERT INTO [session]  ([session_id], [data_source_id], [session_state_id], [error_message])
    SELECT 0,1,5,NULL
    SET IDENTITY_INSERT [session] OFF
END

IF NOT EXISTS(SELECT 1 FROM [dbo].[Setting] WHERE SettingID = 'AuditProcAll' )
INSERT INTO [dbo].[Setting] (SettingID, StrValue) values('AuditProcAll', N'AuditProcAll')

IF EXISTS (SELECT * FROM sys.servers WHERE NAME = N'LinkSRVOds' )    
    EXECUTE sp_dropserver @server = 'LinkSRVOds'

IF NOT EXISTS (SELECT * FROM sys.servers WHERE NAME = N'LinkSRVOds' )
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

EXEC [dbo].[sp_FillDimDate] @FromDate = '20240101', @ToDate = '20300101'