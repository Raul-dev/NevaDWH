CREATE TABLE [mq].[MetaDataBuffer] (
  [BufferId]       bigint        identity(1,1) NOT NULL,
  [SessionId]      bigint        NOT NULL,
  [MessageId]      varchar(36)   NOT NULL,
  [MessageBody]    varchar(max)  NULL,
  [MessageKey]     varchar(256)  NULL,
  [MetaAdapterId]  tinyint       NULL,
  [IsError]        bit           CONSTRAINT [DF_mq_MetaDataBuffer_IsError] DEFAULT ((0)) NOT NULL,
  [CreatedAt]      datetime2(4)  CONSTRAINT [DF_mq_MetaDataBuffer_CreatedAt] DEFAULT (sysdatetime()) NOT NULL,
  [UpdatedAt]      datetime2(4)  CONSTRAINT [DF_mq_MetaDataBuffer_UpdatedAt] DEFAULT ([mq].[fn_GetMinDate]()) NOT NULL,
  CONSTRAINT [PK_mq_MetaDataBuffer] PRIMARY KEY CLUSTERED ([BufferId] ASC)
);
