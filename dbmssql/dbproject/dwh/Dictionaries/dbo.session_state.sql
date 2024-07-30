IF NOT EXISTS(SELECT 1 FROM [data_source] WHERe [data_source_id] =1 )
INSERT INTO [data_source] (data_source_id,name) values(1, N'ods1c')


DECLARE @session_state TABLE
(
    [session_state_id] TINYINT,
    [name] NVARCHAR(100)
)

INSERT @session_state ([session_state_id], [name])VALUES
(1, N'Начало обработки Etl'),
(2, N'Завершение обработки Etl'),
(3, N'Ошибка обработки Etl')

IF EXISTS ( 
    SELECT 1 FROM [dbo].[session_state] d 
    LEFT OUTER JOIN @session_state s ON s.session_state_id=d.session_state_id
    WHERE s.session_state_id IS NULL) THROW 60000, N'The table [session_state] was change.', 1;

MERGE INTO [dbo].[session_state] trg
USING 
@session_state src ON src.[session_state_id] = trg.[session_state_id]
WHEN MATCHED THEN UPDATE SET 
    [name] = src.[name]
WHEN NOT MATCHED BY TARGET THEN 
    INSERT ([session_state_id] , [name]) VALUES (src.[session_state_id] , src.[name])
WHEN NOT MATCHED BY SOURCE THEN DELETE;

IF NOT EXISTS(SELECT 1 FROM [dbo].[Setting] WHERE SettingID = 'AuditProcAll' )
    INSERT INTO [dbo].[Setting] (SettingID, StrValue) VALUES('AuditProcAll', N'AuditProcAll')

EXEC [dbo].[sp_FillDimDate] @FromDate = '20240101', @ToDate = '20300101'
