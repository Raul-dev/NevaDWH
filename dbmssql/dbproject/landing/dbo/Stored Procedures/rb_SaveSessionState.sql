
CREATE PROCEDURE [dbo].[rb_SaveSessionState] 
    @session_id       bigint = NULL,
    @data_source_id   tinyint = 1,
    @session_state_id tinyint = 1,
    @error_message    nvarchar(4000) = NULL
AS
    IF(@session_id IS NULL)
    BEGIN
        DECLARE @IdentityOutput table ( [session_id] bigint )
        INSERT [session] ([data_source_id],    [session_state_id],    [error_message])
        OUTPUT inserted.[session_id] into @IdentityOutput
        VALUES(@data_source_id, @session_state_id, @error_message)
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
    