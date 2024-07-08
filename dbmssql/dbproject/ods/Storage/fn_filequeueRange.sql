CREATE PARTITION FUNCTION [fn_filequeueRange](NVARCHAR (256))
    AS RANGE RIGHT
    FOR VALUES (N'Документы.', N'Документы.Продажи', N'Справочники.');

