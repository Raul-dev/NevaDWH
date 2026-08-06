DECLARE @session_state AS TABLE
(
  [DwhSessionStateId] TINYINT,
  [Name]            NVARCHAR(100)
)

INSERT @session_state ([DwhSessionStateId], [Name])
VALUES
(1, N'Начало формирования пакета DWH'),
(2, N'Завершение формирования пакета DWH'),
(3, N'Ошибка формирования пакета DWH'),
(4, N'Завершение переноса данных в DWH')

IF EXISTS (
  SELECT 1 FROM [etl].[DwhSessionState] d
  LEFT OUTER JOIN @session_state s ON s.[DwhSessionStateId] = d.[DwhSessionStateId]
  WHERE s.[DwhSessionStateId] IS NULL) THROW 60000, N'The table [etl].[DwhSessionState] was change.', 1;

MERGE INTO [etl].[DwhSessionState] trg
USING @session_state src ON src.[DwhSessionStateId] = trg.[DwhSessionStateId]
WHEN MATCHED THEN UPDATE SET [Name] = src.[Name]
WHEN NOT MATCHED BY TARGET THEN
  INSERT ([DwhSessionStateId], [Name]) VALUES (src.[DwhSessionStateId], src.[Name])
WHEN NOT MATCHED BY SOURCE THEN DELETE;
