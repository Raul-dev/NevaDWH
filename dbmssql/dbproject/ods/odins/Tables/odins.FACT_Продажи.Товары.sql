CREATE TABLE [odins].[FACT_Продажи.Товары] (
    [ods_id]  bigint IDENTITY(1,1) Primary key,
    [nkey]  uniqueidentifier NOT NULL,
    [FACT_ПродажиRefID]  uniqueidentifier,
    [Доставка]  bit,
    [Товар]  varchar(36),
    [Колличество]  decimal(12,0),
    [Цена]  decimal(16,4),
    [dt_update]  datetime2(4) NOT NULL CONSTRAINT [DF_odins_FACT_Продажи.Товары_target_dt_udate_DEFAULT] DEFAULT (getdate()),
    [dt_create]  datetime2(4) NOT NULL CONSTRAINT [DF_odins_FACT_Продажи.Товары_target_dt_create_DEFAULT] DEFAULT (getdate())
);
GO
CREATE NONCLUSTERED INDEX [idx_FACT_Продажи.Товары_target] ON [odins].[FACT_Продажи.Товары]
(
    [FACT_ПродажиRefID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]

GO
