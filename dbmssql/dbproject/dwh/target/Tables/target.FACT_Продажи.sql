CREATE TABLE [target].[FACT_Продажи] (
    [id]                bigint NOT NULL,
    [session_id]        bigint NOT NULL,
    [source_name]       varchar(128) COLLATE Cyrillic_General_CI_AS NULL,
    [nkey]              uniqueidentifier NOT NULL,
    [vkey]              uniqueidentifier NOT NULL,
    [start_date]        datetime NOT NULL,
    [end_date]          datetime NOT NULL,
    [RefID]            uniqueidentifier  NOT NULL ,
    [DeletionMark]            bit  NULL ,
    [Number]            int  NULL ,
    [Posted]            bit  NULL ,
    [Date]            datetime2(0)  NULL ,
    [ДатаОтгрузки]            datetime2(0)  NULL ,
    [Клиент]            varchar(36)  NULL ,
    [ТипДоставки]            varchar(500)  NULL ,
    [ПримерСоставногоТипа]            varchar(36)  NULL ,
    [ПримерСоставногоТипа_ТипЗначения]            varchar(128)  NULL ,
    [session_id_update] bigint NOT NULL,
    [dt_update]         datetime2(4) NOT NULL CONSTRAINT [DF_FACT_Продажи_target_dt_update_DEFAULT] DEFAULT (getdate()),
    [dt_create]         datetime2(4) NOT NULL CONSTRAINT [DF_FACT_Продажи_target_dt_create_DEFAULT] DEFAULT (getdate())
);
GO
