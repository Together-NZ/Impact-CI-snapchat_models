{% macro final_calculation() %}
combined_data AS (
    SELECT 
    -- combined data
        ad_stat.id AS ad_key,
        ad_stat.ad_start_time,
        ad_stat.impressions,
        ad_stat.spend as media_cost,
        ad_stat.quartile_1,
        ad_stat.quartile_2,
        ad_stat.quartile_3,
        ad_stat.view_completion,
        ad_stat.frequency,
        ad_stat.clicks,
        ad_stat.video_views,
        ad_stat.view_time_millis,
        ad_details.ad_name,
        ad_details.ad_type,
        ad_details.ad_updated_at,
        ad_details.ad_created_at,
        ad_details.media_buy_external_id,
        ad_details.campaign_advertiser_id,
        ad_squad.media_buy_name,
        ad_squad.ad_squad_type,
        ad_squad.media_buy_cost_model,
        campaign.campaign_id,
        campaign.campaign_name,
        campaign.campaign_status,
        campaign.campaign_start_time,
        campaign.campaign_end_time
    FROM ad_stat_filtered ad_stat
    LEFT JOIN ad_details_filtered ad_details ON ad_stat.id = ad_details.id
    LEFT JOIN ad_squad_filtered ad_squad ON ad_details.media_buy_external_id = ad_squad.id
    LEFT JOIN campaign_filtered campaign ON ad_squad.campaign_id = campaign.campaign_id
),
final AS (

-- Step 6: Aggregate and finalize data
SELECT 
    ad_start_time AS date,
    ad_key,
    ad_name,
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
    campaign_status,
    ROW_NUMBER() OVER (PARTITION BY ad_start_time, ad_key, campaign_name) AS row_num
FROM 
    combined_data
GROUP BY 
    ad_start_time, ad_key, ad_name, ad_type, ad_updated_at, ad_created_at, media_buy_external_id, 
    media_buy_name, ad_squad_type, campaign_advertiser_id, campaign_start_time, campaign_end_time,
    campaign_id, campaign_name, campaign_status, media_buy_cost_model)

SELECT * EXCEPT(ad_name), ad_name AS creative_name,
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
    CASE WHEN ARRAY_LENGTH(SPLIT(media_buy_name, '_')) < 8 AND ARRAY_LENGTH(SPLIT(media_buy_name, '_')) > 1  
         THEN SPLIT(media_buy_name, '_')[SAFE_OFFSET(ARRAY_LENGTH(SPLIT(media_buy_name, '_'))-1)] 
         WHEN ARRAY_LENGTH(SPLIT(media_buy_name, '_')) >= 8 THEN SPLIT(media_buy_name, '_')[SAFE_OFFSET(7)] 
         ELSE 'Other' END AS audience_name,
    CASE WHEN ARRAY_LENGTH(SPLIT(ad_name, '_')) < 8 AND ARRAY_LENGTH(SPLIT(ad_name, '_')) > 1  
         THEN SPLIT(ad_name, '_')[SAFE_OFFSET(ARRAY_LENGTH(SPLIT(ad_name, '_'))-1)] 
         WHEN ARRAY_LENGTH(SPLIT(ad_name, '_')) >= 8 THEN SPLIT(ad_name, '_')[SAFE_OFFSET(7)] 
         ELSE 'Other' END AS creative_descr,
    CASE WHEN ARRAY_LENGTH(SPLIT(ad_name, '_')) >= 8 THEN SPLIT(ad_name, '_')[SAFE_OFFSET(5)] 
         WHEN ARRAY_LENGTH(SPLIT(ad_name, '_')) < 8 AND ARRAY_LENGTH(SPLIT(ad_name, '_')) > 1  
         THEN SPLIT(ad_name, '_')[SAFE_OFFSET(ARRAY_LENGTH(SPLIT(ad_name, '_'))-3)] 
         ELSE 'Other' END AS ad_format_detail,
    CASE WHEN ARRAY_LENGTH(SPLIT(ad_name, '_')) >= 8 THEN SPLIT(ad_name, '_')[SAFE_OFFSET(6)] 
         WHEN ARRAY_LENGTH(SPLIT(ad_name, '_')) < 8 AND ARRAY_LENGTH(SPLIT(ad_name, '_')) > 1  
         THEN SPLIT(ad_name, '_')[SAFE_OFFSET(ARRAY_LENGTH(SPLIT(ad_name, '_'))-2)] 
         ELSE 'Other' END AS ad_format,
    CASE WHEN ARRAY_LENGTH(SPLIT(campaign_name,'_')) <=1 THEN 'Other'
        ELSE SPLIT(campaign_name,'_')[SAFE_OFFSET(1)] END AS campaign_descr

FROM final WHERE row_num = 1
{% endmacro %}