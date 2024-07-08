CREATE PROCEDURE [dbo].[sp_SaveSessionState] 
    @session_id        bigint = NULL,
    @dwh_session_id    bigint = NULL,
    @rows_count        int = NULL,
    @data_source_id    tinyint = 1,
    @session_state_id  tinyint = 1,
    @create_session    datetime2(4) = NULL,
    @error_message     varchar(4000) = NULL
AS
    
    IF(@session_id IS NULL)
    BEGIN
        DECLARE @IdentityOutput table (session_id bigint )
        INSERT [session] ([dwh_session_id], [rows_count], [data_source_id], [session_state_id], [create_session], [error_message])
        OUTPUT inserted.[session_id] into @IdentityOutput
        VALUES(@dwh_session_id, @rows_count, @data_source_id, @session_state_id, @create_session, @error_message)
        SELECT * FROM @IdentityOutput
    END 
    ELSE
    BEGIN
        UPDATE [session] SET 
            [session_state_id] = @session_state_id,    
            [error_message]    = @error_message,
            [dt_update]        = GetDate()
        WHERE [session_id] = @session_id
    END