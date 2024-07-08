CREATE TABLE [dbo].[metadata] (
    [nkey]           UNIQUEIDENTIFIER NOT NULL,
    [namespace]      NVARCHAR (256)   NOT NULL,
    [namespace_ver]  NVARCHAR (256)   NOT NULL,
    [msg]            NVARCHAR (MAX)   NULL,
    [metaadapter_id] TINYINT          NULL,
    [dt_create]      DATETIME2 (2)    DEFAULT (getdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([nkey] ASC)
);



