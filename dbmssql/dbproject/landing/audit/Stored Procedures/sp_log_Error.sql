CREATE PROCEDURE [audit].[sp_log_Error] 
    @LogID         int  = NULL,
    @ErrorMessage  varchar(4000) = NULL
AS 
BEGIN

    IF @LogID IS NULL RETURN 0

    EXEC [$(LinkSRVLogLanding)].[$(landing)].[audit].sp_lnk_Update
        @LogID         = @LogID,
        @ErrorMessage  = @ErrorMessage

    RETURN 0
END