SELECT 
    CONCAT(COALESCE(person_name.given_name, ''),
            ' ',
            COALESCE(person_name.middle_name, ''),
            ' ',
            COALESCE(person_name.family_name, '')) AS person_name,
    GROUP_CONCAT(DISTINCT id.identifier
        SEPARATOR ', ') AS identifiers
FROM
    amrs.person `t1`
        INNER JOIN
    amrs.person_name `person_name` ON (t1.person_id = person_name.person_id
        AND (person_name.voided IS NULL
        || person_name.voided = 0))
        LEFT OUTER JOIN
    amrs.patient_identifier `id` ON (t1.person_id = id.patient_id)
GROUP BY t1.person_id
LIMIT 300