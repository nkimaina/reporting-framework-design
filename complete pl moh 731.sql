SELECT 
    t1.person_id,
    t1.encounter_id,
    t1.location_id,
    t1.location_uuid,
    t1.uuid AS patient_uuid,
    person.gender,
    person.birthdate,
    EXTRACT(YEAR FROM (FROM_DAYS(DATEDIFF(NOW(), person.birthdate)))) AS age,
    CASE
        WHEN
            (TIMESTAMPDIFF(DAY,
                t1.vl_order_date,
                NOW()) BETWEEN 0 AND 14)
                AND (t1.vl_1_date IS NULL
                OR t1.vl_order_date > t1.vl_1_date)
        THEN
            TRUE
        ELSE FALSE
    END AS has_pending_vl_test,
    DATE_FORMAT(t1.enrollment_date, '%d-%m-%Y') AS enrollment_date,
    DATE_FORMAT(t1.hiv_start_date, '%d-%m-%Y') AS hiv_start_date,
    t1.arv_start_location,
    DATE_FORMAT(t1.arv_first_regimen_start_date,
            '%d-%m-%Y') AS arv_first_regimen_start_date,
    DATE_FORMAT(t1.arv_start_date, '%d-%m-%Y') AS cur_regimen_arv_start_date,
    t1.cur_arv_line,
    t1.cur_arv_meds,
    t1.arv_first_regimen,
    t1.vl_1,
    DATE_FORMAT(t1.vl_1_date, '%d-%m-%Y') AS vl_1_date,
    DATE_FORMAT(t1.rtc_date, '%d-%m-%Y') AS rtc_date,
    DATE_FORMAT(t1.tb_prophylaxis_start_date, '%d-%m-%Y') AS tb_prophylaxis_start_date,
    DATE_FORMAT(t1.pcp_prophylaxis_start_date,
            '%d-%m-%Y') AS pcp_prophylaxis_start_date,
    DATE_FORMAT(t1.tb_tx_start_date, '%d-%m-%Y') AS tb_tx_start_date,
    t1.encounter_type,
    DATE_FORMAT(t1.encounter_datetime, '%d-%m-%Y') AS encounter_datetime,
    DATE_FORMAT(t1.death_date, '%d-%m-%Y') AS death_date,
    t1.out_of_care,
    t1.transfer_out,
    t1.patient_care_status,
    t1.prev_rtc_date,
    t1.prev_encounter_datetime_hiv,
    CONCAT(COALESCE(person_name.given_name, ''),
            ' ',
            COALESCE(person_name.middle_name, ''),
            ' ',
            COALESCE(person_name.family_name, '')) AS person_name,
    GROUP_CONCAT(DISTINCT id.identifier
        SEPARATOR ', ') AS identifiers
FROM
    etl.dates `t2`
        INNER JOIN
    etl.flat_hiv_summary `t1` ON (DATE(t1.encounter_datetime) <= DATE(t2.endDate))
        INNER JOIN
    amrs.location `t2` ON (t1.location_uuid = t2.uuid)
        INNER JOIN
    amrs.person `t3` ON (t1.person_id = t3.person_id)
        INNER JOIN
    amrs.person_name `person_name` ON (t1.person_id = person_name.person_id
        AND (person_name.voided IS NULL
        || person_name.voided = 0))
        LEFT OUTER JOIN
    amrs.patient_identifier `id` ON (t1.person_id = id.patient_id)
        INNER JOIN
    amrs.person `person` ON (t1.person_id = person.person_id)
WHERE
    (t2.endDate >= DATE('2018-01-23')
        AND t2.endDate <= DATE('2018-02-23')
        AND t1.location_id IN (13)
        AND t1.is_clinical_encounter = 1
        AND (t1.next_clinical_datetime_hiv IS NULL
        OR DATE(t1.next_clinical_datetime_hiv) > t2.endDate)
        AND CASE
        WHEN
            DATE(t1.death_date) <= t2.endDate
                OR (DATE(outreach_death_date_bncd) <= t2.endDate
                AND DATE(outreach_date_bncd) <= t2.endDate)
        THEN
            NULL
        WHEN
            t1.transfer_out IS NOT NULL
                OR (outreach_patient_care_status_bncd IN (1287 , 1594, 9068, 9504, 1285)
                AND DATE(outreach_date_bncd) <= t2.endDate)
                OR (transfer_transfer_out_bncd IS NOT NULL
                AND DATE(transfer_date_bncd) <= t2.endDate)
        THEN
            NULL
        WHEN
            t1.patient_care_status IN (9083)
                OR (outreach_patient_care_status_bncd IN (9083)
                AND DATE(outreach_date_bncd) <= t2.endDate)
        THEN
            NULL
        WHEN
            (outreach_patient_care_status_bncd IN (9036)
                AND DATE(outreach_date_bncd) <= t2.endDate)
                OR t1.patient_care_status IN (9036)
        THEN
            NULL
        WHEN
            TIMESTAMPDIFF(DAY,
                IF(t1.rtc_date,
                    t1.rtc_date,
                    DATE_ADD(t1.encounter_datetime,
                        INTERVAL 30 DAY)),
                t2.endDate) <= 90
        THEN
            1
    END
        AND (encounter_datetime >= pcp_prophylaxis_start_date
        AND COALESCE(t1.death_date, out_of_care) IS NULL))
GROUP BY t1.person_id
ORDER BY t1.encounter_datetime DESC
LIMIT 300