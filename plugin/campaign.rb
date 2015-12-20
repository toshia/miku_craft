# -*- coding: utf-8 -*-

module Plugin::Campaign
  class Campaign
    attr_accessor :name, :range

    def initialize(name:, range:)
      @name, @range = name, range
    end

    def on_daily_login
      @daily = Proc.new
      self
    end

    def daily(name)
      @daily.(name, self)
    end
  end

  Campaigns = [
    Campaign.new(name: "人権週間キャンペーン",
                 range: Range.new(Date.new(2015, 12, 4), Date.new(2015, 12, 10), false))
    .on_daily_login{ |name, campaign|
      Plugin.call(:minecraft_tell, name, '人権週間キャンペーン開催中(12/10まで)！一日乗車券をプレゼント！')
      Plugin.call(:minecraft_give_item, name, 'minecraft:paper', 1, 0, "{display:{Name:\"一日乗車券\"}}")
    },
    Campaign.new(name: "mikutter#{Time.now.year - 2009}周年記念キャンペーン",
                 range: Range.new(Date.new(2015, 12, 20), Date.new(2015, 12, 25), false))
      .on_daily_login{ |name, campaign|
      Plugin.call(:minecraft_tell, name, "#{campaign.name}！誕生日ケーキをプレゼント！")
      Plugin.call(:minecraft_give_item, name, 'minecraft:cake', 1, 0, '{display:{Name: "誕生日ケーキ",Lore:["mikutterの誕生日記念"]}}')
    }
  ]

  def self.active_campaigns
    today = Date.today
    Campaigns.select do |campaign|
      campaign.range.cover? today
    end
  end
end

Plugin.create :campaign do
  on_give_continuous_login_bonus do |name, count|
    Plugin::Campaign.active_campaigns.each do |campaign|
      campaign.daily(name)
    end
  end
end
