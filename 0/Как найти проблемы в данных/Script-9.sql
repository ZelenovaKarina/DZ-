---------------------------------------------------------------------------------------------
-------1.
Выясните, в каких из упомянутых выше таблиц присутствуют колонки с возможными значениями NULL. 
Для этого напишите запрос, который вернёт таблицу из трёх колонок: 
Название таблицы.
Название колонки этой таблицы, в которой есть пропущенные значения.
Значения признака NULLABLE — подтверждение того, что в колонке действительно есть пропущенные значения. Все значения должны быть YES.
Чтобы выявить пустые значения, воспользуйтесь информацией из системной таблицы information_schema.columns — так вы получите информацию обо всех колонках.

SELECT 
    table_name, 
    column_name, 
    is_nullable
FROM 
    information_schema.columns
WHERE 
    table_name IN ('user_payment_log', 'user_activity_log', 'user_attributes')
    AND is_nullable = 'YES';
---------------------------------------------------------------------------------------------
-------2.
Посчитайте, сколько всего записей в каждой таблице. 
Запрос должен вернуть два столбца — столбец с названиями таблиц и столбец с количеством строк. Названию таблицы должно соответствовать число строк в ней.
Используйте префикс ecomm_marketing перед названием таблицы, к данным которой хотите получить доступ. Пример обращения к таблице:  ecomm_marketing.table_name.


SELECT 'user_payment_log',
(SELECT count(1) from user_payment_log) 
UNION ALL
SELECT 'user_activity_log',
(SELECT count(1) from user_activity_log)
UNION ALL
SELECT 'user_attributes',
(SELECT count(1) from user_attributes)
UNION ALL
SELECT 'ecomm_marketing.user_payment_log' AS table_name,
       (SELECT count(*) FROM user_payment_log) AS row_count
UNION ALL
SELECT 'ecomm_marketing.user_activity_log' AS table_name,
       (SELECT count(*) FROM user_activity_log) AS row_count
UNION ALL
SELECT 'ecomm_marketing.user_attributes' AS table_name,
       (SELECT count(*) FROM user_attributes) AS row_count;


