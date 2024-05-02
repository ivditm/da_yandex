/*Найдите количество вопросов, которые набрали больше 300 очков или как минимум 100 раз были добавлены в «Закладки».*/
SELECT COUNT(DISTINCT id)
FROM stackoverflow.posts
WHERE post_type_id = 1 AND (score > 300 OR favorites_count >= 100)


/*
Сколько в среднем в день задавали вопросов с 1 по 18 ноября 2008 включительно? 
Результат округлите до целого числа.*/
SELECT ROUND(AVG(total_per_d)) 
FROM ( 
    SELECT COUNT(*) AS total_per_d 
    FROM stackoverflow.posts 
    WHERE creation_date::date BETWEEN '2008-11-1' AND '2008-11-18' AND post_type_id = 1 
    GROUP BY creation_date::date 
) AS avg_days


/*Сколько пользователей получили значки сразу в день регистрации? 
Выведите количество уникальных пользователей.*/
SELECT COUNT(DISTINCT u.id)
FROM stackoverflow.users AS u
LEFT JOIN stackoverflow.badges AS b ON b.user_id = u.id
WHERE u.creation_date::date = b.creation_date::date


/*Сколько уникальных постов пользователя с именем Joel Coehoorn получили хотя бы один голос?*/
SELECT COUNT(DISTINCT p.id)
FROM stackoverflow.posts AS p INNER JOIN stackoverflow.users AS u ON p.user_id = u.id
INNER JOIN stackoverflow.votes AS v ON v.post_id = p.id
WHERE u.display_name = 'Joel Coehoorn'


/*Выгрузите все поля таблицы vote_types. Добавьте к таблице поле rank,
в которое войдут номера записей в обратном порядке.
Таблица должна быть отсортирована по полю id.*/
SELECT *,
       ROW_NUMBER() OVER (ORDER BY id DESC) as rank
FROM stackoverflow.vote_types
ORDER BY rank DESC


/*Отберите 10 пользователей,
которые поставили больше всего голосов типа Close.
Отобразите таблицу из двух полей: идентификатором пользователя и количеством голосов.
Отсортируйте данные сначала по убыванию количества голосов,
 потом по убыванию значения идентификатора пользователя.*/
SELECT user_id,
       COUNT(*) AS total_votes
FROM stackoverflow.users AS u INNER JOIN stackoverflow.votes AS v ON u.id = v.user_id
INNER JOIN stackoverflow.vote_types AS vt ON vt.id = v.vote_type_id
WHERE vt.name = 'Close'
GROUP BY user_id
ORDER BY total_votes DESC, user_id DESC
LIMIT 10


/*Отберите 10 пользователей по количеству значков, полученных в период с 15 ноября по 15 декабря 2008 года включительно.
Отобразите несколько полей:
- идентификатор пользователя;
- число значков;
- место в рейтинге — чем больше значков, тем выше рейтинг.
Пользователям, которые набрали одинаковое количество значков, присвойте одно и то же место в рейтинге.
Отсортируйте записи по количеству значков по убыванию, а затем по возрастанию значения идентификатора пользователя.*/
WITH t_t AS (
    SELECT DISTINCT user_id,
       COUNT(DISTINCT id)
    FROM stackoverflow.badges
    WHERE creation_date::date BETWEEN '15-11-2008' AND '15-12-2008'
    GROUP BY user_id
    ORDER BY count DESC
)
SELECT *, 
       DENSE_RANK() OVER (ORDER BY count DESC)
FROM t_t
LIMIT 10


/*Сколько в среднем очков получает пост каждого пользователя?
Сформируйте таблицу из следующих полей:
- заголовок поста;
- идентификатор пользователя;
- число очков поста;
среднее число очков пользователя за пост, округлённое до целого числа.
Не учитывайте посты без заголовка, а также те, что набрали ноль очков.*/
SELECT title,
       user_id,
       score,
       ROUND(AVG(score) OVER (PARTITION BY user_id))
FROM stackoverflow.posts
WHERE title IS NOT NULL AND score != 0


/*Отобразите заголовки постов, которые были написаны пользователями,
получившими более 1000 значков.
Посты без заголовков не должны попасть в список.*/
WITH t_t AS (
    SELECT DISTINCT user_id,
           COUNT(DISTINCT id)
    FROM stackoverflow.badges
    GROUP BY user_id
)
SELECT title
FROM stackoverflow.posts
WHERE user_id in (
    SELECT user_id
    FROM t_t
    WHERE count > 1000
) AND title IS NOT NULL


/*Напишите запрос, который выгрузит данные о пользователях из США (англ. United States).
Разделите пользователей на три группы в зависимости от количества просмотров их профилей:
- пользователям с числом просмотров больше либо равным 350 присвойте группу 1;
- пользователям с числом просмотров меньше 350, но больше либо равно 100 — группу 2;
- пользователям с числом просмотров меньше 100 — группу 3.
Отобразите в итоговой таблице идентификатор пользователя, количество просмотров профиля и группу.
Пользователи с нулевым количеством просмотров не должны войти в итоговую таблицу.*/
SELECT id,
       views,
       CASE
          WHEN views>=350 THEN 1
          WHEN views<100 THEN 3
          ELSE 2
       END AS group
FROM stackoverflow.users
WHERE location LIKE '%United States%' AND views != 0


/*Дополните предыдущий запрос.
Отобразите лидеров каждой группы — пользователей, которые набрали максимальное число просмотров в своей группе.
Выведите поля с идентификатором пользователя, группой и количеством просмотров.
Отсортируйте таблицу по убыванию просмотров, а затем по возрастанию значения идентификатора.*/
WITH t_t AS (
    SELECT id,
           views,
           CASE
              WHEN views>=350 THEN 1
              WHEN views<100 THEN 3
              ELSE 2
           END AS group_num
    FROM stackoverflow.users
    WHERE location LIKE '%United States%' AND views != 0
),
temp_t AS (
    SELECT *,
           MAX(views) OVER (PARTITION BY group_num) AS max_value_group
    FROM t_t
)
SELECT id, views, group_num
FROM temp_t
WHERE views = max_value_group
ORDER BY views DESC, id;


/*Посчитайте ежедневный прирост новых пользователей в ноябре 2008 года. Сформируйте таблицу с полями:
- номер дня;
- число пользователей, зарегистрированных в этот день;
- сумму пользователей с накоплением.*/
SELECT *,
       SUM(t.cnt_id) OVER (ORDER BY t.days) as nn
FROM (
      SELECT EXTRACT(DAY FROM creation_date::date) AS days,
             COUNT(id) AS cnt_id
      FROM stackoverflow.users
      WHERE creation_date::date BETWEEN '01-11-2008' AND '30-11-2008'
      GROUP BY EXTRACT(DAY FROM creation_date::date)
      ) as t;


/*Для каждого пользователя, который написал хотя бы один пост,
найдите интервал между регистрацией и временем создания первого поста. Отобразите:
- идентификатор пользователя;
- разницу во времени между регистрацией и первым постом.*/
SELECT DISTINCT u.id,
       MIN(p.creation_date) OVER (PARTITION BY p.user_id) - u.creation_date AS diff
FROM stackoverflow.users AS u
JOIN stackoverflow.posts AS p ON p.user_id = u.id


/*
Выведите общую сумму просмотров постов за каждый месяц 2008 года.
Если данных за какой-либо месяц в базе нет, такой месяц можно пропустить.
Результат отсортируйте по убыванию общего количества просмотров.*/
SELECT DATE_TRUNC('month', creation_date::date)::date AS month,
       SUM(views_count) AS total
FROM stackoverflow.posts
GROUP BY month
HAVING SUM(views_count) IS NOT NULL
ORDER BY SUM(views_count) DESC


/*Выведите имена самых активных пользователей,
которые в первый месяц после регистрации (включая день регистрации)
дали больше 100 ответов. Вопросы, которые задавали пользователи,
не учитывайте. 
Для каждого имени пользователя выведите количество уникальных значений user_id. 
Отсортируйте результат по полю с именами в лексикографическом порядке.*/
SELECT u.display_name,
       COUNT(DISTINCT p.user_id)
FROM stackoverflow.posts AS p
JOIN stackoverflow.users AS u ON p.user_id = u.id
WHERE p.post_type_id = 2
AND p.creation_date::date BETWEEN u.creation_date::date
AND (u.creation_date::date + INTERVAL '1 month')
GROUP BY u.display_name
HAVING COUNT(p.id) > 100
ORDER BY u.display_name


/*
Выведите количество постов за 2008 год по месяцам.
Отберите посты от пользователей, которые зарегистрировались 
в сентябре 2008 года и сделали хотя бы один пост в декабре того же года. 
Отсортируйте таблицу по значению месяца по убыванию.*/
SELECT DATE_TRUNC('month', creation_date::date)::date AS month,
       COUNT(DISTINCT id)
FROM stackoverflow.posts
WHERE user_id IN (
    SELECT DISTINCT u.id
    FROM stackoverflow.users AS u
    JOIN stackoverflow.posts AS p ON p.user_id = u.id
    WHERE EXTRACT(MONTH FROM u.creation_date::date) = 9
    AND EXTRACT(MONTH FROM p.creation_date::date) = 12
)
GROUP BY DATE_TRUNC('month', creation_date::date)
ORDER BY month DESC;


/*
Используя данные о постах, выведите несколько полей:
- идентификатор пользователя, который написал пост;
- дата создания поста;
- количество просмотров у текущего поста;
- сумму просмотров постов автора с накоплением.
Данные в таблице должны быть отсортированы по возрастанию идентификаторов пользователей,
а данные об одном и том же пользователе — по возрастанию даты создания поста.*/
SELECT user_id,
       creation_date,
       views_count,
       SUM(views_count) OVER (PARTITION BY user_id ORDER BY creation_date)						
FROM stackoverflow.posts;


/*Сколько в среднем дней в период с 1 по 7 декабря 2008 года включительно пользователи взаимодействовали с платформой?
Для каждого пользователя отберите дни, в которые он или она опубликовали хотя бы один пост.
Нужно получить одно целое число — не забудьте округлить результат.*/
SELECT ROUND(AVG(cnt))
FROM (
    SELECT user_id,
           COUNT(DISTINCT creation_date::date) AS cnt
    FROM stackoverflow.posts
    WHERE creation_date::date BETWEEN '01-12-2008' AND '07-12-2008'
    GROUP BY user_id
) AS t_t


/*На сколько процентов менялось количество постов ежемесячно с 1 сентября по 31 декабря 2008 года?
Отобразите таблицу со следующими полями:
- номер месяца;
- количество постов за месяц;
- процент, который показывает, насколько изменилось количество постов в текущем месяце по сравнению с предыдущим.
Если постов стало меньше, значение процента должно быть отрицательным,
если больше — положительным. Округлите значение процента до двух знаков после запятой.*/
WITH t_t AS (
    SELECT EXTRACT(MONTH FROM creation_date::date) AS month,
           COUNT(DISTINCT id) AS cnt
    FROM stackoverflow.posts
    WHERE creation_date::date BETWEEN '01-09-2008' AND '31-12-2008'
    GROUP BY month
)
SELECT *,
       ROUND(((cnt::numeric / LAG(cnt) OVER (ORDER BY month)) - 1) * 100,2) AS user_growth
FROM t_t


/*
Выгрузите данные активности пользователя, который опубликовал больше всего постов за всё время.
Выведите данные за октябрь 2008 года в таком виде:
- номер недели;
- дата и время последнего поста, опубликованного на этой неделе.*/
WITH t_t AS (
    SELECT DISTINCT user_id,
           COUNT(DISTINCT id) AS cnt
    FROM stackoverflow.posts
    GROUP BY user_id
    ORDER BY cnt DESC
    LIMIT 1
),
temp_t AS (
    SELECT creation_date,
           EXTRACT('week' FROM creation_date::date) AS week
    FROM stackoverflow.posts
    WHERE user_id IN (SELECT user_id FROM t_t) AND EXTRACT(MONTH FROM creation_date::date) = 10
)
SELECT DISTINCT week,
       LAST_VALUE(creation_date) OVER (PARTITION BY week)
FROM temp_t
