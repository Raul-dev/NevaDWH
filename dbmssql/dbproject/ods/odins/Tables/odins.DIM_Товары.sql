CREATE TABLE [odins].[DIM_Товары] (
    [OdsId]                       bigint IDENTITY(1,1) Primary key,
    [NKey]                        uniqueidentifier NOT NULL,
    [RefID]                       uniqueidentifier,
    [DeletionMark]                bit,
    [Code]                        varchar(128),
    [Description]                 varchar(128),
    [Описание]                    varchar(255),
    [UpdatedAt]                   datetime2(4) NOT NULL CONSTRAINT [DF_odins_DIM_Товары_UpdatedAt] DEFAULT (GetDate()),
    [CreatedAt]                   datetime2(4) NOT NULL CONSTRAINT [DF_odins_DIM_Товары_CreatedAt] DEFAULT (GetDate())
);

GO
CREATE NONCLUSTERED INDEX [idx_DIM_Товары_target] ON [odins].[DIM_Товары]
(
    [RefID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]

GO
