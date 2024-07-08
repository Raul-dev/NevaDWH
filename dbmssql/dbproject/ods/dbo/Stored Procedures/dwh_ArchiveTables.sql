 CREATE PROCEDURE dwh_ArchiveTables( 
    @dwh_session_id bigint = NULL,
    @ErrMessage     varchar(4000) = NULL OUTPUT
)
AS
BEGIN
BEGIN TRY

    BEGIN TRANSACTION

    DELETE [odins].[DIM_Валюты_history] WHERE dwh_session_id = @dwh_session_id

    DELETE [odins].[DIM_Валюты.Представления_history] WHERE dwh_session_id = @dwh_session_id

    DELETE [odins].[DIM_Клиенты_history] WHERE dwh_session_id = @dwh_session_id

    DELETE [odins].[DIM_Товары_history] WHERE dwh_session_id = @dwh_session_id

    DELETE [odins].[FACT_Продажи_history] WHERE dwh_session_id = @dwh_session_id

    DELETE [odins].[FACT_Продажи.Товары_history] WHERE dwh_session_id = @dwh_session_id


    UPDATE [dwh_session] SET dwh_session_state_id = 6
    WHERE dwh_session_id = @dwh_session_id
    COMMIT TRANSACTION
    IF @ErrMessage IS NULL SET @ErrMessage = ''
END TRY
BEGIN CATCH
    SELECT @ErrMessage = ERROR_MESSAGE()

    IF XACT_STATE() <> 0 AND @@TRANCOUNT > 0 
    BEGIN
         ROLLBACK TRANSACTION
    END

    INSERT [dwh_session_log] ( dwh_session_id, [dwh_session_state_id], [error_message])
    SELECT dwh_session_id = @dwh_session_id,
        [dwh_session_state_id] = 3,
        [error_message] = 'ArchiveTables Error: ' +@ErrMessage
    IF XACT_STATE() != -1 
      BEGIN
        IF (@@TRANCOUNT > 0 ) ROLLBACK TRANSACTION
      END

    RAISERROR( N'Error: [%s].', 16, 1, @ErrMessage)
    RETURN -1
END CATCH
END

