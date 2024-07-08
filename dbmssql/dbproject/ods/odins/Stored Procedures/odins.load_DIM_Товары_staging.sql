CREATE PROCEDURE [odins].[load_DIM_Товары_staging]
AS
BEGIN

    MERGE INTO [odins].[DIM_Товары] trg
    USING 
    (
        SELECT *
        FROM [staging].[DIM_Товары] p
         ) src
        ON src.[nkey] = trg.[nkey] 
         WHEN MATCHED 
        THEN UPDATE SET
            [nkey] = src.[nkey],
            [RefID] = src.[RefID],
            [DeletionMark] = src.[DeletionMark],
            [Code] = src.[Code],
            [Description] = src.[Description],
            [Описание] = src.[Описание],
            [dt_update] = GetDate()
        WHEN NOT MATCHED BY TARGET
        THEN INSERT (
            [nkey] ,
            [RefID],
            [DeletionMark],
            [Code],
            [Description],
            [Описание],
            [dt_update]
    )
        VALUES
    (
            src.[nkey] ,
            src.[RefID],
            src.[DeletionMark],
            src.[Code],
            src.[Description],
            src.[Описание],
            [dt_update]
     );


--Sub table
END

GO
