
CREATE  PROCEDURE [audit].[sp_AuditInfo] 
    @LogID        INT = NULL,    
    @SPInfo        VARCHAR(MAX) = NULL
AS 
BEGIN
    SET NOCOUNT ON         

    IF @SPInfo IS NOT NULL
        UPDATE [audit].[LogProcedures]
        SET    [SPInfo] = ISNULL([SPInfo], '') 
                       + ISNULL(@SPInfo + '; ', '')                    
        WHERE LogID = @LogID    

END