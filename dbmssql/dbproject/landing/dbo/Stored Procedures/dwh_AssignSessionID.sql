CREATE PROCEDURE dwh_AssignSessionID
    @dwh_session_id bigint = NULL OUTPUT, -- @dwh_session_id = -1 create new package
    @RowCount       int = NULL OUTPUT,
    @ErrorMessage   varchar(4000) = NULL OUTPUT
AS
BEGIN
SET XACT_ABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET NOCOUNT ON

SET TRANSACTION ISOLATION LEVEL READ COMMITTED
SET DEADLOCK_PRIORITY HIGH
BEGIN TRY

    SET @RowCount = 0
    DECLARE @T AS TABLE (dwh_session_id bigint)

RETURN 0
END TRY
BEGIN CATCH
    SELECT @ErrorMessage = ERROR_MESSAGE()
    IF XACT_STATE() <> 0 AND @@TRANCOUNT > 0 
    BEGIN
         ROLLBACK TRANSACTION
    END

    UPDATE dwh_session SET [dwh_session_state_id] = 3
    WHERE dwh_session_id = @dwh_session_id
    INSERT [dwh_session_log] ( dwh_session_id, [dwh_session_state_id], [error_message])
    SELECT dwh_session_id = @dwh_session_id,
        [dwh_session_state_id] = 3,
        [dwh_error_message] = 'AssignSessionID Error: ' + @ErrorMessage

    --RAISERROR( N'Error: [%s].', 16, 1, @ErrorMessage)
    SELECT @dwh_session_id, -1 as row_count, @ErrorMessage AS ErrMessage
    RETURN -1
END CATCH

END

GO
