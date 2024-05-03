CREATE PROCEDURE [staging].[sp_DIM_Валюты_publish]
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
        trg.[Code] = stg.[Code],
        trg.[Description] = stg.[Description],
        trg.[ЗагружаетсяИзИнтернета] = stg.[ЗагружаетсяИзИнтернета],
        trg.[НаименованиеПолное] = stg.[НаименованиеПолное],
        trg.[Наценка] = stg.[Наценка],
        trg.[ОсновнаяВалюта] = stg.[ОсновнаяВалюта],
        trg.[ПараметрыПрописи] = stg.[ПараметрыПрописи],
        trg.[ФормулаРасчетаКурса] = stg.[ФормулаРасчетаКурса],
        trg.[СпособУстановкиКурса] = stg.[СпособУстановкиКурса]
    FROM [staging].[DIM_Валюты] stg
    INNER JOIN [target].[DIM_Валюты] trg ON stg.id = trg.id

    INSERT [target].[DIM_Валюты] (
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
        [Code],
        [Description],
        [ЗагружаетсяИзИнтернета],
        [НаименованиеПолное],
        [Наценка],
        [ОсновнаяВалюта],
        [ПараметрыПрописи],
        [ФормулаРасчетаКурса],
        [СпособУстановкиКурса]
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
        [Code],
        [Description],
        [ЗагружаетсяИзИнтернета],
        [НаименованиеПолное],
        [Наценка],
        [ОсновнаяВалюта],
        [ПараметрыПрописи],
        [ФормулаРасчетаКурса],
        [СпособУстановкиКурса]
    FROM [staging].[DIM_Валюты]
    WHERE staging_id = id
    UPDATE trg SET
        trg.[session_id] = stg.[session_id],
        trg.[start_date] = stg.[start_date],
        trg.[end_date] = stg.[end_date],
        trg.[session_id_update] = stg.session_id_update,
        trg.[dt_update] = stg.dt_update,
        trg.[DIM_ВалютыRefID] = stg.[DIM_ВалютыRefID],
        trg.[КодЯзыка] = stg.[КодЯзыка],
        trg.[ПараметрыПрописи] = stg.[ПараметрыПрописи]
    FROM [staging].[DIM_Валюты.Представления] stg
    INNER JOIN [target].[DIM_Валюты.Представления] trg ON stg.id = trg.id

    INSERT [target].[DIM_Валюты.Представления] (
        [id],
        [session_id],
        [source_name],
        [nkey],
        [vkey],
        [start_date],
        [end_date],
        [session_id_update],
        [dt_update],
        [DIM_ВалютыRefID],
        [КодЯзыка],
        [ПараметрыПрописи]
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
        [DIM_ВалютыRefID],
        [КодЯзыка],
        [ПараметрыПрописи]
    FROM [staging].[DIM_Валюты.Представления]
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
        [error_message] = 'Table [bulk].[odins_DIM_Валюты]. Error: ' +@ErrMessage

    RAISERROR( N'Error: [%s].', 16, 1, @ErrMessage)
    RETURN -1
END CATCH

END

GO
