{% macro ad_squad(source_name, table_name) %}
WITH ad_squad as ( SELECT 
    -- ad squad, media buy name , campaign id and cost model
        JSON_EXTRACT_SCALAR(data, "$.id") AS ad_squad_id,
        JSON_EXTRACT_SCALAR(data, "$.name") AS media_buy_name,
        JSON_EXTRACT_SCALAR(data, "$.type") AS ad_squad_type,
        LOWER(JSON_EXTRACT_SCALAR(data, "$.optimization_goal")) AS media_buy_cost_model,
        JSON_EXTRACT_SCALAR(data, "$.campaign_id") AS campaign_id,
        ROW_NUMBER() OVER(PARTITION BY JSON_EXTRACT_SCALAR(data, "$.id") ORDER BY _sdc_extracted_at DESC ) as row_num

    FROM {{ source(source_name, table_name) }}),
deduplicate_ad_squad AS (
    select * from ad_squad where row_num=1)
{% endmacro %}