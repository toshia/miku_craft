# -*- coding: utf-8 -*-
require 'yaml'

Plugin.create :campaign_table do
  filter_campaign_table do |table|
    [table +
     YAML.load_file(File.join(__dir__, 'campaign_table', 'campaign.yearly.yml')) +
     YAML.load_file(File.join(__dir__, 'campaign_table', 'campaign.limited.yml'))]
  end
end
