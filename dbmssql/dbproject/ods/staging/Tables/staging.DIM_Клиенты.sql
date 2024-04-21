CREATE TABLE [staging].[DIM_Клиенты] (
    [id]         bigint IDENTITY(1,1) Primary key,
    [nkey]       uniqueidentifier NOT NULL,
    [RefID] uniqueidentifier,
    [DeletionMark] bit,
    [Code] varchar(128),
    [Description] varchar(128),
    [Контакт] varchar(500),
    [dt_update] datetime2(4)
);
GO
