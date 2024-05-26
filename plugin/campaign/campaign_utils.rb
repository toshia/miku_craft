# -*- coding: utf-8 -*-

require_relative 'mc_json'

require 'date'

module Plugin::Campaign
  class Campaign
    attr_accessor :range

    class << self
      def inherited(klass)
        types << klass
        klass.extend(CampaignExtend)
      end

      def types
        @types ||= Set.new
      end

      def generate(_record)
        record = Hashie::Mash.new(_record)
        type = Array(record.type).first.to_sym
        campaign_class = @types.find{|cc| cc.type == type }
        raise "Campaign type `#{record.type}' does not found in `#{record.name}'" unless campaign_class
        date_default = [today.year, today.month, today.day]
        campaign_class.new(name: record.name,
                           range: Range.new(Date.new(*(date_default[0...(3-record.start.size)] + record.start)),
                                            Date.new(*(date_default[0...(3-record.end.size)] + record.end)),
                                            false),
                           variable: record.variable || Hashie::Mash.new,
                           table: record.table,
                           description: record.description)
      end

      def active_campaigns
        Plugin.filtering(:campaign_table, []).first.map { |record|
          Plugin::Campaign::Campaign.generate(record)
        }.select do |campaign|
          campaign.range.cover? today
        end
      end

      def today
        Plugin.filtering(:today_date, Date.today).first
      end

    end

    def initialize(name:, range:, variable:, table:, description:)
      @name, @range, @variable, @table, @description = name, range, variable, table, description
    end

    def name(context=nil)
      if context
        ERB.new(@name).result(context)
      else
        @name
      end
    end

    def description(context=nil)
      if context && @description
        ERB.new(@description).result(context)
      else
        @description
      end
    end

    def daily(user_name:, login_count:)
    end

    def to_s
      @name
    end

    def inspect
      "#<#{self.class}: #{@name.inspect} (#{@range.inspect})>"
    end
  end

  module CampaignExtend
    def type(*args)
      if args.empty?
        @type
      else
        @type = args.first.to_sym
      end
    end
  end

  CampaignArgs = Struct.new(:user_name, :login_count) do
    def context
      binding
    end
  end

  class RandomItem < Campaign
    type :item_random

    def daily(user_name:, login_count:)
      # 先に、itemをnbtにして、計算は全部やっておく。
      # 以下は、その内容を読んでアイテムのコンバートを行う。
      context = CampaignArgs.new(user_name, login_count).context
      item_raw = @table.sample
      item_id = ERB.new(item_raw['id']).result(context)
      # item_name = item.dig('NBT', 'display', 'Name') || item_id
      # r_name = name(context)
      item = MinecraftItem.new(id: item_id, tag: NBT.build(item_raw['NBT'], bind: context))

      # if item.dig('NBT', 'Enchantments')
      #   # エンチャントのlvlが0だった場合にエンチャント自体を消す特例。 -> 残す
      #   item['NBT']['Enchantments'] = item['NBT']['Enchantments'].select { |ench|
      #     ench['lvl'] != 0
      #   }
      # end
      if item.has_enchantment?
        item.destroy_level0_enchantments
      end

      # if item.dig(:NBT, :AttributeModifiers)
      #   item[:NBT][:AttributeModifiers] = item[:NBT][:AttributeModifiers].reject{|attr|
      #     # 数値変動がないA.M.をすべて削除
      #     attr[:Amount] == 0 && attr[:Operation] == 0 || # +0
      #       attr[:Amount] == 0 && attr[:Operation] == 1 || # +0.0 (Multiply Additive)
      #       attr[:Amount] == 1 && attr[:Operation] == 2 # *1 (Multiply Multiply)
      #   }
      # end
      if item.has_attribute_modifiers?
        item.destroy_0_attribute_modifiers
      end
      Plugin.call(:giftbox_keep,
                  user_name,
                  "#{description(context) || r_name}！#{item_name}をプレゼント",
                  {
                    id: item_id,
                    count: context.eval(item.amount.to_s) || 1,
                    tag: item.snbt })
    end
  end

end
