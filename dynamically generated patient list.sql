SELECT 
    hmrd.gender,
    CASE
        WHEN hmrd.age BETWEEN 0 AND 1 THEN '0_to_1'
        WHEN hmrd.age BETWEEN 1 AND 9 THEN '1_to_9'
        WHEN hmrd.age BETWEEN 10 AND 14 THEN '10_to_14'
        WHEN hmrd.age BETWEEN 15 AND 19 THEN '15_to_19'
        WHEN hmrd.age BETWEEN 20 AND 24 THEN '20_to_24'
        ELSE 'older_than_24'
    END AS age_range,
    CASE
        WHEN
            status = 'active'
                AND on_pcp_prophylaxis_this_month = 1
        THEN
            1
        ELSE NULL
    END AS on_ctx_prophylaxis,
    CASE
        WHEN
            status = 'active'
                AND on_art_this_month = 1
        THEN
            1
        ELSE NULL
    END AS active_on_art,
    CONCAT(COALESCE(person_name.given_name, ''),
            ' ',
            COALESCE(person_name.middle_name, ''),
            ' ',
            COALESCE(person_name.family_name, '')) AS person_name,
    GROUP_CONCAT(DISTINCT id.identifier
        SEPARATOR ', ') AS identifiers
FROM
    etl.hiv_monthly_report_dataset hmrd
        INNER JOIN
    amrs.person t1 ON (t1.person_id = hmrd.person_id)
        INNER JOIN
    amrs.person_name `person_name` ON (t1.person_id = person_name.person_id
        AND (person_name.voided IS NULL
        || person_name.voided = 0))
        LEFT OUTER JOIN
    amrs.patient_identifier `id` ON (t1.person_id = id.patient_id)
WHERE
    (CASE
        WHEN hmrd.age BETWEEN 0 AND 1 THEN '0_to_1'
        WHEN hmrd.age BETWEEN 1 AND 9 THEN '1_to_9'
        WHEN hmrd.age BETWEEN 10 AND 14 THEN '10_to_14'
        WHEN hmrd.age BETWEEN 15 AND 19 THEN '15_to_19'
        WHEN hmrd.age BETWEEN 20 AND 24 THEN CONCAT(20, '_to_', 24)
        ELSE 'older_than_24'
    END) = '20_to_24'
        AND (CASE
        WHEN
            hmrd.status = 'active'
                AND hmrd.on_art_this_month = 1
        THEN
            1
        ELSE NULL
    END) = 1
        AND hmrd.gender = 'M'
        AND hmrd.endDate = '2017-12-31'
GROUP BY t1.person_id
LIMIT 300 OFFSET 0;