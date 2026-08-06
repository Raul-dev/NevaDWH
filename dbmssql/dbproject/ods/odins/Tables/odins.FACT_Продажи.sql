CREATE TABLE [odins].[FACT_Продажи] (
    [OdsId]                       bigint IDENTITY(1,1) Primary key,
    [NKey]                        uniqueidentifier NOT NULL,
    [RefID]                       uniqueidentifier,
    [DeletionMark]                bit,
    [Number]                      int,
    [Posted]                      bit,
    [Date]                        datetime2(0),
    [DateID]                      int,
    [ДатаОтгрузки]                datetime2(0),
    [ДатаОтгрузкиID]              int,
    [Клиент]                      varchar(36),
    [ТипДоставки]                 varchar(500),
    [ПримерСоставногоТипа]        varchar(36),
    [ПримерСоставногоТипа_ТипЗначения]varchar(128),
    [UpdatedAt]                   datetime2(4) NOT NULL CONSTRAINT [DF_odins_FACT_Продажи_UpdatedAt] DEFAULT (GetDate()),
    [CreatedAt]                   datetime2(4) NOT NULL CONSTRAINT [DF_odins_FACT_Продажи_CreatedAt] DEFAULT (GetDate())
);

GO
CREATE NONCLUSTERED INDEX [idx_FACT_Продажи_target] ON [odins].[FACT_Продажи]
(
    [RefID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]

GO
