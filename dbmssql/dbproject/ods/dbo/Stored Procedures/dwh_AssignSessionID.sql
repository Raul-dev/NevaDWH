CREATE PROCEDURE dwh_AssignSessionID
    @dwh_session_id bigint = NULL OUTPUT, -- @dwh_session_id = -1 create new package
    @RowCount       int = NULL OUTPUT,
    @ErrorMessage   varchar(MAX) = NULL OUTPUT
AS
BEGIN
DECLARE @LogID int, @ProcedureName varchar(510), @ProcedureParams varchar(max), @ProcedureInfo varchar(max), @AuditProcEnable nvarchar(256)
SET @AuditProcEnable = [dbo].[fn_GetSettingValue]('AuditProcAll')
IF @AuditProcEnable IS NOT NULL 
BEGIN
    IF OBJECT_ID('tempdb..#LogProc') IS NULL
        CREATE TABLE #LogProc(LogID int Primary Key NOT NULL)
    SET @ProcedureName = '[' + OBJECT_SCHEMA_NAME(@@PROCID)+'].['+OBJECT_NAME(@@PROCID)+']'
    SET @ProcedureParams =
         '@dwh_session_id=' + ISNULL(LTRIM(STR(@dwh_session_id)),'NULL')

    EXEC [audit].[sp_log_Start] @AuditProcEnable = @AuditProcEnable, @ProcedureName = @ProcedureName, @ProcedureParams = @ProcedureParams, @LogID = @LogID OUTPUT
END
SET XACT_ABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET NOCOUNT ON

SET TRANSACTION ISOLATION LEVEL READ COMMITTED
SET DEADLOCK_PRIORITY HIGH
BEGIN TRY

    SET @RowCount = 0
    DECLARE @T AS TABLE (dwh_session_id bigint)

    IF NOT @dwh_session_id IS NULL AND @dwh_session_id != -1
    BEGIN

        SELECT s.dwh_session_id, sum(row_count) as row_count, @ErrorMessage AS ErrMessage,         MAX(s.create_session) AS create_session
        FROM dwh_session s
            INNER JOIN [dbo].[dwh_processing_details] p ON p.dwh_session_id = s.dwh_session_id
        WHERE dwh_session_state_id = 2 AND s.dwh_session_id = @dwh_session_id
        GROUP BY s.dwh_session_id
        EXEC [audit].[sp_log_Finish] @LogID = @LogID, @RowCount = 1, @ProcedureInfo = 'RETURN Line 39'
        RETURN 0;
    END
    IF @dwh_session_id IS NULL OR @dwh_session_id = -1
    BEGIN
        SELECT @dwh_session_id = min(dwh_session_id) FROM dwh_session WHERE ISNULL(@dwh_session_id, 0) != -1 AND dwh_session_state_id = 2
        IF NOT @dwh_session_id IS NULL
        BEGIN
            SELECT dwh_session_id, sum(row_count) as row_count, @ErrorMessage AS ErrMessage, (SELECT create_session FROM dwh_session WHERE dwh_session_id = @dwh_session_id) as create_session FROM [dbo].[dwh_processing_details] WHERE dwh_session_id = @dwh_session_id
            GROUP BY dwh_session_id
            EXEC [audit].[sp_log_Finish] @LogID = @LogID, @RowCount = 1, @ProcedureInfo = 'RETURN Line 49'
            RETURN 0;
        END
        INSERT @T EXEC [dbo].[dwh_SaveSessionState]
        SELECT @dwh_session_id = dwh_session_id FROM @T t
        SET @ProcedureInfo = 'Create @dwh_session_id='+LTRIM(STR(@dwh_session_id))
        EXEC [audit].[sp_log_Info] @LogID = @LogID, @ProcedureInfo = @ProcedureInfo
    END

    DECLARE @LocalRowCount int
BEGIN TRANSACTION
    CREATE TABLE #DIM_Валюты(
        [ods_id] bigint Primary Key,
        [RefID] uniqueidentifier
    )
    INSERT INTO #DIM_Валюты (
        [ods_id],
        [RefID]
    )
    SELECT [ods_id], [RefID] FROM [odins].[DIM_Валюты] WITH(XLOCK)
    SET @LocalRowCount = @@ROWCOUNT
    SELECT @RowCount = @RowCount + @LocalRowCount
    IF @LocalRowCount > 0
        INSERT [dbo].[dwh_processing_details]([dwh_session_id], [schema_name], [table_name], [row_count])
        SELECT @dwh_session_id, 'odins', 'DIM_Валюты',@LocalRowCount

    INSERT INTO [odins].[DIM_Валюты_history](
        [nkey],
        [dwh_session_id],
        [RefID],
        [DeletionMark],
        [Code],
        [Description],
        [ЗагружаетсяИзИнтернета],
        [НаименованиеПолное],
        [Наценка],
        [ОсновнаяВалюта],
        [ПараметрыПрописи],
        [ФормулаРасчетаКурса],
        [СпособУстановкиКурса],
        [dt_create]
    )
    SELECT
        b.[nkey],
        @dwh_session_id AS dwh_session_id,
        b.[RefID],
        b.[DeletionMark],
        b.[Code],
        b.[Description],
        b.[ЗагружаетсяИзИнтернета],
        b.[НаименованиеПолное],
        b.[Наценка],
        b.[ОсновнаяВалюта],
        b.[ПараметрыПрописи],
        b.[ФормулаРасчетаКурса],
        b.[СпособУстановкиКурса],
        GetDate() AS [dt_create]
    FROM [odins].[DIM_Валюты] b
        INNER JOIN #DIM_Валюты ll ON b.ods_id = ll.ods_id

    INSERT INTO [odins].[DIM_Валюты.Представления_history](
        [nkey],
        [dwh_session_id],
        [DIM_ВалютыRefID],
        [КодЯзыка],
        [ПараметрыПрописи],
        [dt_create]
    )
    SELECT
        b.[nkey],
        @dwh_session_id AS dwh_session_id,
        b.[DIM_ВалютыRefID],
        b.[КодЯзыка],
        b.[ПараметрыПрописи],
        GetDate() AS [dt_create]
    FROM [odins].[DIM_Валюты.Представления] b
        INNER JOIN #DIM_Валюты ll ON b.[DIM_ВалютыRefID] = ll.[RefID]
    SET @LocalRowCount = @@ROWCOUNT
    SELECT @RowCount = @RowCount + @LocalRowCount
    IF @LocalRowCount > 0
        INSERT [dbo].[dwh_processing_details]([dwh_session_id], [schema_name], [table_name], [row_count])
        SELECT @dwh_session_id, 'odins', 'DIM_Валюты.Представления', @LocalRowCount


COMMIT TRANSACTION
BEGIN TRANSACTION
    CREATE TABLE #DIM_Клиенты(
        [ods_id] bigint Primary Key,
        [RefID] uniqueidentifier
    )
    INSERT INTO #DIM_Клиенты (
        [ods_id],
        [RefID]
    )
    SELECT [ods_id], [RefID] FROM [odins].[DIM_Клиенты] WITH(XLOCK)
    SET @LocalRowCount = @@ROWCOUNT
    SELECT @RowCount = @RowCount + @LocalRowCount
    IF @LocalRowCount > 0
        INSERT [dbo].[dwh_processing_details]([dwh_session_id], [schema_name], [table_name], [row_count])
        SELECT @dwh_session_id, 'odins', 'DIM_Клиенты',@LocalRowCount

    INSERT INTO [odins].[DIM_Клиенты_history](
        [nkey],
        [dwh_session_id],
        [RefID],
        [DeletionMark],
        [Code],
        [Description],
        [Контакт],
        [dt_create]
    )
    SELECT
        b.[nkey],
        @dwh_session_id AS dwh_session_id,
        b.[RefID],
        b.[DeletionMark],
        b.[Code],
        b.[Description],
        b.[Контакт],
        GetDate() AS [dt_create]
    FROM [odins].[DIM_Клиенты] b
        INNER JOIN #DIM_Клиенты ll ON b.ods_id = ll.ods_id


COMMIT TRANSACTION
BEGIN TRANSACTION
    CREATE TABLE #DIM_Товары(
        [ods_id] bigint Primary Key,
        [RefID] uniqueidentifier
    )
    INSERT INTO #DIM_Товары (
        [ods_id],
        [RefID]
    )
    SELECT [ods_id], [RefID] FROM [odins].[DIM_Товары] WITH(XLOCK)
    SET @LocalRowCount = @@ROWCOUNT
    SELECT @RowCount = @RowCount + @LocalRowCount
    IF @LocalRowCount > 0
        INSERT [dbo].[dwh_processing_details]([dwh_session_id], [schema_name], [table_name], [row_count])
        SELECT @dwh_session_id, 'odins', 'DIM_Товары',@LocalRowCount

    INSERT INTO [odins].[DIM_Товары_history](
        [nkey],
        [dwh_session_id],
        [RefID],
        [DeletionMark],
        [Code],
        [Description],
        [Описание],
        [dt_create]
    )
    SELECT
        b.[nkey],
        @dwh_session_id AS dwh_session_id,
        b.[RefID],
        b.[DeletionMark],
        b.[Code],
        b.[Description],
        b.[Описание],
        GetDate() AS [dt_create]
    FROM [odins].[DIM_Товары] b
        INNER JOIN #DIM_Товары ll ON b.ods_id = ll.ods_id


COMMIT TRANSACTION
BEGIN TRANSACTION
    CREATE TABLE #FACT_Продажи(
        [ods_id] bigint Primary Key,
        [RefID] uniqueidentifier
    )
    INSERT INTO #FACT_Продажи (
        [ods_id],
        [RefID]
    )
    SELECT [ods_id], [RefID] FROM [odins].[FACT_Продажи] WITH(XLOCK)
    SET @LocalRowCount = @@ROWCOUNT
    SELECT @RowCount = @RowCount + @LocalRowCount
    IF @LocalRowCount > 0
        INSERT [dbo].[dwh_processing_details]([dwh_session_id], [schema_name], [table_name], [row_count])
        SELECT @dwh_session_id, 'odins', 'FACT_Продажи',@LocalRowCount

    INSERT INTO [odins].[FACT_Продажи_history](
        [nkey],
        [dwh_session_id],
        [RefID],
        [DeletionMark],
        [Number],
        [Posted],
        [Date],
        [ДатаОтгрузки],
        [Клиент],
        [ТипДоставки],
        [ПримерСоставногоТипа],
        [ПримерСоставногоТипа_ТипЗначения],
        [dt_create]
    )
    SELECT
        b.[nkey],
        @dwh_session_id AS dwh_session_id,
        b.[RefID],
        b.[DeletionMark],
        b.[Number],
        b.[Posted],
        b.[Date],
        b.[ДатаОтгрузки],
        b.[Клиент],
        b.[ТипДоставки],
        b.[ПримерСоставногоТипа],
        b.[ПримерСоставногоТипа_ТипЗначения],
        GetDate() AS [dt_create]
    FROM [odins].[FACT_Продажи] b
        INNER JOIN #FACT_Продажи ll ON b.ods_id = ll.ods_id

    INSERT INTO [odins].[FACT_Продажи.Товары_history](
        [nkey],
        [dwh_session_id],
        [FACT_ПродажиRefID],
        [Доставка],
        [Товар],
        [Колличество],
        [Цена],
        [dt_create]
    )
    SELECT
        b.[nkey],
        @dwh_session_id AS dwh_session_id,
        b.[FACT_ПродажиRefID],
        b.[Доставка],
        b.[Товар],
        b.[Колличество],
        b.[Цена],
        GetDate() AS [dt_create]
    FROM [odins].[FACT_Продажи.Товары] b
        INNER JOIN #FACT_Продажи ll ON b.[FACT_ПродажиRefID] = ll.[RefID]
    SET @LocalRowCount = @@ROWCOUNT
    SELECT @RowCount = @RowCount + @LocalRowCount
    IF @LocalRowCount > 0
        INSERT [dbo].[dwh_processing_details]([dwh_session_id], [schema_name], [table_name], [row_count])
        SELECT @dwh_session_id, 'odins', 'FACT_Продажи.Товары', @LocalRowCount


COMMIT TRANSACTION

    -- Deleted and create session
    IF @RowCount > 0
    BEGIN
    BEGIN TRANSACTION
        -- Delete star: odins.DIM_Валюты
        DELETE b FROM [odins].[DIM_Валюты] b
            INNER JOIN #DIM_Валюты ll ON b.[ods_id] = ll.[ods_id]
            -- Delete child: odins.DIM_Валюты.Представления
            DELETE b FROM [odins].[DIM_Валюты.Представления] b
                INNER JOIN #DIM_Валюты ll ON b.[DIM_ВалютыRefID] = ll.[RefID]
        -- Delete star: odins.DIM_Клиенты
        DELETE b FROM [odins].[DIM_Клиенты] b
            INNER JOIN #DIM_Клиенты ll ON b.[ods_id] = ll.[ods_id]
        -- Delete star: odins.DIM_Товары
        DELETE b FROM [odins].[DIM_Товары] b
            INNER JOIN #DIM_Товары ll ON b.[ods_id] = ll.[ods_id]
        -- Delete star: odins.FACT_Продажи
        DELETE b FROM [odins].[FACT_Продажи] b
            INNER JOIN #FACT_Продажи ll ON b.[ods_id] = ll.[ods_id]
            -- Delete child: odins.FACT_Продажи.Товары
            DELETE b FROM [odins].[FACT_Продажи.Товары] b
                INNER JOIN #FACT_Продажи ll ON b.[FACT_ПродажиRefID] = ll.[RefID]
        EXEC [dbo].[dwh_SaveSessionState] @dwh_session_id = @dwh_session_id, @dwh_session_state_id = 2
    COMMIT TRANSACTION
    END

    EXEC [audit].[sp_log_Finish] @LogID = @LogID, @RowCount = @LocalRowCount

    SELECT @dwh_session_id AS dwh_session_id, @RowCount AS row_count, @ErrorMessage AS ErrMessage, (SELECT create_session FROM dwh_session WHERE dwh_session_id = @dwh_session_id) as create_session

RETURN 0
END TRY
BEGIN CATCH
    SELECT @ErrorMessage = ERROR_MESSAGE()
    IF XACT_STATE() <> 0 AND @@TRANCOUNT > 0 
    BEGIN
        ROLLBACK TRANSACTION
    END

    UPDATE dwh_session SET [dwh_session_state_id] = 3
    WHERE [dwh_session_id] = @dwh_session_id
    INSERT [dwh_session_log] ([dwh_session_id], [dwh_session_state_id], [error_message])
    SELECT [dwh_session_id]    = @dwh_session_id,
        [dwh_session_state_id] = 3,
        [dwh_error_message]    = 'AssignSessionID Error: ' + @ErrorMessage
    SET @RowCount = @@ROWCOUNT
    EXEC [audit].[sp_log_Finish] @LogID = @LogID, @RowCount = @RowCount, @ErrorMessage = @ErrorMessage

    SELECT @dwh_session_id, -1 as row_count, @ErrorMessage AS ErrMessage
    RETURN -1
END CATCH

END

GO
