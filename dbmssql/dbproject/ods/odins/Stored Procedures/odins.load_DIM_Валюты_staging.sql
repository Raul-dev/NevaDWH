CREATE PROCEDURE [odins].[load_DIM_Валюты_staging]
AS
BEGIN

    MERGE INTO [odins].[DIM_Валюты] trg
    USING 
    (
        SELECT *
        FROM [staging].[DIM_Валюты] p
         ) src
        ON src.[nkey] = trg.[nkey] 
         WHEN MATCHED 
        THEN UPDATE SET
            [nkey] = src.[nkey],
            [RefID] = src.[RefID],
            [DeletionMark] = src.[DeletionMark],
            [Code] = src.[Code],
            [Description] = src.[Description],
            [ЗагружаетсяИзИнтернета] = src.[ЗагружаетсяИзИнтернета],
            [НаименованиеПолное] = src.[НаименованиеПолное],
            [Наценка] = src.[Наценка],
            [ОсновнаяВалюта] = src.[ОсновнаяВалюта],
            [ПараметрыПрописи] = src.[ПараметрыПрописи],
            [ФормулаРасчетаКурса] = src.[ФормулаРасчетаКурса],
            [СпособУстановкиКурса] = src.[СпособУстановкиКурса],
            [dt_update] = GetDate()
        WHEN NOT MATCHED BY TARGET
        THEN INSERT (
            [nkey] ,
            [RefID],
            [DeletionMark],
            [Code],
            [Description],
            [ЗагружаетсяИзИнтернета],
            [НаименованиеПолное],
            [Наценка],
            [ОсновнаяВалюта],
            [ПараметрыПрописи],
            [ФормулаРасчетаКурса],
            [СпособУстановкиКурса],
            [dt_update]
    )
        VALUES
    (
            src.[nkey] ,
            src.[RefID],
            src.[DeletionMark],
            src.[Code],
            src.[Description],
            src.[ЗагружаетсяИзИнтернета],
            src.[НаименованиеПолное],
            src.[Наценка],
            src.[ОсновнаяВалюта],
            src.[ПараметрыПрописи],
            src.[ФормулаРасчетаКурса],
            src.[СпособУстановкиКурса],
            [dt_update]
     );


--Sub table
    DELETE FROM [odins].[DIM_Валюты.Представления];


    WITH XMLNAMESPACES (DEFAULT 'http://v8.1c.ru/8.1/data/enterprise/current-config')
    INSERT [odins].[DIM_Валюты.Представления] (nkey, DIM_ВалютыRefID, КодЯзыка, ПараметрыПрописи,  dt_update)    SELECT     [nkey] = CAST(SUBSTRING(HASHBYTES('SHA2_256', COALESCE(CAST(b.RefID AS varchar(36)), '00000000-0000-0000-0000-000000000000')+ 
        '|' + COALESCE(CAST(STR(LTRIM(ROW_NUMBER() OVER (PARTITION BY b.RefID ORDER BY b.id))) AS varchar(36)), '00000000-0000-0000-0000-000000000000' ) )
            , 0,16) as uniqueidentifier),
    [DIM_ВалютыRefID] = b.RefID,
    [КодЯзыка] = X.C.value('(КодЯзыка/text())[1]', 'varchar(10)'),
    [ПараметрыПрописи] = X.C.value('(ПараметрыПрописи/text())[1]', 'varchar(200)'),
    [dt_update]
    FROM staging.[DIM_Валюты] b
    CROSS APPLY b.[DIM_Валюты.Представления].nodes('/Представления') AS X(C);
END

GO
