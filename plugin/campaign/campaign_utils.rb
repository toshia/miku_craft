# -*- coding: utf-8 -*-

require_relative 'mc_json'

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
        year = today.year
        campaign_class.new(name: record.name,
                           range: Range.new(Date.new(year, *record.start),
                                            Date.new(year, *record.end),
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
      item = @table.sample
      context = CampaignArgs.new(user_name, login_count).context
      r_name = name(context)
      Plugin.call(:giftbox_keep,
                  user_name,
                  "#{description(context) || r_name}！#{item.dig(:NBT, :display, :Name) || item.id}をプレゼント",
                  item.id,
                  context.eval(item.amount.to_s) || 1,
                  context.eval(item.variant.to_s) || 0,
                  item.NBT&.to_mcjson(context) || '{}')
    end
  end

end
