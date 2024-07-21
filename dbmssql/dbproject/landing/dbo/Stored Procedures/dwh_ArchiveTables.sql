 CREATE PROCEDURE dwh_ArchiveTables( 
    @dwh_session_id bigint = NULL,
    @ErrorMessage   varchar(4000) = NULL OUTPUT
)
AS
BEGIN
BEGIN TRY

    BEGIN TRANSACTION
        UPDATE [dwh_session] SET dwh_session_state_id = 6
        WHERE dwh_session_id = @dwh_session_id
    COMMIT TRANSACTION
    IF @ErrorMessage IS NULL SET @ErrorMessage = ''
END TRY
BEGIN CATCH
    SELECT @ErrorMessage = ERROR_MESSAGE()

    IF XACT_STATE() <> 0 AND @@TRANCOUNT > 0 
    BEGIN
         ROLLBACK TRANSACTION
    END

    INSERT [dwh_session_log] ( dwh_session_id, [dwh_session_state_id], [error_message])
    SELECT dwh_session_id = @dwh_session_id,
        [dwh_session_state_id] = 3,
        [error_message] = 'ArchiveTables Error: ' + @ErrorMessage
    IF XACT_STATE() != -1 
      BEGIN
        IF (@@TRANCOUNT > 0 ) ROLLBACK TRANSACTION
      END

    RAISERROR( N'Error: [%s].', 16, 1, @ErrorMessage)
    RETURN -1
END CATCH
END

