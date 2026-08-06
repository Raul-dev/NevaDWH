CREATE TABLE [odins].[FACT_Продажи.Товары] (
    [OdsId]                       bigint IDENTITY(1,1) Primary key,
    [NKey]                        uniqueidentifier NOT NULL,
    [FACT_ПродажиRefID]           uniqueidentifier,
    [Доставка]                    bit,
    [Товар]                       varchar(36),
    [Колличество]                 decimal(12,0),
    [Цена]                        decimal(16,4),
    [UpdatedAt]                   datetime2(4) NOT NULL CONSTRAINT [DF_odins_FACT_Продажи.Товары_UpdatedAt] DEFAULT (GetDate()),
    [CreatedAt]                   datetime2(4) NOT NULL CONSTRAINT [DF_odins_FACT_Продажи.Товары_CreatedAt] DEFAULT (GetDate())
);

GO
CREATE NONCLUSTERED INDEX [idx_FACT_Продажи.Товары_target] ON [odins].[FACT_Продажи.Товары]
(
    [FACT_ПродажиRefID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]

GO
