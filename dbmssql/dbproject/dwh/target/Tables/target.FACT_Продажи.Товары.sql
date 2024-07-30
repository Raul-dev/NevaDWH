CREATE TABLE [target].[FACT_Продажи.Товары] (
    [id]                bigint NOT NULL,
    [session_id]        bigint NOT NULL,
    [source_name]       varchar(128) COLLATE Cyrillic_General_CI_AS NULL,
    [nkey]              uniqueidentifier NOT NULL,
    [vkey]              uniqueidentifier NOT NULL,
    [start_date]        datetime NOT NULL,
    [end_date]          datetime NOT NULL,
    [FACT_ПродажиRefID]  uniqueidentifier  NOT NULL ,
    [Доставка]  bit  NULL ,
    [Товар]  varchar(36)  NULL ,
    [Колличество]  decimal(12,0)  NULL ,
    [Цена]  decimal(16,4)  NULL ,
    [session_id_update] bigint NOT NULL,
    [dt_update]         datetime2(4) NOT NULL CONSTRAINT [DF_FACT_Продажи.Товары_target_dt_update_DEFAULT] DEFAULT (getdate()),
    [dt_create]         datetime2(4) NOT NULL CONSTRAINT [DF_FACT_Продажи.Товары_target_dt_create_DEFAULT] DEFAULT (getdate())
);
GO
