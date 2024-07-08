CREATE PROCEDURE [staging].[sp_FACT_Продажи_publish]
    @session_id bigint = NULL, 
    @RowCount bigint = NULL OUTPUT
AS
BEGIN
SET XACT_ABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET NOCOUNT ON

DECLARE @ErrMessage nvarchar(4000)
BEGIN TRY

    UPDATE trg SET
        trg.[session_id] = stg.[session_id],
        trg.[start_date] = stg.[start_date],
        trg.[end_date] = stg.[end_date],
        trg.[session_id_update] = stg.session_id_update,
        trg.[dt_update] = stg.dt_update,
        trg.[RefID] = stg.[RefID],
        trg.[DeletionMark] = stg.[DeletionMark],
        trg.[Number] = stg.[Number],
        trg.[Posted] = stg.[Posted],
        trg.[Date] = stg.[Date],
        trg.[ДатаОтгрузки] = stg.[ДатаОтгрузки],
        trg.[Клиент] = stg.[Клиент],
        trg.[ТипДоставки] = stg.[ТипДоставки],
        trg.[ПримерСоставногоТипа] = stg.[ПримерСоставногоТипа],
        trg.[ПримерСоставногоТипа_ТипЗначения] = stg.[ПримерСоставногоТипа_ТипЗначения]
    FROM [staging].[FACT_Продажи] stg
    INNER JOIN [target].[FACT_Продажи] trg ON stg.id = trg.id

    INSERT [target].[FACT_Продажи] (
        [id],
        [session_id],
        [source_name],
        [nkey],
        [vkey],
        [start_date],
        [end_date],
        [session_id_update],
        [dt_update],
        [RefID],
        [DeletionMark],
        [Number],
        [Posted],
        [Date],
        [ДатаОтгрузки],
        [Клиент],
        [ТипДоставки],
        [ПримерСоставногоТипа],
        [ПримерСоставногоТипа_ТипЗначения]
    )
    SELECT
        [id],
        [session_id],
        [source_name],
        [nkey],
        [vkey],
        [start_date],
        [end_date],
        [session_id_update],
        [dt_update],
        [RefID],
        [DeletionMark],
        [Number],
        [Posted],
        [Date],
        [ДатаОтгрузки],
        [Клиент],
        [ТипДоставки],
        [ПримерСоставногоТипа],
        [ПримерСоставногоТипа_ТипЗначения]
    FROM [staging].[FACT_Продажи]
    WHERE staging_id = id
    UPDATE trg SET
        trg.[session_id] = stg.[session_id],
        trg.[start_date] = stg.[start_date],
        trg.[end_date] = stg.[end_date],
        trg.[session_id_update] = stg.session_id_update,
        trg.[dt_update] = stg.dt_update,
        trg.[FACT_ПродажиRefID] = stg.[FACT_ПродажиRefID],
        trg.[Доставка] = stg.[Доставка],
        trg.[Товар] = stg.[Товар],
        trg.[Колличество] = stg.[Колличество],
        trg.[Цена] = stg.[Цена]
    FROM [staging].[FACT_Продажи.Товары] stg
    INNER JOIN [target].[FACT_Продажи.Товары] trg ON stg.id = trg.id

    INSERT [target].[FACT_Продажи.Товары] (
        [id],
        [session_id],
        [source_name],
        [nkey],
        [vkey],
        [start_date],
        [end_date],
        [session_id_update],
        [dt_update],
        [FACT_ПродажиRefID],
        [Доставка],
        [Товар],
        [Колличество],
        [Цена]
    )
    SELECT
        [id],
        [session_id],
        [source_name],
        [nkey],
        [vkey],
        [start_date],
        [end_date],
        [session_id_update],
        [dt_update],
        [FACT_ПродажиRefID],
        [Доставка],
        [Товар],
        [Колличество],
        [Цена]
    FROM [staging].[FACT_Продажи.Товары]
    WHERE staging_id = id
END TRY
BEGIN CATCH
    SELECT @ErrMessage = ERROR_MESSAGE()
    IF XACT_STATE() <> 0 AND @@TRANCOUNT > 0 
    BEGIN
         ROLLBACK TRANSACTION
    END

    INSERT [dbo].[session_log] ( session_id, [session_state_id], [error_message])
    SELECT session_id = @session_id,
        [session_state_id] = 3,
        [error_message] = 'Table [bulk].[odins_FACT_Продажи]. Error: ' +@ErrMessage

    RAISERROR( N'Error: [%s].', 16, 1, @ErrMessage)
    RETURN -1
END CATCH

END

GO
