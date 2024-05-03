CREATE   PROCEDURE [dbo].[rb_GetMappingSetup]
AS

    SELECT 
        metamap_id,
        msg_key,
        table_name,
        metaadapter_id,
        etl_query
    FROM [metamap] WHERE is_enable = 1