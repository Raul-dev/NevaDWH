CREATE TABLE [dbo].[metamap] (
    [metamap_id]     SMALLINT       NOT NULL,
    [msg_key]        NVARCHAR (256) NOT NULL,
    [table_name]     NVARCHAR (128) NOT NULL,
    [metaadapter_id] TINYINT        NULL,
    [namespace]      NVARCHAR (256) NULL,
    [namespace_ver]  NVARCHAR (256) NULL,
    [etl_query]      NVARCHAR (256) NULL,
    [import_query]   NVARCHAR (256) NULL,
    [is_enable]      BIT            NOT NULL,
    CONSTRAINT [PK_metamap] PRIMARY KEY CLUSTERED ([metamap_id] ASC)
);
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_metamap] ON [dbo].[metamap]
(
    [namespace] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

