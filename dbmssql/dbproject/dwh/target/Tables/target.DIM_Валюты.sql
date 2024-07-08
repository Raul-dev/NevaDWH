CREATE TABLE [target].[DIM_Валюты] (
    [id]                bigint NOT NULL,
    [session_id]        bigint NOT NULL,
    [source_name]       varchar(128) COLLATE Cyrillic_General_CI_AS NULL,
    [nkey]              uniqueidentifier NOT NULL,
    [vkey]              uniqueidentifier NOT NULL,
    [start_date]        datetime NOT NULL,
    [end_date]          datetime NOT NULL,
    [RefID]            uniqueidentifier  NOT NULL ,
    [DeletionMark]            bit  NULL ,
    [Code]            varchar(128)  NULL ,
    [Description]            varchar(128)  NULL ,
    [ЗагружаетсяИзИнтернета]            bit  NULL ,
    [НаименованиеПолное]            varchar(50)  NULL ,
    [Наценка]            decimal(10,2)  NULL ,
    [ОсновнаяВалюта]            varchar(36)  NULL ,
    [ПараметрыПрописи]            varchar(200)  NULL ,
    [ФормулаРасчетаКурса]            varchar(100)  NULL ,
    [СпособУстановкиКурса]            varchar(500)  NULL ,
    [session_id_update] bigint NOT NULL,
    [dt_update]         datetime2(4) NOT NULL CONSTRAINT [DF_DIM_Валюты_target_dt_update_DEFAULT] DEFAULT (getdate()),
    [dt_create]         datetime2(4) NOT NULL CONSTRAINT [DF_DIM_Валюты_target_dt_create_DEFAULT] DEFAULT (getdate())
);
GO
