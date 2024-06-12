------------------------------------------------------------------------------------------------------
-----------Задание 1. Тренируемся создавать представление


CREATE OR REPLACE VIEW client_activity AS 
WITH i AS (
    SELECT customer_id, 
           DATE_TRUNC('month', CAST(invoice_date AS timestamp)) AS invoice_month, 
           total 
    FROM invoice
)
SELECT i.customer_id,
       client.company IS NOT NULL AS is_from_company,
       i.invoice_month,
       COUNT(i.total),
       SUM(i.total)
FROM i
LEFT JOIN client
ON i.customer_id = client.customer_id
GROUP BY i.customer_id, i.invoice_month, client.company;

------------------------------------------------------------------------------------------------------
-----------Задание 2. Проверка запроса
Запрос в представлении должен каждый раз выполняться заново. Проверьте это.
Выведите все записи из представления за июнь 2021 года.
Добавьте такую запись:

INSERT INTO invoice (customer_id, invoice_date, total)
VALUES (9, DATE '2021-06-01', 2); 


select *
from client_activity
where customer_id = 9

------------------------------------------------------------------------------------------------------
-----------Задание 3. Обновление представления
Аналитик просит обновить представление: в нём должны быть только клиенты с суммой заказов за месяц больше 1. 
Перепишите код из первого задания так, чтобы заменить представление новым с таким же именем, не удаляя предыдущего.
Введите ниже секретный ключ, который вы получили после выполнения этого задания в Docker-тренажёре.


CREATE OR REPLACE VIEW client_activity AS (
WITH i AS (
    SELECT customer_id, 
           DATE_TRUNC('month', CAST(invoice_date AS timestamp)) AS invoice_month, 
           total 
    FROM invoice
)

SELECT i.customer_id,
       client.company IS NOT NULL AS is_from_company,
       i.invoice_month,
       COUNT(i.total),
       SUM(i.total)
FROM i
LEFT JOIN client
ON i.customer_id = client.customer_id
GROUP BY i.customer_id, i.invoice_month, client.company
having SUM(i.total)>1
);

------------------------------------------------------------------------------------------------------
-----------Задание 4. Материализованное представление
Сейчас при каждом обращении к client_activity запрос выполняется заново. 
Чтобы результаты закэшировались, переделайте его в материализованное 
представление с тем же именем.

DROP VIEW IF exists client_activity;

CREATE MATERIALIZED VIEW client_activity AS
WITH i AS (
    SELECT customer_id, 
           DATE_TRUNC('month', CAST(invoice_date AS timestamp)) AS invoice_month, 
           total 
    FROM invoice
)
SELECT i.customer_id,
       client.company IS NOT NULL AS is_from_company,
       i.invoice_month,
       COUNT(i.total),
       SUM(i.total)
FROM i
LEFT JOIN client ON i.customer_id = client.customer_id
GROUP BY i.customer_id, i.invoice_month, client.company
HAVING SUM(i.total) > 1;

------------------------------------------------------------------------------------------------------
-----------Задание 5. Проверка запроса к материализованному представлению
Даже если сейчас исходные таблицы обновятся, эти данные в представлении не появятся. Проверьте, что запрос к материализованному представлению действительно не выполняется.
Выведите все записи из client_activity за май 2021 года.
Добавьте такую запись:

DROP MATERIALIZED VIEW IF exists client_activity;

CREATE MATERIALIZED VIEW client_activity AS
WITH i AS (
    SELECT customer_id, 
           DATE_TRUNC('month', CAST(invoice_date AS date)) AS invoice_month, 
           total 
    FROM invoice
)
SELECT i.customer_id,
       client.company IS NOT NULL AS is_from_company,
       i.invoice_month,
       COUNT(i.total),
       SUM(i.total)
FROM i
LEFT JOIN client ON i.customer_id = client.customer_id
GROUP BY i.customer_id, i.invoice_month, client.company
HAVING SUM(i.total) > 1;


INSERT INTO invoice (customer_id, invoice_date, total)
VALUES (9, DATE '2021-05-01', 2);
------------------------------------------------------------------------------------------------------
-----------Задание 6. Последние штрихи
Чтобы новая запись появилась в представлении, обновите его. Затем снова выведите все записи за май 2021 года.

REFRESH MATERIALIZED VIEW client_activity;

SELECT *
FROM client_activity
WHERE invoice_month >= '2021-05-01' AND invoice_month < '2021-06-01';

------------------------------------------------------------------------------------------------------
-----------Задание 7. Представление для заказчика
Создайте материализованное представление user_activity_payment_datamart из запроса построения витрины.


CREATE MATERIALIZED VIEW user_activity_payment_datamart as
WITH ual AS (
	SELECT client_id,
				 DATE(MIN(CASE WHEN action = 'visit' THEN hitdatetime ELSE NULL END)) AS fst_visit_dt,
				 DATE(MIN(CASE WHEN action = 'registration' THEN hitdatetime ELSE NULL END)) AS registration_dt,
				 MAX(CASE WHEN action = 'registration' THEN 1 ELSE 0 END) AS is_registration
	FROM user_activity_log
	GROUP BY client_id
),

upl AS (
  SELECT client_id,
			   SUM(payment_amount) AS total_payment_amount
  FROM user_payment_log
	GROUP BY client_id
)
SELECT ua.client_id,
       ua.utm_campaign,
       ual.fst_visit_dt,
       ual.registration_dt,
       ual.is_registration,
       upl.total_payment_amount
FROM user_attributes AS ua
LEFT JOIN ual ON ua.client_id = ual.client_id
LEFT JOIN upl ON ua.client_id = upl.client_id
;


