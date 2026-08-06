CREATE TABLE [etl].[Setting] (
    [SettingId] VARCHAR (50)   NOT NULL,
    [StrValue]  NVARCHAR (256) NULL,
    CONSTRAINT [PK_etl_Setting] PRIMARY KEY NONCLUSTERED ([SettingId] ASC)
);
