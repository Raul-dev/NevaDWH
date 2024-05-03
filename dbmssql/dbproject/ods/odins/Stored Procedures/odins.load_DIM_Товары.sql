CREATE PROCEDURE [odins].[load_DIM_Товары]
    @session_id bigint = NULL,
    @RowCount int = NULL OUTPUT,
    @ErrMessage nvarchar(4000) = NULL OUTPUT
AS
BEGIN
SET XACT_ABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET NOCOUNT ON

SET TRANSACTION ISOLATION LEVEL READ COMMITTED
SET DEADLOCK_PRIORITY LOW
BEGIN TRY
BEGIN TRANSACTION

    DECLARE  @LockedList AS TABLE(
        buffer_id bigint Primary key,
        msg_id uniqueidentifier,
        [RefID] uniqueidentifier,
        msgtype_id tinyint
    )
    DECLARE  @LockedListTarget AS TABLE(
        ods_id bigint,
        [RefID] uniqueidentifier
    )

    INSERT INTO @LockedList
    SELECT buffer_id, msg_id, [RefID], msgtype_id
    FROM [odins].[DIM_Товары_buffer] b WITH(XLOCK)
    WHERE b.[is_error] = 0
     SET @RowCount = @@ROWCOUNT;

    IF @RowCount = 0 
    BEGIN
    
        COMMIT TRANSACTION
        return 0
    END

    IF EXISTS (SELECT 1 FROM @LockedList WHERE msgtype_id = 2)
    BEGIN

        WITH XMLNAMESPACES (DEFAULT 'http://v8.1c.ru/8.1/data/enterprise/current-config', 'http://www.w3.org/2001/XMLSchema-instance' as xsi)
        INSERT INTO filequeue ([session_id], [msg_key], [msg_id], [start_date], [finish_date], [filename] , [filefolder], [filetype], [error_msg], [state_id], dt_create)
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
            b.dt_create
        FROM [odins].[DIM_Товары_buffer]  b
            INNER JOIN @LockedList l ON b.buffer_id = l.buffer_id
        WHERE l.msgtype_id = 2 AND NOT EXISTS(SELECT 1 FROM dbo.filequeue f WHERE f.msg_key = 'CatalogObject.Товары' AND f.msg_id = l.msg_id AND f.dt_create = b.dt_create);

        DECLARE @FileQueueID bigint, @res int
        SELECT @FileQueueID = MIN(filequeue_id) FROM dbo.filequeue f WHERE f.msg_key = 'CatalogObject.Товары' AND state_id in (1,3)
        COMMIT TRANSACTION
        EXEC @res = [odins].[load_DIM_Товары_file] @FileQueueID = @FileQueueID,  @ErrMessage = @ErrMessage OUTPUT
        if @res <> 0
             RETURN
        BEGIN TRANSACTION
    END

    INSERT INTO @LockedListTarget
    SELECT ods_id, b.[RefID]
    FROM [odins].[DIM_Товары] b WITH(XLOCK)
        INNER JOIN @LockedList ll ON b.[RefID] = ll.[RefID];


    TRUNCATE TABLE staging.DIM_Товары;
    WITH XMLNAMESPACES (DEFAULT 'http://v8.1c.ru/8.1/data/enterprise/current-config', 'http://www.w3.org/2001/XMLSchema-instance' as xsi)
    INSERT staging.DIM_Товары(nkey,  [RefID], [DeletionMark], [Code], [Description], [Описание], dt_update)
    SELECT
         [nkey] = X.C.value('(Ref/text())[1]', 'uniqueidentifier'),
        [RefID] = X.C.value('(Ref/text())[1]', 'uniqueidentifier'),
        [DeletionMark] = X.C.value('(DeletionMark/text())[1]', 'bit'),
        [Code] = X.C.value('(Code/text())[1]', 'varchar(128)'),
        [Description] = X.C.value('(Description/text())[1]', 'varchar(128)'),
        [Описание] = X.C.value('(Описание/text())[1]', 'varchar(255)'),
        dt_update = GetDate()
    FROM [odins].[DIM_Товары_buffer] AS b
        INNER JOIN @LockedList l ON l.buffer_id = b.buffer_id
        CROSS APPLY b.msg.nodes('/Data/Реквизиты/CatalogObject.Товары') AS X(C)
    WHERE l.msgtype_id = 1;

    EXEC [odins].[load_DIM_Товары_staging]

 -- Clear buffer table
    DELETE b
    FROM [odins].[DIM_Товары_buffer] b
    WHERE EXISTS (SELECT 1 FROM @LockedList t WHERE b.buffer_id = t.buffer_id )
    

COMMIT TRANSACTION
END TRY
BEGIN CATCH
    SELECT @ErrMessage = ERROR_MESSAGE()
    IF XACT_STATE() <> 0 AND @@TRANCOUNT > 0 
    BEGIN
         ROLLBACK TRANSACTION
    END

    DECLARE @err_session_id bigint;    SELECT @err_session_id = ISNULL( @session_id, 0)
    INSERT [dbo].[session_log] ( session_id, [session_state_id], [error_message])
    SELECT session_id = @err_session_id,
        [session_state_id] = 3,
        [error_message] = 'Table [odins].[DIM_Товары_buffer]. Error: ' +@ErrMessage

    IF NOT @ErrMessage like '%deadlock%'
        UPDATE b SET 
            [session_id] = @err_session_id,            [is_error] = 1,
            [dt_update] = GetDate()
        FROM [odins].[DIM_Товары_buffer] b
            INNER JOIN @LockedList l ON b.buffer_id = l.buffer_id
        WHERE [is_error] = 0

    --RAISERROR( N'Error: [%s].', 16, 1, @ErrMessage)
    print @ErrMessage    RETURN -1
END CATCH

END

GO
