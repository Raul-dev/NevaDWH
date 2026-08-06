CREATE TABLE [mq].[MessageQueue] (
  [BufferId]     bigint            identity(1,1) NOT NULL,
  [SessionId]    bigint            NOT NULL,
  [MessageId]    uniqueidentifier  NULL,
  [MessageBody]  nvarchar(max)     NULL,
  [MessageKey]   nvarchar(256)     NULL,
  [CreatedAt]    datetime2(4)      CONSTRAINT [DF_mq_MessageQueue_CreatedAt] DEFAULT (sysdatetime()) NOT NULL,
  CONSTRAINT [PK_mq_MessageQueue] PRIMARY KEY CLUSTERED ([BufferId] ASC)
);
