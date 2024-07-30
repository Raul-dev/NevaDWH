CREATE TABLE [target].[DIM_Валюты.Представления] (
    [id]                bigint NOT NULL,
    [session_id]        bigint NOT NULL,
    [source_name]       varchar(128) COLLATE Cyrillic_General_CI_AS NULL,
    [nkey]              uniqueidentifier NOT NULL,
    [vkey]              uniqueidentifier NOT NULL,
    [start_date]        datetime NOT NULL,
    [end_date]          datetime NOT NULL,
    [DIM_ВалютыRefID]  uniqueidentifier  NOT NULL ,
    [КодЯзыка]  varchar(10)  NULL ,
    [ПараметрыПрописи]  varchar(200)  NULL ,
    [session_id_update] bigint NOT NULL,
    [dt_update]         datetime2(4) NOT NULL CONSTRAINT [DF_DIM_Валюты.Представления_target_dt_update_DEFAULT] DEFAULT (getdate()),
    [dt_create]         datetime2(4) NOT NULL CONSTRAINT [DF_DIM_Валюты.Представления_target_dt_create_DEFAULT] DEFAULT (getdate())
);
GO
