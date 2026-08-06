CREATE TABLE [mq].[FileQueue] (
  [FileQueueId]   bigint            identity(1,1) NOT NULL,
  [SessionId]     bigint            NOT NULL,
  [MessageKey]    nvarchar(256)     NOT NULL,
  [MessageId]     uniqueidentifier  NULL,
  [StartDate]     datetime2(4)      NULL,
  [FinishDate]    datetime2(4)      NULL,
  [FileName]      varchar(4000)     NULL,
  [FileFolder]    varchar(4000)     NULL,
  [FileType]      varchar(4)        NULL,
  [ErrorMessage]  varchar(4000)     NULL,
  [StateId]       tinyint           NOT NULL,
  [CreatedAt]     datetime2(4)      CONSTRAINT [DF_mq_FileQueue_CreatedAt] DEFAULT (sysdatetime()) NOT NULL,
  [UpdatedAt]     datetime2(4)      CONSTRAINT [DF_mq_FileQueue_UpdatedAt] DEFAULT (sysdatetime()) NOT NULL,
  CONSTRAINT [PK_mq_FileQueue] PRIMARY KEY CLUSTERED ([MessageKey] ASC, [FileQueueId] ASC) ON [filequeueRange] ([MessageKey])
) ON [filequeueRange] ([MessageKey]);
