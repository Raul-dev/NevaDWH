CREATE TABLE [staging].[FACT_Продажи.Товары] (
    [staging_id]        bigint IDENTITY(1,1) NOT NULL,
    [id]                bigint NULL,
    [session_id]        bigint NULL,
    [source_name]       varchar(128) COLLATE Cyrillic_General_CI_AS NULL,
    [nkey]              uniqueidentifier NULL,
    [vkey]              uniqueidentifier NULL,
    [start_date]        datetime NULL,
    [end_date]          datetime NULL,
    [FACT_ПродажиRefID]            uniqueidentifier  NULL,
    [Доставка]            bit  NULL,
    [Товар]            varchar(36)  NULL,
    [Колличество]            decimal(12,0)  NULL,
    [Цена]            decimal(16,4)  NULL,
    [session_id_update] bigint NOT NULL,
    [dt_update]         datetime2(4)         NULL);
GO