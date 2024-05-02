-- 1. Посчитайте, сколько компаний закрылось.
SELECT COUNT(id)
FROM company
WHERE status = 'closed';


/* Отобразите количество привлечённых средств для новостных компаний США.
Используйте данные из таблицы company.
Отсортируйте таблицу по убыванию значений в поле funding_total .*/
SELECT SUM(funding_total)
FROM company
WHERE category_code = 'news' AND country_code = 'USA'
GROUP BY name
ORDER BY SUM(funding_total) DESC;


/*Найдите общую сумму сделок по покупке одних компаний другими в долларах. 
Отберите сделки, которые осуществлялись только за наличные с 2011 по 2013 год включительно.*/
SELECT SUM(price_amount)
FROM acquisition
WHERE EXTRACT(YEAR FROM CAST(acquired_at AS TIMESTAMP)) BETWEEN 2011 AND 2013
      AND term_code = 'cash'


/*Отобразите имя, фамилию и названия аккаунтов людей в поле network_username,
у которых названия аккаунтов начинаются на 'Silver'.*/
SELECT first_name, last_name, twitter_username
FROM people
WHERE twitter_username LIKE 'Silver%'

/*Выведите на экран всю информацию о людях, у которых названия аккаунтов в поле network_username
содержат подстроку 'money', а фамилия начинается на 'K'. */
SELECT *
FROM people
WHERE twitter_username LIKE '%money%' AND last_name LIKE 'K%'


/*Для каждой страны отобразите общую сумму привлечённых инвестиций,
которые получили компании, зарегистрированные в этой стране.
Страну, в которой зарегистрирована компания, можно определить по коду страны.
Отсортируйте данные по убыванию суммы.*/
SELECT SUM(funding_total), country_code
FROM company
GROUP BY country_code
ORDER BY SUM(funding_total) DESC


/*Составьте таблицу, в которую войдёт дата проведения раунда,
а также минимальное и максимальное значения суммы инвестиций, привлечённых в эту дату.
Оставьте в итоговой таблице только те записи,
в которых минимальное значение суммы инвестиций не равно нулю и не равно максимальному значению.*/
SELECT funded_at,
       MIN(raised_amount), 
       MAX(raised_amount)
FROM funding_round
GROUP BY funded_at
HAVING NOT MIN(raised_amount) = 0 
       AND NOT MIN(raised_amount) = MAX(raised_amount);


/*Создайте поле с категориями:
- Для фондов, которые инвестируют в 100 и более компаний, назначьте категорию high_activity.
- Для фондов, которые инвестируют в 20 и более компаний до 100, назначьте категорию middle_activity.
- Если количество инвестируемых компаний фонда не достигает 20, назначьте категорию low_activity.
Отобразите все поля таблицы fund и новое поле с категориями.*/
SELECT *,
       CASE
       WHEN invested_companies >= 100 THEN 'high_activity'
       WHEN invested_companies >= 20 AND invested_companies < 100 THEN 'middle_activity'
       WHEN invested_companies < 20 THEN 'low_activity'
       END
FROM fund

/*Для каждой из категорий, назначенных в предыдущем задании, 
посчитайте округлённое до ближайшего целого числа среднее количество инвестиционных раундов,
в которых фонд принимал участие. Выведите на экран категории и среднее число инвестиционных раундов.
Отсортируйте таблицу по возрастанию среднего.*/
SELECT
       CASE
           WHEN invested_companies>=100 THEN 'high_activity'
           WHEN invested_companies>=20 THEN 'middle_activity'
           ELSE 'low_activity'
       END AS activity,
       ROUND(AVG(investment_rounds))
FROM fund
GROUP BY activity
ORDER BY ROUND(AVG(investment_rounds));


/*Проанализируйте, в каких странах находятся фонды, которые чаще всего инвестируют в стартапы. 
Для каждой страны посчитайте минимальное, максимальное и среднее число компаний,
в которые инвестировали фонды этой страны, основанные с 2010 по 2012 год включительно.
Исключите страны с фондами, у которых минимальное число компаний, получивших инвестиции, равно нулю. 
Выгрузите десять самых активных стран-инвесторов: 
отсортируйте таблицу по среднему количеству компаний от большего к меньшему. 
Затем добавьте сортировку по коду страны в лексикографическом порядке.*/
SELECT country_code,
       MIN(invested_companies),
       MAX(invested_companies),
       AVG(invested_companies)
FROM fund
WHERE EXTRACT(YEAR FROM CAST(founded_at AS TIMESTAMP)) BETWEEN 2010 AND 2012
GROUP BY country_code
HAVING NOT MIN(invested_companies) = 0
ORDER BY AVG(invested_companies) DESC, country_code
LIMIT 10;


/*Отобразите имя и фамилию всех сотрудников стартапов. 
Добавьте поле с названием учебного заведения, которое окончил сотрудник, если эта информация известна.*/
SELECT people.first_name,
       people.last_name,
       education.instituition
FROM people LEFT JOIN education ON people.id = education.person_id;


/*Для каждой компании найдите количество учебных заведений, которые окончили её сотрудники. 
Выведите название компании и число уникальных названий учебных заведений. 
Составьте топ-5 компаний по количеству университетов.*/
WITH
company AS (SELECT id, name
            FROM company),
people AS (SELECT id, company_id
           FROM people),
education AS (SELECT person_id, instituition
              FROM education)
SELECT company.name, COUNT(DISTINCT education.instituition)
FROM company LEFT JOIN people ON company.id = people.company_id LEFT JOIN education ON education.person_id = people.id
GROUP BY company.name
ORDER BY count DESC
LIMIT 5;


/*Составьте список с уникальными названиями закрытых компаний, 
для которых первый раунд финансирования оказался последним.*/
SELECT DISTINCT name
FROM company
WHERE status = 'closed' AND id IN (SELECT company_id
                                   FROM funding_round
                                   WHERE (is_first_round = 1 AND is_last_round = 1));


/*Составьте список уникальных номеров сотрудников,
которые работают в компаниях, отобранных в предыдущем задании.*/
SELECT id
FROM people
WHERE company_id IN (SELECT DISTINCT id
                     FROM company
                     WHERE status = 'closed' AND id IN (SELECT company_id
                                                        FROM funding_round
                                                        WHERE (is_first_round = 1 AND is_last_round = 1)));
    
/*
Составьте таблицу, куда войдут уникальные пары с номерами сотрудников
из предыдущей задачи и учебным заведением, которое окончил сотрудник.*/
SELECT DISTINCT people.id,
       education.instituition
FROM
(SELECT id
FROM people
WHERE company_id IN (SELECT DISTINCT id
                     FROM company
                     WHERE status = 'closed' AND id IN (SELECT company_id
                                                        FROM funding_round
                                                        WHERE (is_first_round = 1 AND is_last_round = 1)))) AS people
INNER JOIN (SELECT instituition, 
                   person_id
           FROM education) AS education ON people.id = education.person_id;


/*Посчитайте количество учебных заведений для каждого сотрудника из предыдущего задания. 
При подсчёте учитывайте, что некоторые сотрудники могли окончить одно и то же заведение дважды.*/
SELECT DISTINCT people.id AS id,
       COUNT(education.instituition)
FROM
(SELECT id
FROM people
WHERE company_id IN (SELECT DISTINCT id
                     FROM company
                     WHERE status = 'closed' AND id IN (SELECT company_id
                                                        FROM funding_round
                                                        WHERE (is_first_round = 1 AND is_last_round = 1)))) AS people
INNER JOIN (SELECT instituition, 
                   person_id
           FROM education) AS education ON people.id = education.person_id
GROUP BY id;


/*Дополните предыдущий запрос и выведите среднее число учебных заведений
(всех, не только уникальных), которые окончили сотрудники разных компаний.
Нужно вывести только одну запись, группировка здесь не понадобится.*/
SELECT AVG(final.count)
FROM
(SELECT DISTINCT people.id AS id,
       COUNT(education.instituition) AS count
FROM
(SELECT id
FROM people
WHERE company_id IN (SELECT DISTINCT id
                     FROM company
                     WHERE status = 'closed' AND id IN (SELECT company_id
                                                        FROM funding_round
                                                        WHERE (is_first_round = 1 AND is_last_round = 1)))) AS people
INNER JOIN (SELECT instituition, 
                   person_id
           FROM education) AS education ON people.id = education.person_id
GROUP BY id) AS final;


/*Напишите похожий запрос: выведите среднее число учебных заведений (всех, не только уникальных), которые окончили сотрудники Facebook*.
*(сервис, запрещённый на территории РФ)*/
SELECT AVG(final.count)
FROM
(SELECT DISTINCT people.id AS id,
       COUNT(education.instituition) AS count
FROM
(SELECT id
FROM people
WHERE company_id IN (SELECT DISTINCT id
                     FROM company
                     WHERE name='Facebook')) AS people
INNER JOIN (SELECT instituition, 
                   person_id
           FROM education) AS education ON people.id = education.person_id
GROUP BY id) AS final;


/*
Составьте таблицу из полей:
name_of_fund — название фонда;
name_of_company — название компании;
amount — сумма инвестиций, которую привлекла компания в раунде.
В таблицу войдут данные о компаниях, в истории которых было больше шести важных этапов, 
а раунды финансирования проходили с 2012 по 2013 год включительно.*/
SELECT f.name AS name_of_fund,
       c.name AS name_of_company,
       fr.raised_amount AS amount
FROM investment AS i INNER JOIN company AS c ON i.company_id = c.id
INNER JOIN fund AS f ON f.id = i.fund_id
INNER JOIN funding_round AS fr ON fr.id = i.funding_round_id
WHERE c.milestones > 6 AND EXTRACT(YEAR FROM CAST(fr.funded_at AS TIMESTAMP)) BETWEEN 2012 AND 2013;


/*Выгрузите таблицу, в которой будут такие поля:
название компании-покупателя;
сумма сделки;
название компании, которую купили;
сумма инвестиций, вложенных в купленную компанию;
доля, которая отображает, во сколько раз сумма покупки 
превысила сумму вложенных в компанию инвестиций, округлённая до ближайшего целого числа.
Не учитывайте те сделки, в которых сумма покупки равна нулю. 
Если сумма инвестиций в компанию равна нулю, исключите такую компанию из таблицы. 
Отсортируйте таблицу по сумме сделки от большей к меньшей, 
а затем по названию купленной компании в лексикографическом порядке. 
Ограничьте таблицу первыми десятью записями.*/
WITH
-- покупатель
buyer AS (SELECT a.id AS deal_id_buyer,
                 c.name AS buyer_name
          FROM acquisition AS a LEFT JOIN company AS c ON a.acquiring_company_id = c.id),
-- продавец
salesman AS (SELECT a.id AS deal_id_salesman,
                    c.name AS salesman_name,
                    c.funding_total AS total_investments
             FROM acquisition AS a LEFT JOIN company AS c ON a.acquired_company_id = c.id)
-- остальная информация
SELECT buyer.buyer_name,
       a.price_amount,
       salesman.salesman_name,
       salesman.total_investments,
       ROUND(a.price_amount/salesman.total_investments) AS perc
FROM acquisition AS a LEFT JOIN buyer ON a.id = buyer.deal_id_buyer
LEFT JOIN salesman ON a.id = salesman.deal_id_salesman
WHERE NOT salesman.total_investments = 0 AND NOT price_amount = 0
ORDER BY a.price_amount DESC, buyer.buyer_name, salesman.salesman_name
LIMIT 10


/*Выгрузите таблицу, в которую войдут названия компаний из категории social,
получившие финансирование с 2010 по 2013 год включительно. 
Проверьте, что сумма инвестиций не равна нулю. Выведите также номер месяца, в котором проходил раунд финансирования.*/
SELECT c.name, 
       EXTRACT(MONTH FROM CAST(fr.funded_at AS TIMESTAMP)) AS month
FROM company AS C INNER JOIN funding_round AS fr ON c.id = fr.company_id
WHERE EXTRACT(YEAR FROM CAST(fr.funded_at AS TIMESTAMP)) BETWEEN 2010 AND 2013 
AND c.category_code = 'social' AND NOT fr.raised_amount  = 0
ORDER BY month, c.name


/*Отберите данные по месяцам с 2010 по 2013 год, когда проходили инвестиционные раунды. 
Сгруппируйте данные по номеру месяца и получите таблицу, в которой будут поля:
- номер месяца, в котором проходили раунды;
- количество уникальных названий фондов из США, которые инвестировали в этом месяце;
- количество компаний, купленных за этот месяц;
- общая сумма сделок по покупкам в этом месяце*/
WITH 
cut_ac AS (SELECT EXTRACT(MONTH FROM CAST(acquired_at AS TIMESTAMP)) AS month, 
           COUNT(acquired_company_id) AS amount_acquired_company, 
           SUM(price_amount) AS total_deal 
           FROM acquisition 
           WHERE EXTRACT(YEAR FROM CAST(acquired_at AS TIMESTAMP)) BETWEEN 2010 AND 2013
           GROUP BY month), 
cut_fr AS (SELECT EXTRACT(MONTH FROM CAST(fr.funded_at AS TIMESTAMP)) AS month, 
                  COUNT(DISTINCT f.name) AS count
           FROM funding_round AS fr INNER JOIN investment AS i ON fr.id = i.funding_round_id INNER JOIN fund AS f ON f.id = i.fund_id 
           WHERE EXTRACT(YEAR FROM CAST(fr.funded_at AS TIMESTAMP)) BETWEEN 2010 AND 2013
           AND f.country_code = 'USA'
           GROUP BY month) 
SELECT cut_fr.month, 
       cut_fr.count, 
       cut_ac.amount_acquired_company, 
       cut_ac.total_deal 
FROM cut_fr INNER JOIN cut_ac ON cut_fr.month = cut_ac.month;


/*Составьте сводную таблицу и выведите среднюю сумму инвестиций для стран,
в которых есть стартапы, зарегистрированные в 2011, 2012 и 2013 годах.
Данные за каждый год должны быть в отдельном поле.
Отсортируйте таблицу по среднему значению инвестиций за 2011 год от большего к меньшему.*/
WITH
table_2011 AS (SELECT country_code AS cc_2011,
                      AVG(funding_total) AS avg_2011
               FROM company
               WHERE EXTRACT(YEAR FROM CAST(founded_at AS TIMESTAMP)) = 2011
               GROUP BY country_code),
table_2012 AS (SELECT country_code AS cc_2012,
                      AVG(funding_total) AS avg_2012
               FROM company
               WHERE EXTRACT(YEAR FROM CAST(founded_at AS TIMESTAMP)) = 2012
               GROUP BY country_code),
table_2013 AS (SELECT country_code AS cc_2013,
                      AVG(funding_total) AS avg_2013
               FROM company
               WHERE EXTRACT(YEAR FROM CAST(founded_at AS TIMESTAMP)) = 2013
               GROUP BY country_code)
SELECT table_2011.cc_2011,
       table_2011.avg_2011,
       table_2012.avg_2012,
       table_2013.avg_2013
FROM table_2011 inner JOIN table_2012 ON table_2011.cc_2011 = table_2012.cc_2012
inner JOIN table_2013 ON table_2011.cc_2011 = table_2013.cc_2013
ORDER BY table_2011.avg_2011 DESC;


