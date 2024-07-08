﻿CREATE TABLE [dbo].[metadata_sql]
(
    [id] [bigint] NOT NULL PRIMARY KEY,
     [guid] [uniqueidentifier] NULL,
    [column_order] int not null,
    [s_schema_type] nvarchar(128)  NOT NULL,
    [s_table_name] nvarchar(128)  NOT NULL,
    [s_column_name] nvarchar(128)  NOT NULL,
    [s_data_type] nvarchar(128)  NOT NULL,
    [s_text_length] nvarchar(128)  NULL,
    [s_precision] nvarchar(128)  NULL,
    [s_scale] nvarchar(128)  NULL,
    [s_is_nkey] [bit] NOT NULL,
    [t_star_name] nvarchar(128)  NOT NULL,
    [t_table_name] nvarchar(128)  NULL,
    [t_column_name] nvarchar(128)  NULL,
    [t_data_type] nvarchar(128)  NULL,
    [t_text_length] nvarchar(128)  NULL,
    [t_precision] nvarchar(128)  NULL,
    [t_scale] nvarchar(128)  NULL,
    [t_is_nkey] [bit] NOT NULL,
    [t_is_fkey] [bit] NOT NULL,
    [t_is_present] [bit] NOT NULL,
    [t_is_vkey] [bit] NOT NULL,
    [t_history_type] nvarchar(100)  NULL,
    [t_is_aggr] [bit] NOT NULL,
    [t_aggr_type] nvarchar(100) NULL,
    [description] nvarchar(4000)  NULL
) ON [PRIMARY]