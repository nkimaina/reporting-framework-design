SELECT 
    gender,
    CASE
        WHEN age BETWEEN 0 AND 1 THEN '0_to_1'
        WHEN age BETWEEN 1 AND 9 THEN '1_to_9'
        WHEN age BETWEEN 10 AND 14 THEN '10_to_14'
        WHEN age BETWEEN 15 AND 19 THEN '15_to_19'
        WHEN age BETWEEN 20 AND 24 THEN '20_to_24'
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
    END AS active_on_art
FROM
    etl.hiv_monthly_report_dataset;