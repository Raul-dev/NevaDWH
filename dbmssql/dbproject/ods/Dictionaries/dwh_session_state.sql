
DECLARE @session_state AS TABLE
(
    [dwh_session_state_id] TINYINT,
    [name] NVARCHAR(100)
)

INSERT @session_state ([dwh_session_state_id], [name])
VALUES
(1, N'Начало формирования пакета DWH'),
(2, N'Завершение формирования пакета DWH'),
(3, N'Ошибка формирования пакета DWH'),
(4, N'Завершение переноса данных в DWH')


--SELECT * FROM [dbo].[dwh_session_state] d 
IF EXISTS ( 
    SELECT 1 FROM [dbo].[dwh_session_state] d 
    LEFT OUTER JOIN @session_state s ON s.dwh_session_state_id=d.dwh_session_state_id
    WHERE s.dwh_session_state_id IS NULL) THROW 60000, N'The table [dwh_session_state] was change.', 1;

MERGE INTO [dbo].[dwh_session_state] trg
USING 
@session_state src ON src.[dwh_session_state_id] = trg.[dwh_session_state_id]
WHEN MATCHED THEN UPDATE SET 
    [name] = src.[name]
WHEN NOT MATCHED BY TARGET THEN 
    INSERT ([dwh_session_state_id] , [name]) VALUES (src.[dwh_session_state_id] , src.[name])
WHEN NOT MATCHED BY SOURCE THEN DELETE;