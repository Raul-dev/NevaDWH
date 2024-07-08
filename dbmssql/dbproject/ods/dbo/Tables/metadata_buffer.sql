CREATE TABLE [dbo].[metadata_buffer] (
    [buffer_id]      BIGINT        IDENTITY (1, 1) NOT NULL,
    [session_id]     BIGINT        NOT NULL,
    [msg_id]         VARCHAR (36)  NOT NULL,
    [msg]            VARCHAR (MAX) NULL,
    [msg_key]        VARCHAR (256) NULL,
    [metaadapter_id] TINYINT       NULL,
    [is_error]       BIT           CONSTRAINT [DF_metadata_buffer_is_error_DEFAULT] DEFAULT ((0)) NOT NULL,
    [dt_create]      DATETIME2 (4) CONSTRAINT [DF_metadata_buffer_dt_update_DEFAULT] DEFAULT (getdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([buffer_id] ASC)
);



