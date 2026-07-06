{% macro merge_infos() %}
ad_squad_joint_campaign AS (
    SELECT ad_squad.* except(campaign_id),campaign.* FROM deduplicate_ad_squad as ad_squad LEFT JOIN campaign_filtered AS campaign ON ad_squad.campaign_id=campaign.campaign_id
),
ad_joint AS (
    SELECT ads.* except(row_num), reference.* except(row_num) FROM ad_details_filtered AS ads LEFT JOIN ad_squad_joint_campaign AS reference ON reference.ad_squad_id=ads.media_buy_external_id
)
{% endmacro %}