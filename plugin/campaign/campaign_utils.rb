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
      item = @table.sample
      context = CampaignArgs.new(user_name, login_count).context
      item_id = ERB.new(item.id).result(context)
      item_name = item.dig(:NBT, :display, :Name) || item_id
      r_name = name(context)
      variant = item.variant
      if variant && !item.dig(:NBT, :Damage)
        if item[:NBT].is_a?(Hash)
          item[:NBT][:Damage] = context.eval(variant.to_s)
        else
          item[:NBT] = {Damage: context.eval(variant.to_s)}
        end
      end
      item.dig(:NBT, :display, :Name)&.yield_self do |text|
        item[:NBT][:display][:Name] = rich_text(text, context)
      end
      if item.dig(:NBT, :display, :Lore).is_a?(Array)
        item[:NBT][:display][:Lore] = item.dig(:NBT, :display, :Lore).map do |lore|
          rich_text(lore, context)
        end
      end
      if item.dig(:NBT, :Enchantments)
        item[:NBT][:Enchantments] = item[:NBT][:Enchantments].map{|ench|
          case ench[:lvl]
          when String
            r = ERB.new(ench[:lvl]).result(context)
            ench.merge(lvl: r.to_i)
          else
            ench
          end
        }.select{|ench|
          ench[:lvl] != 0
        }
      end
      Plugin.call(:giftbox_keep,
                  user_name,
                  "#{description(context) || r_name}！#{item_name}をプレゼント",
                  {
                    id: item_id,
                    count: context.eval(item.amount.to_s) || 1,
                    tag: item.NBT&.to_mcjson(context) || '{}' })
    end

    private

    def rich_text(text, context)
      case text
      when String
        Hashie::Mash.new(text: text).to_mcjson(context).to_s
      when Hash
        text.to_mcjson(context).to_s
      end
    end
  end

end
