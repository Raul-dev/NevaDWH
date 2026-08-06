CREATE TABLE [mq].[Session] (
  [SessionId]       bigint         identity(1,1) NOT NULL,
  [DataSourceId]    tinyint        NOT NULL,
  [SessionStateId]  tinyint        NOT NULL,
  [ErrorMessage]    varchar(4000)  NULL,
  [UpdatedAt]       datetime2(4)   CONSTRAINT [DF_mq_Session_UpdatedAt] DEFAULT (sysdatetime()) NOT NULL,
  [CreatedAt]       datetime2(4)   CONSTRAINT [DF_mq_Session_CreatedAt] DEFAULT (sysdatetime()) NOT NULL,
  CONSTRAINT [PK_mq_Session] PRIMARY KEY CLUSTERED ([SessionId] ASC),
  CONSTRAINT [FK_mq_Session_DataSource] FOREIGN KEY ([DataSourceId]) REFERENCES [mq].[DataSource] ([DataSourceId]),
  CONSTRAINT [FK_mq_Session_SessionState] FOREIGN KEY ([SessionStateId]) REFERENCES [mq].[SessionState] ([SessionStateId])
);
