CREATE TABLE [dbo].[codegen_dwh_column] (
    [codegen_dwh_column_id] INT           NOT NULL,
    [codegen_dwh_table_id]  INT           NOT NULL,
    [column_name]           VARCHAR (128) NOT NULL,
    [data_type]             VARCHAR (128) NOT NULL,
    [text_length]           INT           NULL,
    [precision]             INT           NULL,
    [scale]                 INT           NULL,
    [is_enable]             BIT           CONSTRAINT [DF_codegen_dwh_column_is_enable_DEFAULT] DEFAULT ((1)) NOT NULL,
    [is_versionkey]         BIT           CONSTRAINT [DF_codegen_dwh_column_is_versionkey_DEFAULT] DEFAULT ((0)) NOT NULL,
    [is_nulable]            BIT           CONSTRAINT [DF_codegen_dwh_column_is_nulable_DEFAULT] DEFAULT ((1)) NOT NULL,
    [null_value]            VARCHAR (128) NULL,
    CONSTRAINT [PK_codegen_dwh_column] PRIMARY KEY CLUSTERED ([codegen_dwh_column_id] ASC),
    CONSTRAINT [FK_codegen_dwh_column_codegen_dwh_table] FOREIGN KEY ([codegen_dwh_table_id]) REFERENCES [dbo].[codegen_dwh_table] ([codegen_dwh_table_id])
);



