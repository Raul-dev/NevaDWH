CREATE PROCEDURE [odins].[load_FACT_Продажи]
    @session_id         bigint         = NULL,
    @BufferHistoryMode  tinyint        = 0,  -- 0 - Do not delete the buffering history.
                                             -- 1 - Delete the buffering history.
                                             -- 2 - Keep the buffering history for 10 days.
                                             -- 3 - Keep the buffering history for a month.
    @RowCount           int            = NULL OUTPUT,
    @ErrorMessage       varchar(4000)  = NULL OUTPUT
AS
BEGIN
SET CONCAT_NULL_YIELDS_NULL ON
SET NOCOUNT ON
DECLARE @LogID int, @ProcedureName varchar(510), @ProcedureParams varchar(max), @ProcedureInfo varchar(max), @AuditProcEnable nvarchar(256)
SET @AuditProcEnable = [dbo].[fn_GetSettingValue]('AuditProcAll')
IF @AuditProcEnable IS NOT NULL 
BEGIN
    IF OBJECT_ID('tempdb..#LogProc') IS NULL
        CREATE TABLE #LogProc(LogID int Primary Key NOT NULL)
    SET @ProcedureName = '[' + OBJECT_SCHEMA_NAME(@@PROCID)+'].['+OBJECT_NAME(@@PROCID)+']'
    SET @ProcedureParams =
        '@session_id=' + ISNULL(LTRIM(STR(@session_id)),'NULL') + ', ' +
        '@BufferHistoryMode=' + ISNULL(LTRIM(STR(@BufferHistoryMode)),'NULL')
END
SET XACT_ABORT OFF

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET DEADLOCK_PRIORITY LOW
DECLARE @MinDate datetime2(4) = DATEFROMPARTS(1900, 01, 01),
    @UpdateDate datetime2(4)  = GetDate(),
    @BufferHistoryDays int

SET @BufferHistoryDays = IIF(@BufferHistoryMode = 2, 10, 30)

DECLARE @LockedList AS TABLE(
    [buffer_id] bigint Primary key,
    [msg_id] uniqueidentifier,
    [RefID] uniqueidentifier,
    [msgtype_id] tinyint
)
DECLARE @LockedListUniq AS TABLE(
    [buffer_id] bigint Primary key,
    [RefID] uniqueidentifier
)

BEGIN TRY
BEGIN TRANSACTION

    IF @AuditProcEnable IS NOT NULL 
        EXEC [audit].[sp_log_Start] @AuditProcEnable = @AuditProcEnable, @ProcedureName = @ProcedureName, @ProcedureParams = @ProcedureParams, @LogID = @LogID OUTPUT
    INSERT INTO @LockedList
    SELECT buffer_id, msg_id, [RefID], msgtype_id
    FROM [odins].[FACT_Продажи_buffer] b 
    WHERE b.[dt_update] = @MinDate
    ORDER BY buffer_id
    SET @RowCount = @@ROWCOUNT;

    IF @RowCount = 0 
    BEGIN
    
        EXEC [audit].[sp_log_Finish] @LogID = @LogID, @RowCount = 0, @ProcedureInfo = 'Empty buffer'
        COMMIT TRANSACTION
        RETURN 0
    END

    IF EXISTS (SELECT 1 FROM @LockedList WHERE msgtype_id = 2)
    BEGIN

        WITH XMLNAMESPACES (DEFAULT 'http://v8.1c.ru/8.1/data/enterprise/current-config', 'http://www.w3.org/2001/XMLSchema-instance' as xsi)
        INSERT INTO filequeue ([session_id], [msg_key], [msg_id], [start_date], [finish_date], [filename], [filefolder], [filetype], [error_msg], [state_id], dt_create)
        SELECT
            @session_id AS session_id,
            b.msg.value('(/Data/ПолноеИмя/text())[1]', 'varchar(4000)') [msg_key],
            b.msg_id [msg_id],
            b.msg.value('(/Data/Реквизиты/НачалоФормирования/text())[1]', 'datetime2(4)')  AS [start_date],
            b.msg.value('(/Data/Реквизиты/КонецФормирования/text())[1]', 'datetime2(4)')  AS [finish_date],
            b.msg.value('(/Data/Реквизиты/ИмяФайла/text())[1]', 'varchar(4000)') AS filename,
            b.msg.value('(/Data/Реквизиты/ИмяПапки/text())[1]', 'varchar(4000)') AS filefolder,
            'xml' AS [filetype],
            NULL [error_msg],
            1 [state_id],
            b.[dt_create]
        FROM [odins].[FACT_Продажи_buffer] b
        INNER JOIN @LockedList l ON b.[buffer_id] = l.[buffer_id]
        WHERE l.[msgtype_id] = 2 AND NOT EXISTS(SELECT 1 FROM dbo.filequeue f WHERE f.[msg_key] = 'DocumentObject.Продажи' AND f.[msg_id] = l.[msg_id] AND f.[dt_create] = b.[dt_create]);

        DECLARE @FileQueueID bigint, @res int
        SELECT @FileQueueID = MIN(filequeue_id) FROM dbo.filequeue f WHERE f.msg_key = 'DocumentObject.Продажи' AND state_id in (1,3)
        COMMIT TRANSACTION
        EXEC @res = [odins].[load_FACT_Продажи_file] @FileQueueID = @FileQueueID, @ErrorMessage = @ErrorMessage OUTPUT
        IF @res <> 0 BEGIN
            EXEC [audit].[sp_log_Finish] @LogID = @LogID, @RowCount = 0, @ProcedureInfo = 'load_file @res<>0'
            RETURN
        END
        BEGIN TRANSACTION
    END

    INSERT INTO @LockedListUniq
    SELECT buffer_id = MAX(buffer_id), [RefID]
    FROM @LockedList l
    WHERE l.msgtype_id = 1 
    GROUP BY [RefID]
    SET @RowCount = @@ROWCOUNT;

    SELECT DISTINCT tmp = 1 INTO #tmpFACT_Продажи
    FROM [odins].[FACT_Продажи] b WITH(ROWLOCK,XLOCK)
    INNER JOIN @LockedListUniq ll ON b.[RefID] = ll.[RefID];

    TRUNCATE TABLE staging.FACT_Продажи;
    SET @UpdateDate = GetDate();
    WITH XMLNAMESPACES (DEFAULT 'http://v8.1c.ru/8.1/data/enterprise/current-config', 'http://www.w3.org/2001/XMLSchema-instance' as xsi)
    INSERT staging.FACT_Продажи(nkey,  [FACT_Продажи.Товары], [RefID], [DeletionMark], [Number], [Posted], [Date], [DateID], [ДатаОтгрузки], [ДатаОтгрузкиID], [Клиент], [ТипДоставки], [ПримерСоставногоТипа], [ПримерСоставногоТипа_ТипЗначения], dt_update)
    SELECT
        [nkey] = X.C.value('(Ref/text())[1]', 'uniqueidentifier'),
        [FACT_Продажи.Товары] = X.C.query('declare default element namespace "http://v8.1c.ru/8.1/data/enterprise/current-config";Товары'),
        [RefID] = X.C.value('(Ref/text())[1]', 'uniqueidentifier'),
        [DeletionMark] = X.C.value('(DeletionMark/text())[1]', 'bit'),
        [Number] = X.C.value('(Number/text())[1]', 'int'),
        [Posted] = X.C.value('(Posted/text())[1]', 'bit'),
        [Date] = X.C.value('(Date/text())[1]', 'datetime2(0)'),
        [DateID] = CAST(CONVERT(varchar(25), X.C.value('(Date/text())[1]', 'datetime2(0)'), 112) as int),
        [ДатаОтгрузки] = X.C.value('(ДатаОтгрузки/text())[1]', 'datetime2(0)'),
        [ДатаОтгрузкиID] = CAST(CONVERT(varchar(25), X.C.value('(ДатаОтгрузки/text())[1]', 'datetime2(0)'), 112) as int),
        [Клиент] = X.C.value('(Клиент/text())[1]', 'varchar(36)'),
        [ТипДоставки] = X.C.value('(ТипДоставки/text())[1]', 'varchar(500)'),
        [ПримерСоставногоТипа] = X.C.value('(ПримерСоставногоТипа/text())[1]', 'varchar(36)'),
        [ПримерСоставногоТипа_ТипЗначения] = X.C.value('(ПримерСоставногоТипа/@xsi:type)[1]', 'varchar(128)'),
        [dt_update] = @UpdateDate
    FROM [odins].[FACT_Продажи_buffer] AS b
    INNER JOIN @LockedListUniq l ON l.buffer_id = b.buffer_id
    CROSS APPLY b.msg.nodes('/Data/Реквизиты/DocumentObject.Продажи') AS X(C);

    EXEC [odins].[load_FACT_Продажи_staging]

    -- Clear buffer table
    IF @BufferHistoryMode = 1 AND NOT EXISTS (SELECT 1 FROM [odins].[FACT_Продажи_buffer] WHERE [is_error] = 1)
    BEGIN
        DELETE b
        FROM [odins].[FACT_Продажи_buffer] b
        INNER JOIN @LockedList t ON b.buffer_id = t.buffer_id
    END
    ELSE
    BEGIN
        UPDATE b SET
            dt_update = @UpdateDate
        FROM [odins].[FACT_Продажи_buffer] AS b
        INNER JOIN @LockedList l ON l.buffer_id = b.buffer_id

        IF @BufferHistoryMode >= 2 AND NOT EXISTS (SELECT 1 FROM [odins].[FACT_Продажи_buffer] WHERE [is_error] = 1)
            DELETE b
            FROM [odins].[FACT_Продажи_buffer] b
            WHERE DATEDIFF(DD, @UpdateDate, dt_update) > @BufferHistoryDays
    END
    EXEC [audit].[sp_log_Finish] @LogID = @LogID, @RowCount = @RowCount

COMMIT TRANSACTION
END TRY
BEGIN CATCH
    SET @ErrorMessage = ERROR_MESSAGE()
    IF XACT_STATE() <> 0 AND @@TRANCOUNT > 0 
        ROLLBACK TRANSACTION

    DECLARE @err_session_id bigint;
    SET @err_session_id = ISNULL(@session_id, 0)
    INSERT [dbo].[session_log] (session_id, [session_state_id], [error_message])
    SELECT
        [session_id] = @err_session_id,
        [session_state_id] = 3,
        [error_message] = 'Table [odins].[FACT_Продажи_buffer]. Error: ' +@ErrorMessage

    IF NOT @ErrorMessage LIKE '%deadlock%'
        UPDATE b SET 
            [session_id] = @err_session_id,
            [is_error]   = 1,
            [dt_update]  = ISNULL(@UpdateDate, GetDate())
        FROM [odins].[FACT_Продажи_buffer] b
        INNER JOIN @LockedList l ON b.[buffer_id] = l.[buffer_id]
        WHERE [is_error] = 0

    EXEC [audit].[sp_log_Finish] @LogID = @LogID, @RowCount = @RowCount, @ErrorMessage = @ErrorMessage
    EXEC [audit].[sp_Print] @StrPrint = @ErrorMessage
    RETURN -1
END CATCH

END

GO
