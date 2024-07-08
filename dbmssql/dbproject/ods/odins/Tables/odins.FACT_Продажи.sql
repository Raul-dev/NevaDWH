CREATE TABLE [odins].[FACT_Продажи] (
    [ods_id]   bigint IDENTITY(1,1) Primary key,
    [nkey]              uniqueidentifier NOT NULL,
    [RefID]                            uniqueidentifier,
    [DeletionMark]                                         bit,
    [Number]                                         int,
    [Posted]                                         bit,
    [Date]                                datetime2(0),
    [ДатаОтгрузки]                                datetime2(0),
    [Клиент]                                 varchar(36),
    [ТипДоставки]                                varchar(500),
    [ПримерСоставногоТипа]                                 varchar(36),
    [ПримерСоставногоТипа_ТипЗначения]                                varchar(128),
    [dt_update]     datetime2(4) NOT NULL CONSTRAINT [DF_odins_FACT_Продажи_target_dt_udate_DEFAULT] DEFAULT (getdate()),
    [dt_create]     datetime2(4) NOT NULL CONSTRAINT [DF_odins_FACT_Продажи_target_dt_create_DEFAULT] DEFAULT (getdate())
);
GO
CREATE NONCLUSTERED INDEX [idx_FACT_Продажи_target] ON [odins].[FACT_Продажи]
(
    [RefID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]

GO
