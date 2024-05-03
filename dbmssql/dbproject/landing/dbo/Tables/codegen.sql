CREATE TABLE [dbo].[codegen] (
    [codegen_id] int NOT NULL,
    [namespace] nvarchar(256) COLLATE Cyrillic_General_CI_AS NOT NULL,
    [schema] nvarchar(128) COLLATE Cyrillic_General_CI_AS NOT NULL,
    [table_name] nvarchar(128) COLLATE Cyrillic_General_CI_AS NOT NULL,
    [ods_enable_type] smallint NULL,
    [dwh_enable_type] smallint NULL,
    [landing_enable_type] smallint NULL,
    CONSTRAINT [PK_codegen] PRIMARY KEY CLUSTERED ([codegen_id] ASC),
    CONSTRAINT [FK_codegen_enable_type] FOREIGN KEY ([ods_enable_type]) REFERENCES [dbo].[codegen_enable_type] ([codegen_enable_type_id])
);

