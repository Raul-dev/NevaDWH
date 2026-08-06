CREATE TABLE [config].[Setting] (
  [SettingId]  varchar(50)    NOT NULL,
  [StrValue]   nvarchar(256)  NULL,
  CONSTRAINT [PK_config_Setting] PRIMARY KEY NONCLUSTERED ([SettingId] ASC)
);
