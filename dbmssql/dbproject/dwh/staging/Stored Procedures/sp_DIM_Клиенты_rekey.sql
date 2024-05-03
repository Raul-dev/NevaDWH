CREATE PROCEDURE [staging].[sp_DIM_Клиенты_rekey]
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
    CREATE TABLE #DIM_Клиенты (
        identificator uniqueidentifier
    )

    UPDATE staging SET 
        [id] = ISNULL(trget.id, staging.staging_id),
        [session_id] = ISNULL(trget.session_id, staging.session_id),
        [start_date] = ISNULL(trget.start_date, staging.start_date)
    OUTPUT deleted.[RefID] into #DIM_Клиенты
    FROM [staging].[DIM_Клиенты] as staging
    LEFT JOIN [target].[DIM_Клиенты] as trget
            ON trget.end_date = dbo.fn_GetMaxDate() AND trget.[nkey] = staging.[nkey] AND trget.[vkey] = staging.[vkey]

    INSERT [staging].[DIM_Клиенты] (
        [id],
        [session_id],
        [source_name],
        [nkey],
        [vkey],
        [start_date],
        [end_date],
        [RefID],
        [DeletionMark],
        [Code],
        [Description],
        [Контакт],
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
        [Code],
        [Description],
        [Контакт],
        @session_id AS session_id_update,
        @start_date AS dt_update
    FROM (
        SELECT source.*
            FROM [target].[DIM_Клиенты] source
            WHERE source.[end_date] = dbo.fn_GetMaxDate() AND
            EXISTS( SELECT 1 FROM [staging].[DIM_Клиенты] as stg WHERE source.[nkey] = stg.[nkey] AND source.id <> stg.id )
        ) a
    SET @LocalCount= ROWCOUNT_BIG ( ) 
    SELECT @RowCount = @RowCount + @LocalCount
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
        [error_message] = 'ETL rekey [odins_DIM_Клиенты]. Error: ' +@ErrMessage

    RAISERROR( N'Error: [%s].', 16, 1, @ErrMessage)
    RETURN -1
END CATCH

END

GO
