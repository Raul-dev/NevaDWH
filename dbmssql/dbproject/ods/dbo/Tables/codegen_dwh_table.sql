CREATE TABLE [dbo].[codegen_dwh_table] (
    [codegen_dwh_table_id]  INT           NOT NULL,
    [codegen_id]            INT           NOT NULL,
    [table_name]            VARCHAR (128) COLLATE Cyrillic_General_CI_AS NOT NULL,
    [is_root]               BIT           NOT NULL,
    [is_enable]             BIT           NOT NULL,
    [dwh_table_name]        VARCHAR (128) COLLATE Cyrillic_General_CI_AS NOT NULL,
    [is_vkey_session]       BIT           CONSTRAINT [DF_codegen_dwh_column_is_vkey_session_DEFAULT] DEFAULT ((0)) NOT NULL,
    [is_vkey_sourcename]    BIT           CONSTRAINT [DF_codegen_dwh_column_is_vkey_sourcename_DEFAULT] DEFAULT ((0)) NOT NULL,
    [is_historical]         BIT           CONSTRAINT [DF_codegen_dwh_column_is_historical_DEFAULT] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_codegen_dwh_table] PRIMARY KEY CLUSTERED ([codegen_dwh_table_id] ASC),
    CONSTRAINT [FK_codegen_dwh_table_codegen] FOREIGN KEY ([codegen_id]) REFERENCES [dbo].[codegen] ([codegen_id])
);

