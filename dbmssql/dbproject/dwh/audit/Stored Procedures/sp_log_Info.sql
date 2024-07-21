CREATE PROCEDURE [audit].[sp_log_Info] 
    @LogID         int          = NULL,
    @ProcedureInfo varchar(max) = NULL
AS 
BEGIN
                    
    IF @LogID IS NULL RETURN 0

    EXEC [$(LinkSRVLogLanding)].[$(landing)].[audit].sp_lnk_Update
        @LogID         = @LogID,
        @ProcedureInfo = @ProcedureInfo

    RETURN 0
END
