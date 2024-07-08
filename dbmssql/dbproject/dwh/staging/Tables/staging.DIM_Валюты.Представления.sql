CREATE TABLE [staging].[DIM_Валюты.Представления] (
    [staging_id]        bigint IDENTITY(1,1) NOT NULL,
    [id]                bigint NULL,
    [session_id]        bigint NULL,
    [source_name]       varchar(128) COLLATE Cyrillic_General_CI_AS NULL,
    [nkey]              uniqueidentifier NULL,
    [vkey]              uniqueidentifier NULL,
    [start_date]        datetime NULL,
    [end_date]          datetime NULL,
    [DIM_ВалютыRefID]            uniqueidentifier  NULL,
    [КодЯзыка]            varchar(10)  NULL,
    [ПараметрыПрописи]            varchar(200)  NULL,
    [session_id_update] bigint NOT NULL,
    [dt_update]         datetime2(4)         NULL);
GO