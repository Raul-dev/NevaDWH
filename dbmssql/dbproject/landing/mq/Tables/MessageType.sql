CREATE TABLE [mq].[MessageType] (
  [MessageTypeId]  tinyint       NOT NULL,
  [Name]           varchar(100)  NOT NULL,
  CONSTRAINT [PK_mq_MessageType] PRIMARY KEY CLUSTERED ([MessageTypeId] ASC)
);
