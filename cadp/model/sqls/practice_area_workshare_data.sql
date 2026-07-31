SELECT 
    id,
    agency,
    account_name,
    opportunity_name,
    practice_area_value,
    practice_area_name,
    work_share,
    amount_share,
    concat(id, practice_area_name) as unique_id
FROM icebase.builderuploads.practice_area_workshare_data