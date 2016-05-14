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

    def to_s
      @name
    end
  end

  YEAR = Time.now.year

  Campaigns = [
    Campaign.new(name: "人権週間キャンペーン",
                 range: Range.new(Date.new(YEAR, 12, 4), Date.new(YEAR, 12, 10), false))
    .on_daily_login{ |name, campaign|
      Plugin.call(:minecraft_tell, name, '人権週間キャンペーン開催中(12/10まで)！一日乗車券をプレゼント！')
      Plugin.call(:minecraft_give_item, name, 'minecraft:paper', 1, 0, "{display:{Name:\"一日乗車券\"}}")
    },
    Campaign.new(name: "mikutter#{Time.now.year - 2009}周年記念キャンペーン(12/25まで)",
                 range: Range.new(Date.new(YEAR, 12, 20), Date.new(YEAR, 12, 25), false))
      .on_daily_login{ |name, campaign|
      Plugin.call(:minecraft_tell, name, "#{campaign.name}！誕生日ケーキをプレゼント！")
      Plugin.call(:minecraft_give_item, name, 'minecraft:cake', 1, 0, '{display:{Name: "誕生日ケーキ",Lore:["mikutterの誕生日記念"]}}')
    },
    Campaign.new(name: "年末年始キャンペーン(1/5まで)",
                 range: Range.new(Date.new(YEAR, 12, 25), Date.new(YEAR+1, 1, 5), false))
      .on_daily_login{ |name, campaign|
      [ -> {
          Plugin.call(:minecraft_tell, name, "#{campaign.name}！門松をプレゼント！")
          Plugin.call(:minecraft_give_item, name, 'minecraft:reeds', 1, 0, %<{display:{Name: "門松",Lore:["メリーお正月！"]},AttributeModifiers:[{AttributeName: "generic.attackDamage",Name: "generic.attackDamage",Amount: 6,Operation: 0,UUIDMost: 96348,UUIDLeast: 877567}]}>)
        },
        -> {
          Plugin.call(:minecraft_tell, name, "#{campaign.name}！破魔矢をプレゼント！")
          Plugin.call(:minecraft_give_item, name, 'minecraft:tipped_arrow', 1, 0, %<{display:{Name: "破魔矢",Lore:["メリーお正月！"]},Potion:strong_healing}>)
        },
        -> {
          Plugin.call(:minecraft_tell, name, "#{campaign.name}！羽子板をプレゼント！")
          Plugin.call(:minecraft_give_item, name, 'minecraft:wooden_sword', 1, 0, %<{display:{Name:"羽子板",Lore:["メリーお正月！"]},AttributeModifiers:[{AttributeName:"generic.attackDamage",Name:"generic.attackDamage",Amount:16,Operation:0,UUIDMost:9742,UUIDLeast:466013}],HideFlags:2}>)
        },
        -> {
          Plugin.call(:minecraft_tell, name, "#{campaign.name}！獅子舞をプレゼント！")
          Plugin.call(:minecraft_give_item, name, 'minecraft:skull', 1, 3, %<{display:{Name:"獅子舞",Lore:["メリーお正月！"]},SkullOwner:"#{name}",AttributeModifiers:[{AttributeName:"generic.maxHealth",Name:"generic.maxHealth",Amount:2,Operation:0,UUIDMost:77658,UUIDLeast:855423}],ench:[{id:6,lvl:1}],HideFlags:1}>)
        }
      ].sample.()
    },
    Campaign.new(name: "自殺強化月間",
                 range: Range.new(Date.new(YEAR, 3, 1), Date.new(YEAR, 3, 31), false))
      .on_daily_login{ |name, campaign|
      today = Time.now.strftime("%Y/%m/%d")
      [ -> {
          Plugin.call(:minecraft_tell, name, "#{campaign.name}！蜘蛛の目をプレゼント！")
          Plugin.call(:minecraft_give_item, name, 'minecraft:spider_eye', 1, 0, %<{display:{Name: "蜘蛛の目",Lore:["自殺強化月間記念に#{name}がもらった", "#{today}"]}}>)
        },
        -> {
          Plugin.call(:minecraft_tell, name, "#{campaign.name}！首綱をプレゼント！")
          Plugin.call(:minecraft_give_item, name, 'minecraft:lead', 1, 0, %<{display:{Name: "首綱",Lore:["自殺強化月間記念に#{name}がもらった", "#{today}"]}}>)
        },
        -> {
          Plugin.call(:minecraft_tell, name, "#{campaign.name}！チャッカマンをプレゼント！")
          Plugin.call(:minecraft_give_item, name, 'flint_and_steel', 1, 0, %<{display:{Name: "チャッカマン",Lore:["自殺強化月間記念に#{name}がもらった", "#{today}"]},ench:[{id:20,lvl:1}],AttributeModifiers:[{AttributeName:"generic.attackDamage",Name:"generic.attackDamage",Amount:4,Operation:0,UUIDMost:30253,UUIDLeast:21008}],HideFlags:3}>)
        },
        -> {
          Plugin.call(:minecraft_tell, name, "#{campaign.name}！金床をプレゼント！")
          Plugin.call(:minecraft_give_item, name, 'minecraft:anvil', 1, 0, %<{display:{Name: "金床",Lore:["自殺強化月間記念に#{name}がもらった", "#{today}"]},AttributeModifiers:[{AttributeName:"generic.knockbackResistance",Name:"generic.knockbackResistance",Amount:0.25,Operation:0,UUIDMost:65999,UUIDLeast:969951},{AttributeName:"generic.movementSpeed",Name:"generic.movementSpeed",Amount:-0.05,Operation:0,UUIDMost:11251,UUIDLeast:684314},{AttributeName:"generic.attackDamage",Name:"generic.attackDamage",Amount:5,Operation:0,UUIDMost:44111,UUIDLeast:12466}],ench:[{id:19,lvl:1}],HideFlags:3}>)
        },
      ].sample.()
    },
    Campaign.new(name: "あしゅりーおじさん600ユーロスられ記念",
                 range: Range.new(Date.new(YEAR, 3, 7), Date.new(YEAR, 3, 10), false))
      .on_daily_login{ |name, campaign|
      Plugin.call(:minecraft_tell, name, 'あしゅりーおじさん600ユーロスられ記念！ドイツのトリタペストリーをプレゼント！')
      (0..13).to_a.sample(2).each do |bg|
        Plugin.call(:minecraft_give_item, name, 'minecraft:banner', 1, 0, %<{display:{Name: "ドイツのトリタペストリー"},BlockEntityTag:{Base:#{bg},Patterns:[{Pattern:cre,Color:14},{Pattern:hh,Color:#{bg}},{Pattern:mr,Color:#{bg}},{Pattern:mr,Color:15},{Pattern:bt,Color:#{bg}},{Pattern:mc,Color:15},{Pattern:ts,Color:#{bg}}]}}>)
      end
    },

    Campaign.new(name: "re4k垢BAN記念イベント",
                 range: Range.new(Date.new(YEAR, 3, 12), Date.new(YEAR, 3, 19), false))
      .on_daily_login{ |name, campaign|
      Plugin.call(:minecraft_tell, name, "#{campaign.name}開催中(3/19まで)！re4kをプレゼント！")
      Plugin.call(:minecraft_give_item, name, 'minecraft:packed_ice', 1, 0, %<{display:{Name:"re4k",Lore:["レニウム垢BAN記念","#{Time.now.strftime("%Y/%m/%d")}"]},ench:[{id:51,lvl:1}]}>)
    },

    Campaign.new(name: "Favstar プレミアムユーザ垢BAN記念イベント",
                 range: Range.new(Date.new(YEAR, 3, 12), Date.new(YEAR, 3, 19), false))
      .on_daily_login{ |name, campaign|
      Plugin.call(:minecraft_tell, name, "#{campaign.name}開催中(3/19まで)！喫茶室長が羊毛ブロックは燃えないと勘違いしていた記念に、燃えない羊毛をプレゼント！")
      Plugin.call(:minecraft_give_item, name, 'minecraft:stained_hardened_clay', 1, (0..15).to_a.sample, %<{display:{Name:"燃えない羊毛",Lore:["Favstar プレミアムユーザ垢BAN記念","#{Time.now.strftime("%Y/%m/%d")}"]},ench:[{id:1,lvl:1}]}>)
    },

    Campaign.new(name: "Minecraft 1.9バージョンアップキャンペーン(5/30まで)",
                 range: Range.new(Date.new(2016, 5, 16), Date.new(2016, 5, 30), false))
      .on_daily_login{ |name, campaign|
      rarity = {
        r: rand(32..64),
        sr: rand(16..48),
        ssr: rand(8..32),
        ur: rand(1..8)}
      levels5 = [*[1]*4096, *[2]*(rarity[:r]**2), *[3]*(rarity[:sr]**2), *[4]*(rarity[:ssr]**2), *[5]*(rarity[:ur]**2)]
      swords = [*['wooden_sword']*4096, *['stone_sword']*(rarity[:r]**2), *['iron_sword']*(rarity[:sr]**2), *['golden_sword']*(rarity[:ssr]**2), *['diamond_sword']*(rarity[:ur]**2)]
      axes = [*['wooden_axe']*4096, *['stone_axe']*(rarity[:r]**2), *['iron_axe']*(rarity[:sr]**2), *['golden_axe']*(rarity[:ssr]**2), *['diamond_axe']*(rarity[:ur]**2)]
      pickaxes = [*['wooden_pickaxe']*4096, *['stone_pickaxe']*(rarity[:r]**2), *['iron_pickaxe']*(rarity[:sr]**2), *['golden_pickaxe']*(rarity[:ssr]**2), *['diamond_pickaxe']*(rarity[:ur]**2)]
      [
        -> {
          Plugin.call(:minecraft_tell, name, "#{campaign.name}！ずんだアローをプレゼント！")
          Plugin.call(:minecraft_give_item, name, 'minecraft:tipped_arrow', rarity[:r], 0, %<{Potion:regeneration,display:{Name:"ずんだアロー",Lore:["当たった相手をずんだ餅に変えてしまう矢"]}}>)
        },
        -> {
          Plugin.call(:minecraft_tell, name, "#{campaign.name}！ずんだアロー・改をプレゼント！")
          Plugin.call(:minecraft_give_item, name, 'minecraft:tipped_arrow', rarity[:sr], 0, %<{Potion:long_regeneration,display:{Name:"ずんだアロー・改",Lore:["当たった相手をずんだ餅に変えてしまう矢"]}}>)
        },
        -> {
          Plugin.call(:minecraft_tell, name, "#{campaign.name}！ずんだアロー・極をプレゼント！")
          Plugin.call(:minecraft_give_item, name, 'minecraft:tipped_arrow', rarity[:ssr], 0, %<{Potion:strong_regeneration,display:{Name:"ずんだアロー・極",Lore:["当たった相手をずんだ餅に変えてしまう矢"]}}>)
        },
        -> {
          Plugin.call(:minecraft_tell, name, "#{campaign.name}！毒矢をプレゼント！")
          Plugin.call(:minecraft_give_item, name, 'minecraft:tipped_arrow', rarity[:r], 0, %<{Potion:poison,display:{Name:"毒矢"}}>)
        },
        -> {
          Plugin.call(:minecraft_tell, name, "#{campaign.name}！レイニースピンをプレゼント！")
          Plugin.call(:minecraft_give_item, name, 'minecraft:tipped_arrow', rarity[:r], 0, %<{Potion:weakness,display:{Name:"レイニースピン"}}>)
        },
        -> {
          Plugin.call(:minecraft_tell, name, "#{campaign.name}！ストームスピンをプレゼント！")
          Plugin.call(:minecraft_give_item, name, 'minecraft:tipped_arrow', rarity[:sr], 0, %<{Potion:long_weakness,display:{Name:"ストームスピン"}}>)
        },
        -> {
          Plugin.call(:minecraft_tell, name, "#{campaign.name}！トライバーストをプレゼント！")
          Plugin.call(:minecraft_give_item, name, 'minecraft:tipped_arrow', rarity[:r], 0, %<{Potion:slowness,display:{Name:"トライバースト"}}>)
        },
        -> {
          Plugin.call(:minecraft_tell, name, "#{campaign.name}！ノックバーストをプレゼント！")
          Plugin.call(:minecraft_give_item, name, 'minecraft:tipped_arrow', rarity[:sr], 0, %<{Potion:long_slowness,display:{Name:"ノックバースト"}}>)
        },
        -> {
          Plugin.call(:minecraft_tell, name, "#{campaign.name}！破魔矢をプレゼント！")
          Plugin.call(:minecraft_give_item, name, 'minecraft:tipped_arrow', rarity[:ur], 0, %<{Potion:strong_healing,display:{Name:"破魔矢",Lore:["Minecraft1.9リリース記念・お正月イベント復刻"]}}>)
        },
        -> {
          Plugin.call(:minecraft_tell, name, "#{campaign.name}！チャージバーストをプレゼント！")
          Plugin.call(:minecraft_give_item, name, 'minecraft:tipped_arrow', rarity[:ur], 0, %<{Potion:strong_harming,display:{Name:"チャージバースト"}}>)
        },
        -> {
          Plugin.call(:minecraft_tell, name, "#{campaign.name}！イッテンキューソードをプレゼント！")
          Plugin.call(:minecraft_give_item, name, swords.sample, 1, 0, %<{display:{Name:"イッテンキューソード"},ench:[{id:34,lvl:#{levels5.sample}},{id:70,lvl:1}]}>)
        },
        -> {
          Plugin.call(:minecraft_tell, name, "#{campaign.name}！イッテンキューアックス・採掘をプレゼント！")
          Plugin.call(:minecraft_give_item, name, axes.sample, 1, 0, %<{display:{Name:"イッテンキューアックス・採掘"},ench:[{id:32,lvl:#{levels5.sample}},{id:34,lvl:#{levels5.sample}},{id:70,lvl:1}]}>)
        },
        -> {
          Plugin.call(:minecraft_tell, name, "#{campaign.name}！イッテンキューアックス・攻撃をプレゼント！")
          Plugin.call(:minecraft_give_item, name, axes.sample, 1, 0, %<{display:{Name:"イッテンキューアックス・攻撃"},ench:[{id:16,lvl:#{levels5.sample}},{id:34,lvl:#{levels5.sample}},{id:70,lvl:1}]}>)
        },
        -> {
          Plugin.call(:minecraft_tell, name, "#{campaign.name}！イッテンキューピッケルをプレゼント！")
          Plugin.call(:minecraft_give_item, name, pickaxes.sample, 1, 0, %<{display:{Name:"イッテンキューピッケル"},ench:[{id:32,lvl:#{levels5.sample}},{id:34,lvl:#{levels5.sample}},{id:70,lvl:1}]}>)
        },
      ].sample.()
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
