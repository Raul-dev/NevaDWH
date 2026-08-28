---
workspace: portal-helper
route: /generator/
title: "Генератор SQL"
description: "Генерация SQL из MetaDataObject 1С (XML/JSON)"
source: nevadwh-astro
---

# Генератор SQL

> Генерация SQL из MetaDataObject 1С (XML/JSON)

Канонический URL на портале: /generator/

# Генератор SQL



Xml MetaDataObject 1С можно получить в панели администратора или командой `1cv8.exe /DumpConfigToFiles`. Ниже — пример самодельного объекта `DocumentObject.Продажи`.



    
      
        
          MetaData 1C (xml/json)
        
        
          Скрипт SQL
        
      

      
        

_(поле ввода MetaData — содержимое примера опущено в RAG)_



          
            
              Сгенерировать SQL
            

            
              СУБД
              
                MS SQL
                Postgres
                Oracle
                ClickHouse
              
            

            
              Метод
              
                Tables
                Procedures
                MetaData
              
            
          
        

        

_(поле ввода MetaData — содержимое примера опущено в RAG)_
