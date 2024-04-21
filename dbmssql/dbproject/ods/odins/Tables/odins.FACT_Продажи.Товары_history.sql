CREATE TABLE [odins].[FACT_Продажи.Товары_history] (
    [nkey]              uniqueidentifier NOT NULL,
    [dwh_session_id]           bigint NULL,
    [FACT_ПродажиRefID]            uniqueidentifier  NULL,
    [Доставка]            bit  NULL,
    [Товар]            varchar(36)  NULL,
    [Колличество]            decimal(12,0)  NULL,
    [Цена]            decimal(16,4)  NULL,
    [dt_create]   datetime2(4)   NOT NULL CONSTRAINT [DF_odins_FACT_Продажи.Товары_history_dt_create_DEFAULT] DEFAULT (getdate())
);
GO

