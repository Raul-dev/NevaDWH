CREATE TABLE [mq].[DataSource] (
  [DataSourceId]  tinyint       NOT NULL,
  [Name]          varchar(100)  COLLATE Cyrillic_General_CI_AS NULL,
  CONSTRAINT [PK_mq_DataSource] PRIMARY KEY CLUSTERED ([DataSourceId] ASC)
);
