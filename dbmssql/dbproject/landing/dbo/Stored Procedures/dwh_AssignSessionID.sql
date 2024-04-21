CREATE PROCEDURE dwh_AssignSessionID
	@dwh_session_id bigint = NULL OUTPUT, -- @dwh_session_id = -1 create new package
    @RowCount INT = NULL OUTPUT,
    @ErrMessage VARCHAR(MAX) = NULL OUTPUT
AS
BEGIN
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
               SELECT s.dwh_session_id, sum(row_count) as row_count, @ErrMessage AS ErrMessage,         MAX(s.create_session) AS create_session
        FROM dwh_session s
            INNER JOIN [dbo].[dwh_processing_details] p ON p.dwh_session_id = s.dwh_session_id
        WHERE dwh_session_state_id = 2 AND s.dwh_session_id = @dwh_session_id
        GROUP BY s.dwh_session_id
        RETURN 0;
    END
    IF @dwh_session_id IS NULL OR @dwh_session_id = -1
    BEGIN
        SELECT @dwh_session_id = min(dwh_session_id) FROM dwh_session WHERE ISNULL(@dwh_session_id, 0) != -1 AND dwh_session_state_id = 2
        IF NOT @dwh_session_id IS NULL
        BEGIN
            SELECT dwh_session_id, sum(row_count) as row_count, @ErrMessage AS ErrMessage, (SELECT create_session FROM dwh_session WHERE dwh_session_id = @dwh_session_id) as create_session FROM [dbo].[dwh_processing_details] WHERE dwh_session_id = @dwh_session_id
            GROUP BY dwh_session_id
            RETURN;
        END
        INSERT @T EXEC [dbo].[dwh_SaveSessionState]
        SELECT @dwh_session_id = dwh_session_id FROM @T t
    END

    DECLARE @LocalRowCount INT
BEGIN TRANSACTION
/*
    CREATE TABLE #F_Продажи(
        ods_id bigint Primary Key,
        [RefID] uniqueidentifier
    )
    INSERT INTO #F_Продажи (
        ods_id, [RefID]
    )
    SELECT ods_id, [RefID] FROM [uts].[F_Продажи] WITH(XLOCK)
    SET @LocalRowCount = @@ROWCOUNT
    SELECT @RowCount = @RowCount + @LocalRowCount
    IF @LocalRowCount > 0
        INSERT [dbo].[dwh_processing_details]( dwh_session_id, [schema_name], [table_name], [row_count])
        SELECT @dwh_session_id, 'uts', 'F_Продажи',@LocalRowCount

    INSERT INTO [uts].[F_Продажи_history](
        nkey,
        dwh_session_id,
        [RefID],
        [DeletionMark],
        [Number],
        [Posted],
        [Date],
        [ДатаОтгрузки],
        [Клиент],
        [ТипДоставки],
        [dt_create]
    )
    SELECT
        b.nkey,
        @dwh_session_id AS dwh_session_id,
        b.[RefID],
        b.[DeletionMark],
        b.[Number],
        b.[Posted],
        b.[Date],
        b.[ДатаОтгрузки],
        b.[Клиент],
        b.[ТипДоставки],
        b.[dt_create]
    FROM [uts].[F_Продажи] b
        INNER JOIN #F_Продажи ll ON b.ods_id = ll.ods_id

    INSERT INTO [uts].[F_Продажи.Товары_history](
        nkey,
        dwh_session_id,
        [ПродажиRefID],
        [Доставка],
        [Товар],
        [Колличество],
        [Цена],
        [dt_create]
    )
    SELECT
        b.nkey,
        @dwh_session_id AS dwh_session_id,
        b.[ПродажиRefID],
        b.[Доставка],
        b.[Товар],
        b.[Колличество],
        b.[Цена],
        GetDate() AS [dt_create]
    FROM [uts].[F_Продажи.Товары] b
        INNER JOIN #F_Продажи ll ON b.[F_Продажи_RefID] = ll.[RefID]
*/
    SET @LocalRowCount = @@ROWCOUNT
    SELECT @RowCount = @RowCount + @LocalRowCount
    IF @LocalRowCount > 0
        INSERT [dbo].[dwh_processing_details]( dwh_session_id, [schema_name], [table_name], [row_count])
        SELECT @dwh_session_id, 'uts', 'F_Продажи.Товары', @LocalRowCount


COMMIT TRANSACTION


    -- Deleted and create session
    IF @RowCount > 0
    BEGIN
    BEGIN TRANSACTION
    /*
        -- Delete star: uts.F_Продажи
        DELETE b FROM [uts].[F_Продажи] b
            INNER JOIN #F_Продажи ll ON b.[ods_id] = ll.[ods_id]
            -- Delete child: uts.F_Продажи.Товары
            DELETE b FROM [uts].[F_Продажи.Товары] b
                INNER JOIN #F_Продажи ll ON b.[ПродажиRefID] = ll.[RefID]
      */  
        EXEC [dbo].[dwh_SaveSessionState] @dwh_session_id = @dwh_session_id, @dwh_session_state_id = 2
    COMMIT TRANSACTION
    END

    SELECT @dwh_session_id AS dwh_session_id, @RowCount AS row_count, @ErrMessage AS ErrMessage, (SELECT create_session FROM dwh_session WHERE dwh_session_id = @dwh_session_id) as create_session

RETURN 0
END TRY
BEGIN CATCH
	SELECT @ErrMessage = ERROR_MESSAGE()
	IF XACT_STATE() <> 0 AND @@TRANCOUNT > 0 
	BEGIN
		 ROLLBACK TRANSACTION
	END

    UPDATE dwh_session SET [dwh_session_state_id] = 3
    WHERE dwh_session_id = @dwh_session_id
	INSERT [dwh_session_log] ( dwh_session_id, [dwh_session_state_id], [error_message])
	SELECT dwh_session_id = @dwh_session_id,
		[dwh_session_state_id] = 3,
		[dwh_error_message] = 'AssignSessionID Error: ' +@ErrMessage

	--RAISERROR( N'Error: [%s].', 16, 1, @ErrMessage)
    SELECT @dwh_session_id, -1 as row_count, @ErrMessage AS ErrMessage
	RETURN -1
END CATCH

END

GO
