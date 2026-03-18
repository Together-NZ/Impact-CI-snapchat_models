{% macro ad_detail(source_name, table_name) %}
ad_details AS (
    SELECT 
    -- ad, media_buy and campaign advertiser
        JSON_EXTRACT_SCALAR(data, "$.id") AS id,
        JSON_EXTRACT_SCALAR(data, "$.name") AS ad_name,
        JSON_EXTRACT_SCALAR(data, "$.type") AS ad_type,
        JSON_EXTRACT_SCALAR(data, "$.updated_at") AS ad_updated_at,
        JSON_EXTRACT_SCALAR(data, "$.created_at") AS ad_created_at,
        JSON_EXTRACT_SCALAR(data, "$.ad_squad_id") AS media_buy_external_id,
        JSON_EXTRACT_SCALAR(data, "$.ad_account_id") AS campaign_advertiser_id,
        ROW_NUMBER() OVER (PARTITION BY JSON_EXTRACT_SCALAR(data, "$.id") ORDER BY _sdc_extracted_at)as row_num
    FROM {{ source(source_name, table_name) }}
),
ad_details_filtered AS (
  SELECT * FROM ad_details where row_num=1
)
{% endmacro %}