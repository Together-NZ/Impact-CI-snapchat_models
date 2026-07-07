{% macro final_calculation() %}
semi_final as (

SELECT parsed_data.* except(ad_id), ad_joint.* FROM ad_stat_filtered AS parsed_data LEFT JOIN ad_joint ON parsed_data.ad_id=ad_joint.ad_id),
non_result AS (
SELECT 
    ad_start_time AS date,
    ad_id,
    ad_name AS creative_name,
    ad_type,
    SUM(CAST(quartile_1 AS INT64)) AS video_25_completion,
    SUM(CAST(quartile_2 AS INT64)) AS video_50_completion,
    SUM(CAST(quartile_3 AS INT64)) AS video_75_completion,
    SUM(CAST(view_completion AS INT64)) AS video_completion,
    AVG(CAST(frequency AS FLOAT64)) AS frequency,
    SUM(CAST(media_cost AS FLOAT64) / 1000000) AS media_cost,
    SUM(CAST(clicks AS INT64)) AS clicks,
    SUM(CAST(impressions AS INT64)) AS impressions,
    SUM(CAST(video_views AS INT64)) AS video_views,
    SUM(CAST(view_time_millis AS FLOAT64) / 1000000) AS total_view,
    ad_updated_at,
    ad_created_at,
    media_buy_external_id,
    media_buy_name,
    media_buy_cost_model,
    ad_squad_type,
    campaign_advertiser_id,
    campaign_start_time,
    campaign_end_time,
    campaign_id,
    campaign_name,
    raw_data,
    campaign_status,
    ROW_NUMBER() OVER (PARTITION BY ad_start_time, ad_id, campaign_name) AS row_num
FROM 
    semi_final
GROUP BY 
    ad_start_time, ad_id, ad_name, ad_type, ad_updated_at, ad_created_at, media_buy_external_id, 
    media_buy_name, ad_squad_type, campaign_advertiser_id, campaign_start_time, campaign_end_time,
    campaign_id, campaign_name, campaign_status, media_buy_cost_model,raw_data)
SELECT *, 
CASE WHEN media_buy_cost_model ='impressions' THEN impressions
WHEN media_buy_cost_model = 'swipes' THEN clicks
WHEN media_buy_cost_model = 'landing_page_view' THEN SAFE_CAST(JSON_VALUE(raw_data,'$.landing_page_views') AS INT64)
WHEN media_buy_cost_model = 'video_views_15_sec' THEN SAFE_CAST(JSON_VALUE(raw_data,'$.video_views_15s') AS INT64)
WHEN media_buy_cost_model = 'video_views' THEN SAFE_CAST(JSON_VALUE(raw_data,'$.video_views') AS INT64)
WHEN media_buy_cost_model = 'app_installs' THEN SAFE_CAST(JSON_VALUE(raw_data,'$.total_installs_app') AS INT64)
WHEN media_buy_cost_model = 'story_opens' THEN SAFE_CAST(JSON_VALUE(raw_data,'$.story_opens') AS INT64)
WHEN media_buy_cost_model = 'pixel_page_view' THEN SAFE_CAST(JSON_VALUE(raw_data,'$.conversion_page_views') AS INT64)
WHEN media_buy_cost_model IN ('pixel_add_to_cart','app_add_to_cart') THEN SAFE_CAST(JSON_VALUE(raw_data,'$.conversion_add_cart') AS INT64)
WHEN media_buy_cost_model IN ('pixel_purchase','app_purchase') THEN SAFE_CAST(JSON_VALUE(raw_data,'$.conversion_purchases') AS INT64)
WHEN media_buy_cost_model IN ('pixel_signup','app_signup') THEN SAFE_CAST(JSON_VALUE(raw_data,'$.conversion_sign_ups') AS INT64)
WHEN media_buy_cost_model = 'lead_form_submissions' THEN SAFE_CAST(JSON_VALUE(raw_data,'$.native_leads') AS INT64)
ELSE 0 END AS result,
   'Snapchat' AS publisher,
    CASE 
        WHEN SPLIT (ad_name,'_')[OFFSET(1)] LIKE 'SOCIAL%'
        AND (
            lower(media_buy_name) LIKE '%vid%'
            OR lower(ad_name) LIKE '%vid%'
            OR lower(campaign_name) LIKE '%vid%'
        ) THEN 'Social Video'
        WHEN SPLIT (ad_name,'_')[OFFSET(1)] LIKE 'SOCIAL%'
        AND (
            lower(media_buy_name) NOT LIKE '%vid%'
            AND lower(ad_name) NOT LIKE '%vid%'
            AND lower(campaign_name) NOT LIKE '%vid%'
        )
        THEN 'Social Display'
        ELSE 'Other'
    END AS media_format,
    REGEXP_EXTRACT(media_buy_name, r'PLATFORM_([^_]+)') AS audience_name,
    CASE WHEN ARRAY_LENGTH(SPLIT(ad_name, '_')) >= 8 THEN SPLIT(ad_name, '_')[SAFE_OFFSET(7)] 
         ELSE 'Other' END AS creative_descr,
    CASE WHEN ARRAY_LENGTH(SPLIT(ad_name, '_')) >= 7 THEN SPLIT(ad_name, '_')[SAFE_OFFSET(5)] 
         ELSE 'Other' END AS ad_format_detail,
    CASE WHEN ARRAY_LENGTH(SPLIT(ad_name, '_')) >= 7 THEN SPLIT(ad_name, '_')[SAFE_OFFSET(6)] 
         ELSE 'Other' END AS ad_format,
    CASE WHEN ARRAY_LENGTH(SPLIT(campaign_name,'_')) <=1 THEN 'Other'
        ELSE SPLIT(campaign_name,'_')[SAFE_OFFSET(1)] END AS campaign_descr
from non_result
{% endmacro %}