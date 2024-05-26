# -*- coding: utf-8 -*-
require 'fileutils'
require_relative '../lib/minecraft_item'

ITEM_STACK = YAML.safe_load_file(File.join(__dir__, 'stack.yml'))

Plugin.create :giftbox do
  save_dir = File.expand_path(File.join(__dir__, '..', 'config', 'giftbox'))
  FileUtils.mkdir_p(save_dir)
  store = Moneta.new(:File, dir: File.join(save_dir, 'giftbox'))

  on_giftbox_keep do |name, message, opts|
    box = store[name] || []
    box << {
      message: message,
      item: {
        name: opts[:id],           # 'minecraft:dirt'
        amount: opts[:count] || 1, # 1
        tag: opts[:tag]            # NBT::Compound | nil
      }
    }
    store[name] = box
    if collect(:active_players).include?(name)
      Plugin.call(:giftbox_give, name)
    end
  end

  subscribe(:active_players__add).each do |name|
    Plugin.call(:giftbox_give, name)
  end

  on_giftbox_give do |name|
    if collect(:active_players).include?(name)
      box = store[name] || []
      case box.size
      when 0
        next
      when 1
        case box
        in [{item: {name: item_name, amount: amount, tag: MinecraftItem | nil => tag}}]
          Plugin.call(:minecraft_give_item, name, item_name, amount, tag)
        in [{item: {name: item_name, amount: amount}}]
          Plugin.call(:minecraft_give_item, name, item_name, amount, nil)
        else
          warn "unknown gift payload! #{box.inspect}"
          nil
        end
      when (2..)
        gifts, capa_over = box.filter_map do |gift|
          case gift
          in {item: {name: item_name, amount: amount, tag: MinecraftItem | nil => tag}}
            {id: item_name, Count: amount, tag: tag}
          else
            nil
          end
        end.partition{ calc_weight(_1) <= 1 }
        gifts.sort_by! { -calc_weight(_1) }
        capa = 1
        chunks = (capa_over || []).map { [_1].freeze }
        chunk = []
        while !gifts.empty?
          i = gifts.find_index { capa >= calc_weight(_1) }
          if i
            gift = gifts.slice!(i)
            capa -= calc_weight(gift)
            chunk << gift
          else
            capa = 1
            chunks << chunk.freeze
            chunk = []
          end
        end
        chunks << chunk.freeze unless chunk.empty?
        chunks.each do |gifts|
          case gifts.size
          when 1
            gift, = gifts
            Plugin.call(:minecraft_give_item, name, gift['id'], gift['Count'], gift['tag'])
          when (2..)
            Plugin.call(:minecraft_give_item, name, 'minecraft:bundle', 1,
                        Hashie::Mash.new({ Items: gifts }).to_mcjson(binding))
          end
        end
      end

      box.each do |gift|
        Plugin.call(:minecraft_tell, name, gift[:message]) if gift[:message].is_a? String
      end

      unless box.empty?
        store[name] = []
      end
    end
  end

  def calc_weight(item)
    Rational((item['Count'] || 1).to_i, ITEM_STACK[item['id'].to_s] || 1)
  end
end
