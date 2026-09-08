IF NOT EXISTS(SELECT 1 FROM [audit].[AuditTypeSP])
  INSERT [audit].[AuditTypeSP] ([AuditTypeID], [Code], [Description])
  VALUES
    (1, N'LocalTable', N'Локальный audit через loopback linked server'),
    (2, N'LinkedServer', N'Central Log DB через LinkSRVLog')
