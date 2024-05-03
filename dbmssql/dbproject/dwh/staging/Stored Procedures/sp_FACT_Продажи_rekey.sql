CREATE PROCEDURE [staging].[sp_FACT_Продажи_rekey]
    @session_id bigint = NULL, 
    @RowCount bigint = NULL OUTPUT
AS
BEGIN
SET XACT_ABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET NOCOUNT ON

DECLARE @ErrMessage nvarchar(4000)
BEGIN TRY
DECLARE @start_date datetime
DECLARE @LocalCount bigint
    SELECT @start_date = create_session FROM session WHERE session_id = @session_id
    CREATE TABLE #FACT_Продажи (
        identificator uniqueidentifier
    )

    UPDATE staging SET 
        [id] = ISNULL(trget.id, staging.staging_id),
        [session_id] = ISNULL(trget.session_id, staging.session_id),
        [start_date] = ISNULL(trget.start_date, staging.start_date)
    OUTPUT deleted.[RefID] into #FACT_Продажи
    FROM [staging].[FACT_Продажи] as staging
    LEFT JOIN [target].[FACT_Продажи] as trget
            ON trget.end_date = dbo.fn_GetMaxDate() AND trget.[nkey] = staging.[nkey] AND trget.[vkey] = staging.[vkey]

    INSERT [staging].[FACT_Продажи] (
        [id],
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
        session_id_update,
        dt_update
    )
    SELECT
        [id],
        [session_id],
        [source_name],
        [nkey],
        [vkey],
        [start_date],
        @start_date as [end_date],
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
        @session_id AS session_id_update,
        @start_date AS dt_update
    FROM (
        SELECT source.*
            FROM [target].[FACT_Продажи] source
            WHERE source.[end_date] = dbo.fn_GetMaxDate() AND
            EXISTS( SELECT 1 FROM [staging].[FACT_Продажи] as stg WHERE source.[nkey] = stg.[nkey] AND source.id <> stg.id )
        ) a
    SET @LocalCount= ROWCOUNT_BIG ( ) 
    SELECT @RowCount = @RowCount + @LocalCount
-- Child 
    DELETE b FROM [target].[FACT_Продажи.Товары] b
        INNER JOIN #FACT_Продажи ll ON b.[FACT_ПродажиRefID] = ll.[identificator]
    UPDATE staging SET
        [id] = staging_id
    FROM [staging].[FACT_Продажи.Товары] AS staging
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
        [error_message] = 'ETL rekey [odins_FACT_Продажи]. Error: ' +@ErrMessage

    RAISERROR( N'Error: [%s].', 16, 1, @ErrMessage)
    RETURN -1
END CATCH

END

GO
