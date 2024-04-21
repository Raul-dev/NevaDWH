CREATE TABLE [dbo].[codegen_enable_type] (
    [codegen_enable_type_id]  SMALLINT            NOT NULL,
    [description]   NVARCHAR (256) COLLATE Cyrillic_General_CI_AS NOT NULL
    CONSTRAINT [PK_codegen_enable_type] PRIMARY KEY CLUSTERED ([codegen_enable_type_id] ASC)
);
