IF NOT EXISTS(SELECT 1 FROM [config].[Setting] WHERE SettingId = 'AuditProcAll')
  INSERT INTO [config].[Setting] (SettingId, StrValue) VALUES ('AuditProcAll', N'AuditProcAll')

-- StrValue для AuditProcAll: AuditProcAll (локально), AuditProcAllLnk (central Log DB), NULL/'' (выкл.)
IF NOT EXISTS(SELECT 1 FROM [audit].[AuditTypeSP])
  INSERT [audit].[AuditTypeSP] ([AuditTypeID], [Code], [Description])
  VALUES
    (1, N'LocalTable', N'Локальный audit через LinkSRVLogLanding (autonomous)'),
    (2, N'LinkedServer', N'Central Log DB через LinkSRVLog (autonomous)')
