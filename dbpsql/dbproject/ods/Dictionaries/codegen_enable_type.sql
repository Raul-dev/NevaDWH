do
$$
BEGIN
RAISE NOTICE 'Fill codegen_enable_type ';
END;
$$;


CREATE TEMPORARY TABLE IF NOT EXISTS tmp_codegen_enable_type 
(
    codegen_enable_type_id smallint,
    "description" VARCHAR(100)
);


INSERT INTO tmp_codegen_enable_type (codegen_enable_type_id, "description") VALUES
(0, 'Исключить из проекта ODS'),
(1, 'Генерировать код ODS если файлы отсутствуют'),
(2, 'Генерировать только ODS таблицы всегда , процедуры только если отсутствуют'),
(3, 'Генерировать код ODS');



UPDATE codegen_enable_type as c
SET description = t.description
FROM tmp_codegen_enable_type as t
WHERE c.codegen_enable_type_id = t.codegen_enable_type_id;

INSERT INTO codegen_enable_type (codegen_enable_type_id, description)
SELECT * FROM tmp_codegen_enable_type t
WHERE  NOT t.codegen_enable_type_id in (SELECT codegen_enable_type_id FROM codegen_enable_type c);

DROP TABLE tmp_codegen_enable_type;

