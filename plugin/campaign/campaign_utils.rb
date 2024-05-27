# -*- coding: utf-8 -*-

require_relative 'mc_json'
require_relative '../../lib/nbt'
require_relative '../../lib/minecraft_item'

require 'date'

module Plugin::Campaign
  class Campaign
    attr_accessor :range

    CampaignMetadata = Struct.new(:name, :start, :end, :type, :description, :table, keyword_init: true)

    class << self
      def inherited(klass)
        types << klass
        klass.extend(CampaignExtend)
      end

      def types
        @types ||= Set.new
      end

      def generate(raw_record)
        record = CampaignMetadata.new(**raw_record.transform_keys(&:to_sym))
        type = Array(record.type).first.to_sym
        campaign_class = @types.find{|cc| cc.type == type }
        raise "Campaign type `#{record.type}' does not found in `#{record.name}'" unless campaign_class
        date_default = [today.year, today.month, today.day]
        campaign_class.new(name: record.name,
                           range: Range.new(Date.new(*(date_default[0...(3-record.start.size)] + record.start)),
                                            Date.new(*(date_default[0...(3-record.end.size)] + record.end)),
                                            false),
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

    def initialize(name:, range:, table:, description:)
      @name, @range, @table, @description = name, range, table, description
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
      item_id = ERB.new(item_raw[:id]).result(context)
      item = MinecraftItem::Item.new(item_id, component: NBT.build(item_raw[:NBT], bind: context, allow_nil: true))

      Plugin.call(:giftbox_keep_stack,
                  user_name,
                  "#{description(context) || name(context)}！#{item.item_name}をプレゼント",
                  MinecraftItem::Stack.new(
                    item,
                    context.eval(item_raw[:amount].to_s) || 1))
    end
  end

  class GiveAllItem < Campaign
    type :give_all_item

    def daily(user_name:, login_count:)
      # 先に、itemをnbtにして、計算は全部やっておく。
      # 以下は、その内容を読んでアイテムのコンバートを行う。
      context = CampaignArgs.new(user_name, login_count).context
      @table.each do |item_raw|
        item_id = ERB.new(item_raw[:id]).result(context)
        item = MinecraftItem::Item.new(item_id, component: NBT.build(item_raw[:NBT], bind: context, allow_nil: true))

        Plugin.call(:giftbox_keep_stack,
                    user_name,
                    "#{description(context) || name(context)}！#{item.item_name}をプレゼント",
                    MinecraftItem::Stack.new(
                      item,
                      context.eval(item_raw[:amount].to_s) || 1))
      end
    end
  end

end
