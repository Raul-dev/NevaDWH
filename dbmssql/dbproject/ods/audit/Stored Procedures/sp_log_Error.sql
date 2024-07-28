CREATE PROCEDURE [audit].[sp_log_Error] 
    @LogID         int  = NULL,
    @ErrorMessage  varchar(4000) = NULL
AS 
BEGIN

    IF @LogID IS NULL RETURN 0
    IF EXISTS ( SELECT 1 FROM sys.dm_exec_sessions WITH(nolock)
        WHERE session_id = @@SPID AND transaction_isolation_level = 5)
        --SNAPSHOT ISOLATION LEVEL Remote access is not supported for transaction isolation level "SNAPSHOT".

        EXEC [$(LinkSRVLogLanding)].[$(landing)].[audit].sp_lnk_Update
            @LogID         = @LogID,
            @ErrorMessage  = @ErrorMessage
    ELSE
        EXEC [$(LinkSRVLogLanding)].[$(landing)].[audit].sp_lnk_Update
            @LogID         = @LogID,
            @ErrorMessage  = @ErrorMessage

    RETURN 0
END