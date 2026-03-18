{% macro ad_squad(source_name, table_name) %}
ad_squad AS (
    SELECT 
    -- ad squad, media buy name , campaign id and cost model
        JSON_EXTRACT_SCALAR(data, "$.id") AS id,
        JSON_EXTRACT_SCALAR(data, "$.name") AS media_buy_name,
        JSON_EXTRACT_SCALAR(data, "$.type") AS ad_squad_type,
        JSON_EXTRACT_SCALAR(data, "$.optimization_goal") AS media_buy_cost_model,
        JSON_EXTRACT_SCALAR(data, "$.campaign_id") AS campaign_id,
        ROW_NUMBER() OVER(PARTITION BY JSON_EXTRACT_SCALAR(data, "$.id"),JSON_EXTRACT_SCALAR(data, "$.campaign_id"),JSON_EXTRACT_SCALAR(data, "$.name"),JSON_EXTRACT_SCALAR(data, "$.type") ORDER BY _sdc_extracted_at) as row_num

    FROM {{ source(source_name, table_name) }}
),
ad_squad_filtered AS (
  SELECT *  FROM ad_squad where row_num=1
)
{% endmacro %}