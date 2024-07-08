CREATE PROCEDURE [staging].[sp_FACT_Продажи_transfer]
    @session_id bigint = NULL, 
    @RowCount   bigint = NULL OUTPUT
AS
BEGIN
SET XACT_ABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET NOCOUNT ON

DECLARE @ErrMessage nvarchar(4000)
BEGIN TRY
    DECLARE @start_date datetime
    DECLARE @dwh_session_id bigint, @LastTargetID bigint, @LocalCount bigint
    DECLARE @source_name varchar(128) 

    TRUNCATE TABLE [staging].[FACT_Продажи]
    SELECT @LastTargetID = MAX(id) FROM [target].[FACT_Продажи]
    IF ISNULL(@LastTargetID,0) >= 1
    BEGIN
        SET @LastTargetID = @LastTargetID + 1
        DBCC CHECKIDENT('[staging].[FACT_Продажи]', RESEED, @LastTargetID) WITH NO_INFOMSGS
    END
    SELECT @start_date = [create_session],
        @dwh_session_id = [dwh_session_id],
        @source_name = (SELECT [name] FROM [dbo].[data_source] d WHERE d.data_source_id =  s.data_source_id)
    FROM [session] s WHERE [session_id] = @session_id

    INSERT [staging].[FACT_Продажи] (
        [session_id],
        [source_name],
        [nkey],
        [vkey],
        [start_date],
        [end_date],
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
        [session_id_update],
        [dt_update]
    )
    SELECT
        @session_id AS [session_id],
        @source_name AS [source_name],
        [nkey],
        nkey AS [vkey],
        @start_date AS [start_date],
        dbo.fn_GetMaxDate() AS [end_date],
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
        @session_id AS [session_id_update],
        @start_date AS [dt_update]
    FROM [$(ods)].[odins].[FACT_Продажи_history] tmp
    WHERE [dwh_session_id] = @dwh_session_id
    SET @LocalCount= ROWCOUNT_BIG ( ) 
    SELECT @RowCount = @RowCount + @LocalCount


-- Child FACT_Продажи.Товары 
    TRUNCATE TABLE [staging].[FACT_Продажи.Товары]
    SELECT @LastTargetID = MAX(id) FROM [target].[FACT_Продажи.Товары]
    IF ISNULL(@LastTargetID,0) >= 1
    BEGIN
        SET @LastTargetID = @LastTargetID + 1
        DBCC CHECKIDENT('[staging].[FACT_Продажи.Товары]', RESEED, @LastTargetID) WITH NO_INFOMSGS
    END
    INSERT [staging].[FACT_Продажи.Товары] (
        [session_id],
        [source_name],
        [nkey],
        [vkey],
        [start_date],
        [end_date],
        [FACT_ПродажиRefID],
        [Доставка],
        [Товар],
        [Колличество],
        [Цена],
        [session_id_update],
        [dt_update]
    )
    SELECT
        @session_id AS [session_id],
        @source_name AS [source_name],
        [nkey],
        nkey AS [vkey],
        @start_date AS [start_date],
        dbo.fn_GetMaxDate() AS [end_date],
        [FACT_ПродажиRefID],
        [Доставка],
        [Товар],
        [Колличество],
        [Цена],
        @session_id AS session_id_update,
        @start_date AS dt_update
    FROM [$(ods)].[odins].[FACT_Продажи.Товары_history] tmp
    WHERE dwh_session_id = @dwh_session_id
END TRY
BEGIN CATCH
    SELECT @ErrMessage = ERROR_MESSAGE()
    IF XACT_STATE() <> 0 AND @@TRANCOUNT > 0 
    BEGIN
         ROLLBACK TRANSACTION
    END

    INSERT [dbo].[session_log] ([session_id], [session_state_id], [error_message])
    SELECT [session_id] = @session_id,
        [session_state_id] = 3,
        [error_message] = 'ETL transfer [odins_FACT_Продажи]. Error: ' +@ErrMessage

    RAISERROR( N'Error: [%s].', 16, 1, @ErrMessage)
    RETURN -1
END CATCH

END

GO
