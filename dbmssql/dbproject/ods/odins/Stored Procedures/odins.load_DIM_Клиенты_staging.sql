CREATE PROCEDURE [odins].[load_DIM_Клиенты_staging]
AS
BEGIN

    MERGE INTO [odins].[DIM_Клиенты] trg
    USING 
    (
        SELECT *
        FROM [staging].[DIM_Клиенты] p
         ) src
        ON src.[nkey] = trg.[nkey] 
         WHEN MATCHED 
        THEN UPDATE SET
            [nkey] = src.[nkey],
            [RefID] = src.[RefID],
            [DeletionMark] = src.[DeletionMark],
            [Code] = src.[Code],
            [Description] = src.[Description],
            [Контакт] = src.[Контакт],
            [dt_update] = GetDate()
        WHEN NOT MATCHED BY TARGET
        THEN INSERT (
            [nkey] ,
            [RefID],
            [DeletionMark],
            [Code],
            [Description],
            [Контакт],
            [dt_update]
    )
        VALUES
    (
            src.[nkey] ,
            src.[RefID],
            src.[DeletionMark],
            src.[Code],
            src.[Description],
            src.[Контакт],
            [dt_update]
     );


--Sub table
END

GO
