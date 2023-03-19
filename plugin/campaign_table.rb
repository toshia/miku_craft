# -*- coding: utf-8 -*-
require 'yaml'
require 'json'

Plugin.create :campaign_table do
  filter_campaign_table do |table|
    [table +
     JSON.parse(
       JSON.generate(
         YAML.safe_load_file(File.join(__dir__, 'campaign_table', 'campaign.yearly.yml'), aliases: true)
       ),
       symbolize_names: true
     ) +
     JSON.parse(
       JSON.generate(
         YAML.safe_load_file(File.join(__dir__, 'campaign_table', 'campaign.limited.yml'), aliases: true)
       ),
       symbolize_names: true
     )]
  end
end
