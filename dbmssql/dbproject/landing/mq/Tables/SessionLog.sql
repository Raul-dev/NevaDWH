CREATE TABLE [mq].[SessionLog] (
  [SessionLogId]    bigint         identity(1,1) NOT NULL,
  [SessionId]       bigint         NOT NULL,
  [SessionStateId]  tinyint        NOT NULL,
  [ErrorMessage]    varchar(4000)  NULL,
  [CreatedAt]       datetime2(4)   CONSTRAINT [DF_mq_SessionLog_CreatedAt] DEFAULT (sysdatetime()) NOT NULL,
  CONSTRAINT [PK_mq_SessionLog] PRIMARY KEY CLUSTERED ([SessionLogId] ASC),
  CONSTRAINT [FK_mq_SessionLog_Session] FOREIGN KEY ([SessionId]) REFERENCES [mq].[Session] ([SessionId]),
  CONSTRAINT [FK_mq_SessionLog_SessionState] FOREIGN KEY ([SessionStateId]) REFERENCES [mq].[SessionState] ([SessionStateId])
);
