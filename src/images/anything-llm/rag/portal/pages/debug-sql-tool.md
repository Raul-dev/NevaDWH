---
workspace: portal-helper
route: /debug-sql/
title: "Debug SQL"
description: "Добавление audit-обёрток к тексту CREATE/ALTER PROCEDURE"
source: nevadwh-astro
---

# Debug SQL

> Добавление audit-обёрток к тексту CREATE/ALTER PROCEDURE

Канонический URL на портале: /debug-sql/

# Debug SQL



Вставьте текст `CREATE`/`CREATE OR ALTER`/`ALTER PROCEDURE` — API `ApplyProcLog` вернёт процедуру с audit-логированием (`sp_LogStart` / `sp_LogFinish`).



Проект audit-базы и утилита применения аудита к процедурам: [Moex_CGate / ProcDebug](https://github.com/Raul-dev/Moex_CGate/tree/main/src/ProcDebug).



    
      
        
          Процедура SQL
        
        
          С audit
        
      

      
        

_(поле ввода MetaData — содержимое примера опущено в RAG)_



          
            
              Сгенерировать SQL
            

            
              
              Оборачивать RETURN
            
          
        

        

_(поле ввода MetaData — содержимое примера опущено в RAG)_
