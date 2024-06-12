-------------------------------------------------------------------------------------------
---------------------Задание 1. Получение метрик

select  
    client_id,
case when "action" ='visit' then hitdatetime  else NULL end as visit_dt,
case when "action" ='registration' then 1 else 0 end as is_registration
from user_activity_log
limit 10




-------------------------------------------------------------------------------------------
---------------------Задание 2. Агрегация метрик
Выгрузите первые 10 записей, в которых для каждого пользователя содержится:
client_id — идентификатор клиента;
fst_visit_dt — дата первого посещения сайта;
registration_dt — дата регистрации. Если таких событий несколько, возьмите самое раннее;
is_registration — флаг регистрации ( 1, если пользователь когда-либо зарегистрировался, и 0 иначе).
Приведите колонки с датами к типу DATE.


WITH ranked_activity AS (
    SELECT  
        client_id,
        hitdatetime,
        first_value( cast(hitdatetime as date)) OVER (PARTITION BY client_id) AS first_hitdatetime,
        CASE 
            WHEN "action" = 'visit' THEN cast(hitdatetime as date)
            ELSE NULL 
        END AS visit_dt,
        CASE 
            WHEN "action" = 'registration' THEN cast(hitdatetime as date)
            ELSE NULL 
        END AS registration_dt,
        CASE 
            WHEN "action" = 'registration' THEN 1 
            ELSE 0 
        END AS is_registration,
        ROW_NUMBER() OVER (PARTITION BY client_id ORDER BY hitdatetime) AS rn
    FROM 
        user_activity_log
)
SELECT 
    client_id,
    first_hitdatetime as fst_visit_dt,
   registration_dt,
    is_registration
FROM 
    ranked_activity
WHERE 
    rn = 1
LIMIT 10;

-------------------------------------------------------------------------------------------
---------------------Задание 3. Объединение данных
Помимо данных по посещению и регистрации, в витрине необходима также информация о платежах 
и о маркетинговой кампании, чтобы проанализировать оборот. 
Для этого нужно объединить данные из нескольких таблиц.
Соберите все данные в витрину с полями:
client_id — идентификатор клиента;
utm_campaign — маркетинговая кампания;
fst_visit_dt — дата первого посещения сайта;
registration_dt — дата регистрации клиента;
is_registration — 1, если клиент регистрировался, 0 иначе;
total_payment_amount — сумма платежей клиента.
Используйте подзапросы.



-- Поменяйте этот код
SELECT client_id,
       DATE(MIN(CASE WHEN action = 'visit' THEN hitdatetime ELSE NULL END)) AS fst_visit_dt,
       DATE(MIN(CASE WHEN action = 'registration' THEN hitdatetime ELSE NULL END)) AS registration_dt,
       MAX(CASE WHEN action = 'registration' THEN 1 ELSE 0 END) AS is_registration
FROM user_activity_log
GROUP BY client_id
LIMIT 10;








WITH user_payment_log AS (
  SELECT
    upl.client_id,
    SUM(upl.payment_amount) AS total_payment_amount
  FROM user_payment_log upl
  GROUP BY upl.client_id
)


select  
       ual.client_id, 
       ua.utm_campaign,
       DATE(MIN(CASE WHEN ual.action = 'visit' THEN ual.hitdatetime ELSE NULL END)) AS fst_visit_dt,
       DATE(MIN(CASE WHEN ual.action = 'registration' THEN ual.hitdatetime ELSE NULL END)) AS registration_dt,
       MAX(CASE WHEN ual.action = 'registration' THEN 1 ELSE 0 END) AS is_registration,
       sum(upl.payment_amount)  as total_payment_amount
FROM user_activity_log ual
join user_attributes ua
	on ual.client_id = ua.client_id 
join user_payment_log upl
	on ual.client_id = upl.client_id 
group by ual.client_id, 
       ua.utm_campaign
LIMIT 10;



-------------------------------------------------------------------------------------------
---------------------Задание 4. Упрощение запроса
SELECT ua.client_id,
       ua.utm_campaign,
       ual.fst_visit_dt,
       ual.registration_dt,
       ual.is_registration,
       upl.total_payment_amount
FROM user_attributes AS ua
LEFT JOIN (
       SELECT client_id,
              DATE(MIN(CASE WHEN action = 'visit' THEN hitdatetime ELSE NULL END)) AS fst_visit_dt,
              DATE(MIN(CASE WHEN action = 'registration' THEN hitdatetime ELSE NULL END)) AS registration_dt,
              MAX(CASE WHEN action = 'registration' THEN 1 ELSE 0 END) AS is_registration
       FROM user_activity_log
       GROUP BY client_id
) AS ual
ON ua.client_id = ual.client_id
LEFT JOIN (
       SELECT client_id,
              SUM(payment_amount) AS total_payment_amount
       FROM user_payment_log
       GROUP BY client_id
) AS upl
ON ua.client_id = upl.client_id;




WITH user_payment_log AS (
  SELECT
    upl.client_id,
    SUM(upl.payment_amount) AS total_payment_amount
  FROM user_payment_log upl
  GROUP BY upl.client_id
)
select  
       ual.client_id, 
       ua.utm_campaign,
       DATE(MIN(CASE WHEN ual.action = 'visit' THEN ual.hitdatetime ELSE NULL END)) AS fst_visit_dt,
       DATE(MIN(CASE WHEN ual.action = 'registration' THEN ual.hitdatetime ELSE NULL END)) AS registration_dt,
       MAX(CASE WHEN ual.action = 'registration' THEN 1 ELSE 0 END) AS is_registration,
       upl.total_payment_amount
FROM user_activity_log ual
join user_attributes ua
	on ual.client_id = ua.client_id 
join user_payment_log upl
	on ual.client_id = upl.client_id 
group by ual.client_id, 
       ua.utm_campaign
LIMIT 10;



WITH user_payment_log AS (
  SELECT
    upl.client_id,
       DATE(MIN(CASE WHEN ual.action = 'visit' THEN ual.hitdatetime ELSE NULL END)) AS fst_visit_dt,
       DATE(MIN(CASE WHEN ual.action = 'registration' THEN ual.hitdatetime ELSE NULL END)) AS registration_dt,
       MAX(CASE WHEN ual.action = 'registration' THEN 1 ELSE 0 END) AS is_registration,
    SUM(upl.payment_amount) AS total_payment_amount
  FROM user_payment_log upl
  join user_activity_log ual
	on ual.client_id = upl.client_id 
  GROUP BY upl.client_id
)
select  
	upl.client_id, 
    ua.utm_campaign,
    upl.fst_visit_dt,
    upl.registration_dt,
    upl.is_registration,
    upl.total_payment_amount
FROM user_attributes ua
join user_payment_log upl
	on ua.client_id = upl.client_id 
LIMIT 10;


