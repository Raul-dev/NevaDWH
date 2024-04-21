CREATE TABLE [dbo].[dwh_processing_details] (
    [processing_id]  BIGINT        IDENTITY (1, 1) NOT NULL,
    [dwh_session_id] BIGINT        NULL,
    [schema_name]    VARCHAR (128) NULL,
    [table_name]     VARCHAR (128) NULL,
    [row_count]      BIGINT        NULL,
    CONSTRAINT [PK_DWH_PROCESSING_DETAILS] PRIMARY KEY CLUSTERED ([processing_id] ASC),
    CONSTRAINT [FK_dwh_processing_details_dwh_session] FOREIGN KEY ([dwh_session_id]) REFERENCES [dbo].[dwh_session] ([dwh_session_id])
);

