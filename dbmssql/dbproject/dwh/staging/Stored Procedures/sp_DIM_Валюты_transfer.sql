CREATE PROCEDURE [staging].[sp_DIM_Валюты_transfer]
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

    TRUNCATE TABLE [staging].[DIM_Валюты]
    SELECT @LastTargetID = MAX(id) FROM [target].[DIM_Валюты]
    IF ISNULL(@LastTargetID,0) >= 1
    BEGIN
        SET @LastTargetID = @LastTargetID + 1
        DBCC CHECKIDENT('[staging].[DIM_Валюты]', RESEED, @LastTargetID) WITH NO_INFOMSGS
    END
    SELECT @start_date = [create_session],
        @dwh_session_id = [dwh_session_id],
        @source_name = (SELECT [name] FROM [dbo].[data_source] d WHERE d.data_source_id =  s.data_source_id)
    FROM [session] s WHERE [session_id] = @session_id

    INSERT [staging].[DIM_Валюты] (
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
        [ЗагружаетсяИзИнтернета],
        [НаименованиеПолное],
        [Наценка],
        [ОсновнаяВалюта],
        [ПараметрыПрописи],
        [ФормулаРасчетаКурса],
        [СпособУстановкиКурса],
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
        [Code],
        [Description],
        [ЗагружаетсяИзИнтернета],
        [НаименованиеПолное],
        [Наценка],
        [ОсновнаяВалюта],
        [ПараметрыПрописи],
        [ФормулаРасчетаКурса],
        [СпособУстановкиКурса],
        @session_id AS [session_id_update],
        @start_date AS [dt_update]
    FROM [$(ods)].[odins].[DIM_Валюты_history] tmp
    WHERE [dwh_session_id] = @dwh_session_id
    SET @LocalCount= ROWCOUNT_BIG ( ) 
    SELECT @RowCount = @RowCount + @LocalCount


-- Child DIM_Валюты.Представления 
    TRUNCATE TABLE [staging].[DIM_Валюты.Представления]
    SELECT @LastTargetID = MAX(id) FROM [target].[DIM_Валюты.Представления]
    IF ISNULL(@LastTargetID,0) >= 1
    BEGIN
        SET @LastTargetID = @LastTargetID + 1
        DBCC CHECKIDENT('[staging].[DIM_Валюты.Представления]', RESEED, @LastTargetID) WITH NO_INFOMSGS
    END
    INSERT [staging].[DIM_Валюты.Представления] (
        [session_id],
        [source_name],
        [nkey],
        [vkey],
        [start_date],
        [end_date],
        [DIM_ВалютыRefID],
        [КодЯзыка],
        [ПараметрыПрописи],
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
        [DIM_ВалютыRefID],
        [КодЯзыка],
        [ПараметрыПрописи],
        @session_id AS session_id_update,
        @start_date AS dt_update
    FROM [$(ods)].[odins].[DIM_Валюты.Представления_history] tmp
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
        [error_message] = 'ETL transfer [odins_DIM_Валюты]. Error: ' +@ErrMessage

    RAISERROR( N'Error: [%s].', 16, 1, @ErrMessage)
    RETURN -1
END CATCH

END

GO
