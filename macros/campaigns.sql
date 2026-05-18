{% macro campaigns(source_name, table_name) %}
campaign AS (
    SELECT 
    -- campaign details ( id, name , status and etc)
        JSON_EXTRACT_SCALAR(data, "$.id") AS campaign_id,
        JSON_EXTRACT_SCALAR(data, "$.name") AS campaign_name,
        JSON_EXTRACT_SCALAR(data, "$.status") AS campaign_status,
        JSON_EXTRACT_SCALAR(data, "$.start_time") AS campaign_start_time,
        JSON_EXTRACT_SCALAR(data, "$.end_time") AS campaign_end_time,
        ROW_NUMBER() OVER (PARTITION BY JSON_EXTRACT_SCALAR(data, "$.id") ORDER BY _sdc_extracted_at ) as row_num
    FROM {{ source(source_name, table_name) }}
),
campaign_filtered AS (
    SELECT * FROM campaign WHERE row_num=1
)
{% endmacro %}