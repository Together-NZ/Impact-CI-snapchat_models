{% macro ad_stats_daily(source_name, table_name) %}
ad_stat_filtered_duplicate AS (
    SELECT 
    -- vidoe metrics, actions(like, comment and etc)
        *,
        ROW_NUMBER() OVER (
            PARTITION BY id, ad_start_time
            ORDER BY extraction_date DESC
        ) AS row_num
    FROM (
        SELECT
            _sdc_extracted_at AS extraction_date,
            JSON_EXTRACT_SCALAR(data, "$.id") AS id,
            DATETIME(TIMESTAMP(JSON_EXTRACT_SCALAR(data, "$.start_time")),"Pacific/Auckland") AS ad_start_time,
            JSON_EXTRACT_SCALAR(data, "$.impressions") AS impressions,
            SAFE_CAST(JSON_EXTRACT_SCALAR(data, "$.spend")as float64)  AS spend,
            JSON_EXTRACT_SCALAR(data, "$.quartile_1") AS quartile_1,
            JSON_EXTRACT_SCALAR(data, "$.quartile_2") AS quartile_2,
            JSON_EXTRACT_SCALAR(data, "$.quartile_3") AS quartile_3,
            JSON_EXTRACT_SCALAR(data, "$.view_completion") AS view_completion,
            JSON_EXTRACT_SCALAR(data, "$.frequency") AS frequency,
            JSON_EXTRACT_SCALAR(data, "$.uniques") AS unqieus,
            JSON_EXTRACT_SCALAR(data, "$.swipes") AS clicks,
            JSON_EXTRACT_SCALAR(data, "$.video_views") AS video_views,
            JSON_EXTRACT_SCALAR(data, "$.view_time_millis") AS view_time_millis
        FROM {{ source(source_name, table_name) }}
    )
  
),
ad_stat_filtered AS (
    select * from ad_stat_filtered_duplicate where row_num=1
)
{% endmacro %}