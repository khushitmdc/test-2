WITH cte AS (
    SELECT
        *,
        CAST(
            date_parse(
                replace(rfi_release_date, ' UTC', ''),
                '%Y-%m-%d %H:%i:%s.%f'
            ) AS timestamp
        ) AS rfi_release_ts,

        DATE_DIFF(
            'month',
            CAST(
                date_parse(
                    replace(rfi_release_date, ' UTC', ''),
                    '%Y-%m-%d %H:%i:%s.%f'
                ) AS timestamp
            ),
            current_timestamp
        ) AS month_diff
    FROM "icebase"."builderuploads"."opportunities_data"
),

cte2 AS (
    SELECT *,
        CASE
            WHEN CAST(rfi_release_ts AS date) >= current_date THEN
                CASE
                    WHEN month_diff < 3 THEN 1
                    WHEN month_diff < 6 THEN 2
                    WHEN month_diff < 9 THEN 3
                    WHEN month_diff < 12 THEN 4
                    WHEN month_diff < 15 THEN 5
                    ELSE 99
                END
            ELSE 0
        END AS priority_month
    FROM cte
),

cte3 AS (
    SELECT *,
        CASE
            WHEN pwin BETWEEN 76 AND 100 THEN 1
            WHEN pwin BETWEEN 51 AND 75 THEN 2
            WHEN pwin BETWEEN 26 AND 50 THEN 3
            WHEN pwin BETWEEN 1 AND 25 THEN 4
            ELSE 5
        END AS pwin_bucket
    FROM cte2
),

cte4 AS (
    SELECT *,
           ROW_NUMBER() OVER () AS row_id
    FROM cte3
),

ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (
            ORDER BY
                rfi_release_ts ASC,
                priority_month ASC,
                pwin DESC
        ) AS future_rank
    FROM cte4
    WHERE priority_month > 0
),

final AS (
    SELECT
        c4.*,
        CASE
            WHEN c4.priority_month = 0 THEN 0
            ELSE r.future_rank
        END AS priority_rank
    FROM cte4 c4
    LEFT JOIN ranked r
        ON c4.row_id = r.row_id
)

SELECT
    id,
    agency,
    account_name,
    opportunity_name,
    stage,
    opp_type,
    description,
    rfq_number,
    winit_opp_id,
    probability,
    practice_area_priority,
    practice_area,
    sector,
    business_area,
    division,
    pwin,
    pgo,
    basepop,
    totalpop,
    type_of_competition,
    leidos_tcv,
    leidos_tcv_amount_in_dollar,
    practice_area_value_in_dollar,
    rfi_release_date,
    rfi_release_date AS rfp_release_date,
    rfi_due_date,
    rfi_submitted,
    ref_submitted_date,
    rfp_due_date,
    rfp_submitted_date,
    close_date,
    start_date,
    end_date,
    opportunity_owner,
    award_date,
    expected_revenue,
    expected_cost,
    priority_rank
FROM final
ORDER BY priority_rank;