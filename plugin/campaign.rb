# -*- coding: utf-8 -*-
require_relative 'campaign/campaign_utils'

Plugin.create :campaign do
  on_give_continuous_login_bonus do |name, count|
    Plugin::Campaign::Campaign.active_campaigns.each do |campaign|
      campaign.daily(user_name: name, login_count: count)
    end
  end
end






