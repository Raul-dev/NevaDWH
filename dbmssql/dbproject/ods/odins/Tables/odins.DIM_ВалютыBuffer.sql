CREATE TABLE [odins].[DIM_ВалютыBuffer] (
  [BufferId]        bigint IDENTITY(1,1),
  [SessionId]       bigint            NOT NULL,
  [MessageId]       uniqueidentifier  NOT NULL,
  [MessageBody]     xml               NULL,
  [IsError]         bit               NOT NULL CONSTRAINT [DF_odins_DIM_ВалютыBuffer_IsError] DEFAULT 0,
  [MessageTypeId]   tinyint           CONSTRAINT [DF_odins_DIM_ВалютыBuffer_MessageTypeId] DEFAULT ((1)) NOT NULL,
  [CreatedAt]       datetime2(4)      NOT NULL CONSTRAINT [DF_odins_DIM_ВалютыBuffer_CreatedAt] DEFAULT (GetDate()),
  [UpdatedAt]       datetime2(4)      NOT NULL CONSTRAINT [DF_odins_DIM_ВалютыBuffer_UpdatedAt] DEFAULT ([mq].[fn_GetMinDate]()),
  [RefID] AS ([mq].[fn_GetRef]([MessageBody],'CatalogObject.Валюты')),
  CONSTRAINT [PK_odins_DIM_ВалютыBuffer] PRIMARY KEY CLUSTERED
  (
    [BufferId] ASC
  )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = ON) ON [PRIMARY]
);

GO

