CREATE TABLE [odins].[DIM_Валюты.Представления] (
    [OdsId]                       bigint IDENTITY(1,1) Primary key,
    [NKey]                        uniqueidentifier NOT NULL,
    [DIM_ВалютыRefID]             uniqueidentifier,
    [КодЯзыка]                    varchar(10),
    [ПараметрыПрописи]            varchar(200),
    [UpdatedAt]                   datetime2(4) NOT NULL CONSTRAINT [DF_odins_DIM_Валюты.Представления_UpdatedAt] DEFAULT (GetDate()),
    [CreatedAt]                   datetime2(4) NOT NULL CONSTRAINT [DF_odins_DIM_Валюты.Представления_CreatedAt] DEFAULT (GetDate())
);

GO
CREATE NONCLUSTERED INDEX [idx_DIM_Валюты.Представления_target] ON [odins].[DIM_Валюты.Представления]
(
    [DIM_ВалютыRefID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]

GO
