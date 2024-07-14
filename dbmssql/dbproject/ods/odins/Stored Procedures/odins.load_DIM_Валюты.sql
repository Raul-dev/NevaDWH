CREATE PROCEDURE [odins].[load_DIM_Валюты]
    @session_id         bigint         = NULL,
    @BufferHistoryMode tinyint         = 0,  -- 0 - Do not delete the buffering history.
                                             -- 1 - Delete the buffering history.
                                             -- 2 - Keep the buffering history for 10 days.
                                             -- 3 - Keep the buffering history for a month.
    @RowCount           int            = NULL OUTPUT,
    @ErrMessage         nvarchar(4000) = NULL OUTPUT
AS
BEGIN
SET XACT_ABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET NOCOUNT ON

SET TRANSACTION ISOLATION LEVEL READ COMMITTED
SET DEADLOCK_PRIORITY LOW
DECLARE @MinDate datetime2(4) = DATEFROMPARTS(1900, 01, 01),
    @UpdateDate datetime2(4) = GetDate(),
    @BufferHistoryDays int

SET @BufferHistoryDays = IIF(@BufferHistoryMode = 2, 10, 30)

BEGIN TRY
BEGIN TRANSACTION

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
    DECLARE @LockedListTarget AS TABLE(
        [ods_id] bigint,
        [RefID] uniqueidentifier
    )

    INSERT INTO @LockedList
    SELECT buffer_id, msg_id, [RefID], msgtype_id
    FROM [odins].[DIM_Валюты_buffer] b WITH(XLOCK)
    WHERE b.[dt_update] = @MinDate
    SET @RowCount = @@ROWCOUNT;

    IF @RowCount = 0 
    BEGIN
    
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
        FROM [odins].[DIM_Валюты_buffer] b
            INNER JOIN @LockedList l ON b.[buffer_id] = l.[buffer_id]
        WHERE l.[msgtype_id] = 2 AND NOT EXISTS(SELECT 1 FROM dbo.filequeue f WHERE f.[msg_key] = 'CatalogObject.Валюты' AND f.[msg_id] = l.[msg_id] AND f.[dt_create] = b.[dt_create]);

        DECLARE @FileQueueID bigint, @res int
        SELECT @FileQueueID = MIN(filequeue_id) FROM dbo.filequeue f WHERE f.msg_key = 'CatalogObject.Валюты' AND state_id in (1,3)
        COMMIT TRANSACTION
        EXEC @res = [odins].[load_DIM_Валюты_file] @FileQueueID = @FileQueueID, @ErrMessage = @ErrMessage OUTPUT
        if @res <> 0
            RETURN
        BEGIN TRANSACTION
    END

    INSERT INTO @LockedListUniq
    SELECT buffer_id = MAX(buffer_id), [RefID]
    FROM @LockedList l
    WHERE l.msgtype_id = 1 
    GROUP BY [RefID]
    SET @RowCount = @@ROWCOUNT;

    INSERT INTO @LockedListTarget
    SELECT [ods_id], b.[RefID]
    FROM [odins].[DIM_Валюты] b WITH(XLOCK)
        INNER JOIN @LockedListUniq ll ON b.[RefID] = ll.[RefID];


    TRUNCATE TABLE staging.DIM_Валюты;
    SET @UpdateDate = GetDate();
    WITH XMLNAMESPACES (DEFAULT 'http://v8.1c.ru/8.1/data/enterprise/current-config', 'http://www.w3.org/2001/XMLSchema-instance' as xsi)
    INSERT staging.DIM_Валюты(nkey,  [DIM_Валюты.Представления], [RefID], [DeletionMark], [Code], [Description], [ЗагружаетсяИзИнтернета], [НаименованиеПолное], [Наценка], [ОсновнаяВалюта], [ПараметрыПрописи], [ФормулаРасчетаКурса], [СпособУстановкиКурса], dt_update)
    SELECT
        [nkey] = X.C.value('(Ref/text())[1]', 'uniqueidentifier'),
        [DIM_Валюты.Представления] = X.C.query('declare default element namespace "http://v8.1c.ru/8.1/data/enterprise/current-config";Представления'),
        [RefID] = X.C.value('(Ref/text())[1]', 'uniqueidentifier'),
        [DeletionMark] = X.C.value('(DeletionMark/text())[1]', 'bit'),
        [Code] = X.C.value('(Code/text())[1]', 'varchar(128)'),
        [Description] = X.C.value('(Description/text())[1]', 'varchar(128)'),
        [ЗагружаетсяИзИнтернета] = X.C.value('(ЗагружаетсяИзИнтернета/text())[1]', 'bit'),
        [НаименованиеПолное] = X.C.value('(НаименованиеПолное/text())[1]', 'varchar(50)'),
        [Наценка] = X.C.value('(Наценка/text())[1]', 'decimal(10,2)'),
        [ОсновнаяВалюта] = X.C.value('(ОсновнаяВалюта/text())[1]', 'varchar(36)'),
        [ПараметрыПрописи] = X.C.value('(ПараметрыПрописи/text())[1]', 'varchar(200)'),
        [ФормулаРасчетаКурса] = X.C.value('(ФормулаРасчетаКурса/text())[1]', 'varchar(100)'),
        [СпособУстановкиКурса] = X.C.value('(СпособУстановкиКурса/text())[1]', 'varchar(500)'),
        [dt_update] = @UpdateDate
    FROM [odins].[DIM_Валюты_buffer] AS b
        INNER JOIN @LockedListUniq l ON l.buffer_id = b.buffer_id
        CROSS APPLY b.msg.nodes('/Data/Реквизиты/CatalogObject.Валюты') AS X(C)
    ;

    EXEC [odins].[load_DIM_Валюты_staging]

    -- Clear buffer table
    IF @BufferHistoryMode = 1 AND NOT EXISTS (SELECT 1 FROM [odins].[DIM_Валюты_buffer] WHERE [is_error] = 1)
    BEGIN
        DELETE b
        FROM [odins].[DIM_Валюты_buffer] b
        INNER JOIN @LockedList t ON b.buffer_id = t.buffer_id
    END
    ELSE
    BEGIN
        UPDATE b SET
            dt_update = @UpdateDate
        FROM [odins].[DIM_Валюты_buffer] AS b
            INNER JOIN @LockedList l ON l.buffer_id = b.buffer_id

        IF @BufferHistoryMode >= 2 AND NOT EXISTS (SELECT 1 FROM [odins].[DIM_Валюты_buffer] WHERE [is_error] = 1)
            DELETE b
            FROM [odins].[DIM_Валюты_buffer] b
            WHERE DATEDIFF(DD, @UpdateDate, dt_update) > @BufferHistoryDays
    END


COMMIT TRANSACTION
END TRY
BEGIN CATCH
    SELECT @ErrMessage = ERROR_MESSAGE()
    IF XACT_STATE() <> 0 AND @@TRANCOUNT > 0 
    BEGIN
         ROLLBACK TRANSACTION
    END

    DECLARE @err_session_id bigint;
    SELECT @err_session_id = ISNULL( @session_id, 0)
    INSERT [dbo].[session_log] ( session_id, [session_state_id], [error_message])
    SELECT session_id = @err_session_id,
        [session_state_id] = 3,
        [error_message] = 'Table [odins].[DIM_Валюты_buffer]. Error: ' +@ErrMessage

    IF NOT @ErrMessage LIKE '%deadlock%'
        UPDATE b SET 
            [session_id] = @err_session_id,            [is_error]   = 1,
            [dt_update]  = ISNULL(@UpdateDate, GetDate())
        FROM [odins].[DIM_Валюты_buffer] b
            INNER JOIN @LockedList l ON b.[buffer_id] = l.[buffer_id]
        WHERE [is_error] = 0

    PRINT @ErrMessage
    RETURN -1
END CATCH

END

GO
